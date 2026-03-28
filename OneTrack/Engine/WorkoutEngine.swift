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

    /// Cancels and deletes the workout session.
    func cancelWorkout() {
        guard let session else { return }
        stopTimers()
        modelContext.delete(session)
        try? modelContext.save()
        self.session = nil
        isActive = false
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

    // MARK: - Rest Timer

    func startRestTimer(duration: Int? = nil) {
        guard let session else { return }
        restDuration = duration ?? (session.plan?.defaultRestSeconds ?? 90)
        restTimeRemaining = restDuration
        isResting = true
        startRestTimerTask()
    }

    func skipRestTimer() {
        isResting = false
        restTimeRemaining = 0
        restTimerTask?.cancel()
        restTimerTask = nil
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
                guard let self, self.isResting, self.restTimeRemaining > 0 else { break }
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { break }
                self.restTimeRemaining -= 1
            }
            if let self, self.restTimeRemaining <= 0 {
                self.isResting = false
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
