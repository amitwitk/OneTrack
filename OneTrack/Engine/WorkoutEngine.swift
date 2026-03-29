import Foundation
import SwiftData
import Observation

/// Platform-agnostic workout lifecycle manager.
/// Extracted from ActiveWorkoutView for reuse on watchOS.
@MainActor
@Observable
final class WorkoutEngine {
    private(set) var session: WorkoutSession?
    private(set) var previousSession: WorkoutSession?
    private(set) var elapsedSeconds: Int = 0
    private(set) var isActive: Bool = false

    // Rest timer
    private(set) var restTimeRemaining: Int = 0
    private(set) var isResting: Bool = false
    private(set) var restDuration: Int = 90

    // PR celebration trigger — views observe this
    private(set) var prDetectedCount: Int = 0

    private let modelContext: ModelContext
    private var timerTask: Task<Void, Never>?
    private var restTimerTask: Task<Void, Never>?

    var sortedLogs: [ExerciseLog] {
        session?.exerciseLogs.sorted { $0.sortOrder < $1.sortOrder } ?? []
    }

    var workingSets: [SetLog] {
        sortedLogs.flatMap(\.sets).filter { !$0.isWarmUp }
    }

    var completedCount: Int {
        workingSets.filter(\.isCompleted).count
    }

    var totalCount: Int {
        workingSets.count
    }

    var progress: Double {
        totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Lifecycle

    /// Resumes an existing session (e.g., after app relaunch or from plan list).
    func resumeSession(_ session: WorkoutSession, previous: WorkoutSession?) {
        self.session = session
        self.previousSession = previous
        self.restDuration = session.plan?.defaultRestSeconds ?? 90
        self.isActive = true
        startElapsedTimer()
    }

    /// Finishes the workout: sets duration, marks complete, saves.
    func finishWorkout(rpe: Int? = nil) {
        guard let session else { return }
        session.durationSeconds = elapsedSeconds
        session.isCompleted = true
        if let rpe { session.rpe = rpe }
        stopTimers()
        try? modelContext.save()
    }

    /// Cancels the workout: stops timers and marks for deletion.
    /// Returns the session so the caller can delete it after dismissing the view.
    @discardableResult
    func cancelWorkout() -> WorkoutSession? {
        let sessionToDelete = session
        stopTimers()
        self.session = nil
        isActive = false
        return sessionToDelete
    }

    /// Prepares finish (stops timers, sets duration) without marking complete.
    /// Used by the finish summary sheet flow.
    func prepareFinish() {
        guard let session else { return }
        session.durationSeconds = elapsedSeconds
        stopTimers()
    }

    // MARK: - Sets

    func addSet(to log: ExerciseLog) -> SetLog {
        let sortedSets = log.sets.sorted { $0.setNumber < $1.setNumber }
        let lastSet = sortedSets.last
        let newSet = SetLog(
            setNumber: (lastSet?.setNumber ?? 0) + 1,
            reps: lastSet?.reps ?? 0,
            seconds: lastSet?.seconds ?? 0,
            weightKg: lastSet?.weightKg ?? 0
        )
        newSet.exerciseLog = log
        modelContext.insert(newSet)
        return newSet
    }

    func deleteSet(_ setLog: SetLog, from log: ExerciseLog) {
        PlanManagement.deleteSet(setLog, from: log)
        modelContext.delete(setLog)
        try? modelContext.save()
    }

    // MARK: - Exercises

    func addExercises(_ templates: [ExerciseTemplate]) {
        guard let session else { return }
        let maxOrder = sortedLogs.last?.sortOrder ?? -1
        for (index, template) in templates.enumerated() {
            let log = ExerciseLog(
                exerciseName: template.name,
                sortOrder: maxOrder + 1 + index,
                isIsometric: template.isIsometric
            )
            log.session = session
            modelContext.insert(log)

            for setIndex in 0..<template.defaultSets {
                let setLog = SetLog(
                    setNumber: setIndex + 1,
                    reps: template.defaultReps,
                    seconds: template.defaultSeconds,
                    weightKg: 0
                )
                setLog.exerciseLog = log
                modelContext.insert(setLog)
            }
        }
        try? modelContext.save()
    }

    // MARK: - Reorder & Swap

    /// Reorders exercises within the current session. Session-scoped only.
    func reorderExercises(from source: IndexSet, to destination: Int) {
        guard session != nil else { return }
        var logs = sortedLogs
        logs.move(fromOffsets: source, toOffset: destination)
        for (index, log) in logs.enumerated() {
            log.sortOrder = index
        }
        try? modelContext.save()
    }

    /// Swaps an exercise for an alternative. Preserves sets, clears PRs.
    func swapExercise(_ log: ExerciseLog, with template: ExerciseTemplate) {
        // Track the original exercise name (not intermediate swaps)
        if log.swappedFromExercise.isEmpty {
            log.swappedFromExercise = log.exerciseName
        }
        log.exerciseName = template.name
        log.isIsometric = template.isIsometric

        // Clear PR flags — different exercise can't retain old PRs
        for set in log.sets {
            set.isPersonalRecord = false
        }

        try? modelContext.save()
    }

    // MARK: - Auto-fill

    /// After completing a set, auto-fills the next uncompleted set with the same weight/reps/seconds.
    /// Does NOT overwrite if the user already entered values (value > 0).
    func autoFillNextSet(after completedSet: SetLog, in log: ExerciseLog) {
        let sorted = log.sets.sorted { $0.setNumber < $1.setNumber }
        guard let nextSet = sorted.first(where: { $0.setNumber > completedSet.setNumber && !$0.isCompleted }) else { return }

        if nextSet.weightKg == 0 {
            nextSet.weightKg = completedSet.weightKg
        }

        if log.isIsometric {
            if nextSet.seconds == 0 {
                nextSet.seconds = completedSet.seconds
            }
        } else {
            if nextSet.reps == 0 {
                nextSet.reps = completedSet.reps
            }
        }
    }

    /// Returns true if the given set is the last set in its exercise log (by setNumber).
    static func isLastSetInExercise(_ setLog: SetLog, in log: ExerciseLog) -> Bool {
        let maxSetNumber = log.sets.map(\.setNumber).max() ?? 0
        return setLog.setNumber >= maxSetNumber
    }

    // MARK: - Rest Timer

    private(set) var restTimerEndDate: Date?

    func startRestTimer(duration: Int? = nil) {
        guard let session else { return }
        restDuration = duration ?? (session.plan?.defaultRestSeconds ?? 90)
        restTimeRemaining = restDuration
        restTimerEndDate = Date.now.addingTimeInterval(Double(restDuration))
        isResting = true
        startRestTimerTask()
    }

    func skipRestTimer() {
        isResting = false
        restTimeRemaining = 0
        restTimerEndDate = nil
        restTimerTask?.cancel()
        restTimerTask = nil
    }

    /// Recalculates rest timer from the stored end date (call when app returns to foreground).
    func recalculateRestTimer() {
        guard isResting, let endDate = restTimerEndDate else { return }
        let remaining = Int(endDate.timeIntervalSinceNow)
        if remaining <= 0 {
            skipRestTimer()
        } else {
            restTimeRemaining = remaining
        }
    }

    func exerciseRestDuration(for log: ExerciseLog) -> Int? {
        session?.plan?.exercises
            .first { $0.name == log.exerciseName }?
            .restSeconds
    }

    // MARK: - PR Detection

    func detectPR(for setLog: SetLog, exerciseName: String, isIsometric: Bool) -> Bool {
        guard !setLog.setType.isPRExcluded else { return false }

        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.isCompleted }
        )
        descriptor.fetchLimit = 500

