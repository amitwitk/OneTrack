import Testing
import Foundation
import SwiftData
@testable import OneTrack

@Suite("Workout Engine")
@MainActor
struct WorkoutEngineTests {

    private func makeEngine() throws -> (WorkoutEngine, ModelContext) {
        let container = try makeTestContainer()
        let context = container.mainContext
        let engine = WorkoutEngine(modelContext: context)
        return (engine, context)
    }

    private func makePlanWithExercises(context: ModelContext) -> WorkoutPlan {
        let plan = WorkoutPlan(name: "Test Plan", planDescription: "", sortOrder: 0)
        context.insert(plan)
        let e1 = Exercise(name: "Bench", targetSets: 3, targetReps: 10, sortOrder: 0)
        e1.plan = plan
        context.insert(e1)
        let e2 = Exercise(name: "Row", targetSets: 2, targetReps: 8, sortOrder: 1)
        e2.plan = plan
        context.insert(e2)
        try? context.save()
        return plan
    }

    private func makeSessionWithLogs(context: ModelContext) -> WorkoutSession {
        let session = WorkoutSession()
        context.insert(session)
        let log = ExerciseLog(exerciseName: "Bench", sortOrder: 0)
        log.session = session
        context.insert(log)
        for i in 1...3 {
            let set = SetLog(setNumber: i, reps: 10, weightKg: 60)
            set.exerciseLog = log
            context.insert(set)
        }
        try? context.save()
        return session
    }

    // MARK: - Resume Session

    @Test func resumeSession_setsActiveState() throws {
        let (engine, context) = try makeEngine()
        let session = makeSessionWithLogs(context: context)
        engine.resumeSession(session, previous: nil)
        #expect(engine.isActive)
        #expect(engine.session === session)
    }

    @Test func resumeSession_calculatesProgress() throws {
        let (engine, context) = try makeEngine()
        let session = makeSessionWithLogs(context: context)
        engine.resumeSession(session, previous: nil)
        #expect(engine.totalCount == 3)
        #expect(engine.completedCount == 0)
        #expect(engine.progress == 0)
    }

    // MARK: - Add / Delete Sets

    @Test func addSet_createsNewSetWithCorrectNumber() throws {
        let (engine, context) = try makeEngine()
        let session = makeSessionWithLogs(context: context)
        engine.resumeSession(session, previous: nil)
        let log = engine.sortedLogs.first!
        let newSet = engine.addSet(to: log)
        #expect(newSet.setNumber == 4)
        #expect(engine.totalCount == 4)
    }

    @Test func addSet_copiesLastSetValues() throws {
        let (engine, context) = try makeEngine()
        let session = makeSessionWithLogs(context: context)
        engine.resumeSession(session, previous: nil)
        let log = engine.sortedLogs.first!
        let newSet = engine.addSet(to: log)
        #expect(newSet.reps == 10)
        #expect(newSet.weightKg == 60)
    }

    @Test func deleteSet_renumbersRemaining() throws {
        let (engine, context) = try makeEngine()
        let session = makeSessionWithLogs(context: context)
        engine.resumeSession(session, previous: nil)
        let log = engine.sortedLogs.first!
        let sets = log.sets.sorted { $0.setNumber < $1.setNumber }
        engine.deleteSet(sets[1], from: log) // delete set 2
        let remaining = log.sets.sorted { $0.setNumber < $1.setNumber }
        #expect(remaining.count == 2)
        #expect(remaining[1].setNumber == 2) // was 3, now 2
    }

    // MARK: - Finish / Cancel

    @Test func finishWorkout_setsDurationAndCompleted() throws {
        let (engine, context) = try makeEngine()
        let session = makeSessionWithLogs(context: context)
        engine.resumeSession(session, previous: nil)
        engine.finishWorkout(rpe: 7)
        #expect(session.isCompleted)
        #expect(session.rpe == 7)
        #expect(session.durationSeconds != nil)
    }

    @Test func cancelWorkout_returnsSessionForDeletion() throws {
        let (engine, context) = try makeEngine()
        let session = makeSessionWithLogs(context: context)
        engine.resumeSession(session, previous: nil)
        let returned = engine.cancelWorkout()
        #expect(engine.session == nil)
        #expect(!engine.isActive)
        #expect(returned === session)
    }

    // MARK: - Rest Timer

    @Test func startRestTimer_setsState() throws {
        let (engine, context) = try makeEngine()
        let session = makeSessionWithLogs(context: context)
        engine.resumeSession(session, previous: nil)
        engine.startRestTimer(duration: 60)
        #expect(engine.isResting)
        #expect(engine.restTimeRemaining == 60)
        #expect(engine.restDuration == 60)
    }

    @Test func skipRestTimer_stopsResting() throws {
        let (engine, context) = try makeEngine()
        let session = makeSessionWithLogs(context: context)
        engine.resumeSession(session, previous: nil)
        engine.startRestTimer(duration: 60)
        engine.skipRestTimer()
        #expect(!engine.isResting)
        #expect(engine.restTimeRemaining == 0)
    }

    // MARK: - 1RM

    @Test func estimated1RM_fromCompletedSets() throws {
        let (engine, context) = try makeEngine()
        let session = makeSessionWithLogs(context: context)
        // Mark a set as completed
        let sets = session.exerciseLogs.first!.sets
        sets.first!.isCompleted = true
        let result = engine.estimated1RM(completedSets: sets)
        #expect(result != nil)
        // 60 * (1 + 10/30) = 80
        #expect(result == 80.0)
    }

    // MARK: - Auto-fill

