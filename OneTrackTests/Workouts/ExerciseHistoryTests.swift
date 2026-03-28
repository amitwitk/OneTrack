import Testing
import Foundation
import SwiftData
@testable import OneTrack

@Suite("Exercise History")
@MainActor
struct ExerciseHistoryTests {

    // MARK: - History Extraction

    @Test func extractHistory_multipleSessions() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        var sessions: [WorkoutSession] = []
        for dayOffset in [10, 7, 3] {
            let date = Calendar.current.date(byAdding: .day, value: -dayOffset, to: .now)!
            let session = WorkoutSession(date: date)
            session.isCompleted = true
            context.insert(session)

            let log = ExerciseLog(exerciseName: "Bench Press", sortOrder: 0)
            log.session = session
            context.insert(log)

            let weight = Double(60 + (10 - dayOffset) * 5)
            let set1 = SetLog(setNumber: 1, reps: 10, weightKg: weight)
            set1.isCompleted = true
            set1.exerciseLog = log
            context.insert(set1)

            sessions.append(session)
        }
        try context.save()

        let history = ExerciseHistoryCalculations.extractHistory(
            exerciseName: "Bench Press",
            sessions: sessions
        )

        #expect(history.count == 3)
        // Sorted by date ascending
        #expect(history[0].maxWeight < history[2].maxWeight)
    }

    @Test func extractHistory_emptyWhenNoSessions() {
        let history = ExerciseHistoryCalculations.extractHistory(
            exerciseName: "Squat",
            sessions: []
        )
        #expect(history.isEmpty)
    }

    @Test func extractHistory_filtersToExerciseName() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let session = WorkoutSession()
        session.isCompleted = true
        context.insert(session)

        let benchLog = ExerciseLog(exerciseName: "Bench Press", sortOrder: 0)
        benchLog.session = session
        context.insert(benchLog)
        let benchSet = SetLog(setNumber: 1, reps: 10, weightKg: 80)
        benchSet.isCompleted = true
        benchSet.exerciseLog = benchLog
        context.insert(benchSet)

        let squatLog = ExerciseLog(exerciseName: "Squat", sortOrder: 1)
        squatLog.session = session
        context.insert(squatLog)
        let squatSet = SetLog(setNumber: 1, reps: 5, weightKg: 100)
        squatSet.isCompleted = true
        squatSet.exerciseLog = squatLog
        context.insert(squatSet)

        try context.save()

        let benchHistory = ExerciseHistoryCalculations.extractHistory(
            exerciseName: "Bench Press",
            sessions: [session]
        )
        #expect(benchHistory.count == 1)
        #expect(benchHistory[0].maxWeight == 80)
    }

    @Test func extractHistory_excludesIncompleteAndWarmUp() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let session = WorkoutSession()
        session.isCompleted = true
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Bench Press", sortOrder: 0)
        log.session = session
        context.insert(log)

        let warmUp = SetLog(setNumber: 1, reps: 10, weightKg: 40, setType: .warmUp)
        warmUp.isCompleted = true
        warmUp.exerciseLog = log
        context.insert(warmUp)

        let working = SetLog(setNumber: 2, reps: 8, weightKg: 80)
        working.isCompleted = true
        working.exerciseLog = log
        context.insert(working)

        let incomplete = SetLog(setNumber: 3, reps: 0, weightKg: 90)
        incomplete.isCompleted = false
        incomplete.exerciseLog = log
        context.insert(incomplete)

        try context.save()

        let history = ExerciseHistoryCalculations.extractHistory(
            exerciseName: "Bench Press",
            sessions: [session]
        )

        #expect(history.count == 1)
        #expect(history[0].maxWeight == 80) // Not 90 (incomplete) or 40 (warmup)
        #expect(history[0].totalVolume == 640) // 8 * 80
    }

    @Test func extractHistory_calculatesVolume() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let session = WorkoutSession()
        session.isCompleted = true
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Squat", sortOrder: 0)
        log.session = session
        context.insert(log)

        let s1 = SetLog(setNumber: 1, reps: 5, weightKg: 100)
        s1.isCompleted = true
        s1.exerciseLog = log
        context.insert(s1)

        let s2 = SetLog(setNumber: 2, reps: 5, weightKg: 100)
        s2.isCompleted = true
        s2.exerciseLog = log
        context.insert(s2)

        try context.save()

        let history = ExerciseHistoryCalculations.extractHistory(
            exerciseName: "Squat",
            sessions: [session]
        )

        #expect(history[0].totalVolume == 1000) // (5*100) + (5*100)
        #expect(history[0].totalSets == 2)
        #expect(history[0].bestReps == 5)
    }

    @Test func extractHistory_limitsEntries() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        var sessions: [WorkoutSession] = []
        for i in 0..<25 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: .now)!
            let session = WorkoutSession(date: date)
            session.isCompleted = true
            context.insert(session)

            let log = ExerciseLog(exerciseName: "Bench", sortOrder: 0)
            log.session = session
            context.insert(log)

            let set = SetLog(setNumber: 1, reps: 10, weightKg: Double(50 + i))
            set.isCompleted = true
            set.exerciseLog = log
            context.insert(set)

            sessions.append(session)
        }
        try context.save()

        let history = ExerciseHistoryCalculations.extractHistory(
            exerciseName: "Bench",
            sessions: sessions,
            limit: 20
        )
        #expect(history.count == 20)
    }

    @Test func extractHistory_excludesIncompleteSessions() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let completedSession = WorkoutSession()
        completedSession.isCompleted = true
        context.insert(completedSession)

        let completedLog = ExerciseLog(exerciseName: "Bench", sortOrder: 0)
        completedLog.session = completedSession
        context.insert(completedLog)
        let completedSet = SetLog(setNumber: 1, reps: 10, weightKg: 80)
        completedSet.isCompleted = true
        completedSet.exerciseLog = completedLog
        context.insert(completedSet)

        let incompleteSession = WorkoutSession()
        incompleteSession.isCompleted = false
        context.insert(incompleteSession)

        let incompleteLog = ExerciseLog(exerciseName: "Bench", sortOrder: 0)
        incompleteLog.session = incompleteSession
        context.insert(incompleteLog)
        let incompleteSet = SetLog(setNumber: 1, reps: 10, weightKg: 100)
        incompleteSet.isCompleted = true
        incompleteSet.exerciseLog = incompleteLog
        context.insert(incompleteSet)

        try context.save()

        let history = ExerciseHistoryCalculations.extractHistory(
            exerciseName: "Bench",
            sessions: [completedSession, incompleteSession]
        )
        #expect(history.count == 1)
        #expect(history[0].maxWeight == 80)
    }

    // MARK: - PR Detection with Drop Sets

    @Test func dropSetsExcludedFromPR() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        // Historical: 80kg x 10
        let historicalSet = SetLog(setNumber: 1, reps: 10, weightKg: 80)
        historicalSet.isCompleted = true
        context.insert(historicalSet)

        // New drop set: 85kg x 8 — higher weight but it's a drop set
        let dropSet = SetLog(setNumber: 2, reps: 8, weightKg: 85, setType: .dropSet)
        dropSet.isCompleted = true
        context.insert(dropSet)

        try context.save()

        // Drop sets should be excluded from PR detection
        let filteredHistorical = [historicalSet].filter { !$0.setType.isPRExcluded }
        let isPR = WorkoutCalculations.isPersonalRecord(
            setLog: dropSet,
            isIsometric: false,
            historicalSets: filteredHistorical
        )
        // The drop set itself shouldn't be checked for PR since it's excluded
        #expect(dropSet.setType.isPRExcluded)
    }

    @Test func toFailureSetsIncludedInPR() {
        let toFailure = SetLog(setNumber: 1, reps: 10, weightKg: 80, setType: .toFailure)
        #expect(!toFailure.setType.isPRExcluded)
    }

    @Test func warmUpSetsExcludedFromPR() {
        let warmUp = SetLog(setNumber: 1, reps: 10, weightKg: 40, setType: .warmUp)
        #expect(warmUp.setType.isPRExcluded)
    }

    // MARK: - Set Type Cycling

    @Test func setTypeCycleOrder() {
        #expect(SetType.normal.next == .warmUp)
        #expect(SetType.warmUp.next == .dropSet)
        #expect(SetType.dropSet.next == .toFailure)
        #expect(SetType.toFailure.next == .normal)
    }
}