        guard let completedSessions = try? modelContext.fetch(descriptor) else { return false }

        let historicalSets = completedSessions
            .flatMap(\.exerciseLogs)
            .filter { $0.exerciseName == exerciseName }
            .flatMap(\.sets)
            .filter { $0.isCompleted && !$0.setType.isPRExcluded }

        let isPR = WorkoutCalculations.isPersonalRecord(
            setLog: setLog,
            isIsometric: isIsometric,
            historicalSets: historicalSets
        )

        if isPR {
            setLog.isPersonalRecord = true
            prDetectedCount += 1
        }

        return isPR
    }

    /// Estimated 1RM for a set of completed sets.
    func estimated1RM(completedSets: [SetLog]) -> Double? {
        WorkoutCalculations.bestEstimated1RM(completedSets: completedSets)
    }

    // MARK: - Timer Management

    private func startElapsedTimer() {
        timerTask?.cancel()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, let self, let session = self.session else { break }
                self.elapsedSeconds = Int(Date.now.timeIntervalSince(session.startedAt))
            }
        }
    }

    private func startRestTimerTask() {
        restTimerTask?.cancel()
        restTimerTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.isResting, let endDate = self.restTimerEndDate else { break }
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                let remaining = Int(endDate.timeIntervalSinceNow)
                if remaining <= 0 {
                    self.restTimeRemaining = 0
                    self.isResting = false
                    self.restTimerEndDate = nil
                    break
                } else {
                    self.restTimeRemaining = remaining
                }
            }
        }
    }

    private func stopTimers() {
        timerTask?.cancel()
        timerTask = nil
        restTimerTask?.cancel()
        restTimerTask = nil
        isResting = false
        isActive = false
    }
}