    @Test func autoFillNextSet_copiesWeightAndReps() throws {
        let (engine, context) = try makeEngine()

        let log = ExerciseLog(exerciseName: "Bench", sortOrder: 0)
        context.insert(log)

        let set1 = SetLog(setNumber: 1, reps: 8, weightKg: 60)
        set1.isCompleted = true
        set1.exerciseLog = log
        context.insert(set1)

        let set2 = SetLog(setNumber: 2, reps: 0, weightKg: 0)
        set2.exerciseLog = log
        context.insert(set2)

        try context.save()

        engine.autoFillNextSet(in: log, afterSet: set1)

        #expect(set2.reps == 8)
        #expect(set2.weightKg == 60)
    }

    @Test func autoFillNextSet_doesNotOverwriteUserValues() throws {
        let (engine, context) = try makeEngine()

        let log = ExerciseLog(exerciseName: "Squat", sortOrder: 0)
        context.insert(log)

        let set1 = SetLog(setNumber: 1, reps: 10, weightKg: 80)
        set1.isCompleted = true
        set1.exerciseLog = log
        context.insert(set1)

        let set2 = SetLog(setNumber: 2, reps: 5, weightKg: 70)
        set2.exerciseLog = log
        context.insert(set2)

        try context.save()

        engine.autoFillNextSet(in: log, afterSet: set1)

        #expect(set2.reps == 5)
        #expect(set2.weightKg == 70)
    }

    @Test func autoFillNextSet_skipsCompletedSets() throws {
        let (engine, context) = try makeEngine()

        let log = ExerciseLog(exerciseName: "Row", sortOrder: 0)
        context.insert(log)

        let set1 = SetLog(setNumber: 1, reps: 8, weightKg: 50)
        set1.isCompleted = true
        set1.exerciseLog = log
        context.insert(set1)

        let set2 = SetLog(setNumber: 2, reps: 8, weightKg: 50)
        set2.isCompleted = true
        set2.exerciseLog = log
        context.insert(set2)

        let set3 = SetLog(setNumber: 3, reps: 0, weightKg: 0)
        set3.exerciseLog = log
        context.insert(set3)

        try context.save()

        engine.autoFillNextSet(in: log, afterSet: set1)

        #expect(set3.reps == 8)
        #expect(set3.weightKg == 50)
    }

    @Test func autoFillNextSet_isometricCopiesSeconds() throws {
        let (engine, context) = try makeEngine()

        let log = ExerciseLog(exerciseName: "Plank", sortOrder: 0, isIsometric: true)
        context.insert(log)

        let set1 = SetLog(setNumber: 1, reps: 0, seconds: 45, weightKg: 10)
        set1.isCompleted = true
        set1.exerciseLog = log
        context.insert(set1)

        let set2 = SetLog(setNumber: 2, reps: 0, seconds: 0, weightKg: 0)
        set2.exerciseLog = log
        context.insert(set2)

        try context.save()

        engine.autoFillNextSet(in: log, afterSet: set1)

        #expect(set2.seconds == 45)
        #expect(set2.weightKg == 10)
    }

    @Test func autoFillNextSet_noopWhenLastSet() throws {
        let (engine, context) = try makeEngine()

        let log = ExerciseLog(exerciseName: "Curl", sortOrder: 0)
        context.insert(log)

        let set1 = SetLog(setNumber: 1, reps: 10, weightKg: 15)
        set1.isCompleted = true
        set1.exerciseLog = log
        context.insert(set1)

        try context.save()

        engine.autoFillNextSet(in: log, afterSet: set1)
        // No crash, no side effects
    }

    // MARK: - Skip inter-exercise timer

    @Test func shouldStartRestTimer_trueForMidExerciseSet() throws {
        let (engine, context) = try makeEngine()

        let log = ExerciseLog(exerciseName: "Bench", sortOrder: 0)
        context.insert(log)

        let set1 = SetLog(setNumber: 1, reps: 8, weightKg: 60)
        set1.exerciseLog = log
        context.insert(set1)

        let set2 = SetLog(setNumber: 2, reps: 8, weightKg: 60)
        set2.exerciseLog = log
        context.insert(set2)

        try context.save()

        #expect(engine.shouldStartRestTimer(in: log, afterSet: set1) == true)
    }

    @Test func shouldStartRestTimer_falseForLastSetOfExercise() throws {
        let (engine, context) = try makeEngine()

        let log = ExerciseLog(exerciseName: "Bench", sortOrder: 0)
        context.insert(log)

        let set1 = SetLog(setNumber: 1, reps: 8, weightKg: 60)
        set1.exerciseLog = log
        context.insert(set1)

        let set2 = SetLog(setNumber: 2, reps: 8, weightKg: 60)
        set2.exerciseLog = log
        context.insert(set2)

        try context.save()

        #expect(engine.shouldStartRestTimer(in: log, afterSet: set2) == false)
    }

    // MARK: - Progress excludes warm-ups

    @Test func progress_excludesWarmUpSets() throws {
        let (engine, context) = try makeEngine()

        let session = WorkoutSession()
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Squat", sortOrder: 0)
        log.session = session
        context.insert(log)

        let warmUp = SetLog(setNumber: 1, reps: 5, weightKg: 40, setType: .warmUp)
        warmUp.isCompleted = true
        warmUp.exerciseLog = log
        context.insert(warmUp)

        let working1 = SetLog(setNumber: 2, reps: 5, weightKg: 100)
        working1.isCompleted = true
        working1.exerciseLog = log
        context.insert(working1)

        let working2 = SetLog(setNumber: 3, reps: 5, weightKg: 100)
        working2.exerciseLog = log
        context.insert(working2)

        try context.save()

        engine.resumeSession(session, previous: nil)

        #expect(engine.completedCount == 1)
        #expect(engine.totalCount == 2)
        #expect(engine.progress == 0.5)
    }
}
