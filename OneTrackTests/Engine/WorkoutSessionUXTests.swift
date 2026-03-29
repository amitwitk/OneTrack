import Testing
import Foundation
import SwiftData
@testable import OneTrack

@Suite("Workout Session UX")
@MainActor
struct WorkoutSessionUXTests {

    // MARK: - Auto-fill weight/reps from completed set

    @Test func autoFill_nextSetGetsWeightFromCompletedSet() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let session = WorkoutSession()
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Bench", sortOrder: 0)
        log.session = session
        context.insert(log)

        let s1 = SetLog(setNumber: 1, reps: 10, weightKg: 80)
        s1.exerciseLog = log
        context.insert(s1)

        let s2 = SetLog(setNumber: 2, reps: 0, weightKg: 0)
        s2.exerciseLog = log
        context.insert(s2)
        try context.save()

        let engine = WorkoutEngine(modelContext: context)
        engine.resumeSession(session, previous: nil)

        // Complete set 1
        s1.isCompleted = true
        engine.autoFillNextSet(after: s1, in: log)

        #expect(s2.weightKg == 80)
        #expect(s2.reps == 10)
    }

    @Test func autoFill_doesNotOverwriteUserEnteredValues() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let session = WorkoutSession()
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Bench", sortOrder: 0)
        log.session = session
        context.insert(log)

        let s1 = SetLog(setNumber: 1, reps: 10, weightKg: 80)
        s1.exerciseLog = log
        context.insert(s1)

        // User already entered different values for set 2
        let s2 = SetLog(setNumber: 2, reps: 8, weightKg: 85)
        s2.exerciseLog = log
        context.insert(s2)
        try context.save()

        let engine = WorkoutEngine(modelContext: context)
        engine.resumeSession(session, previous: nil)

        s1.isCompleted = true
        engine.autoFillNextSet(after: s1, in: log)

        // Should NOT overwrite since user already set values
        #expect(s2.weightKg == 85)
        #expect(s2.reps == 8)
    }

    @Test func autoFill_isometricFillsSeconds() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let session = WorkoutSession()
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Plank", sortOrder: 0, isIsometric: true)
        log.session = session
        context.insert(log)

        let s1 = SetLog(setNumber: 1, seconds: 60, weightKg: 0)
        s1.exerciseLog = log
        context.insert(s1)

        let s2 = SetLog(setNumber: 2, seconds: 0, weightKg: 0)
        s2.exerciseLog = log
        context.insert(s2)
        try context.save()

        let engine = WorkoutEngine(modelContext: context)
        engine.resumeSession(session, previous: nil)

        s1.isCompleted = true
        engine.autoFillNextSet(after: s1, in: log)

        #expect(s2.seconds == 60)
    }

    @Test func autoFill_noNextSet_noCrash() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let session = WorkoutSession()
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Bench", sortOrder: 0)
        log.session = session
        context.insert(log)

        let s1 = SetLog(setNumber: 1, reps: 10, weightKg: 80)
        s1.exerciseLog = log
        context.insert(s1)
        try context.save()

        let engine = WorkoutEngine(modelContext: context)
        engine.resumeSession(session, previous: nil)

        s1.isCompleted = true
        // Should not crash when there's no next set
        engine.autoFillNextSet(after: s1, in: log)
    }

    // MARK: - Inter-exercise timer

    @Test func isLastSetInExercise_true() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let log = ExerciseLog(exerciseName: "Bench", sortOrder: 0)
        context.insert(log)

        let s1 = SetLog(setNumber: 1, reps: 10, weightKg: 80)
        s1.isCompleted = true
        s1.exerciseLog = log
        context.insert(s1)

        let s2 = SetLog(setNumber: 2, reps: 10, weightKg: 80)
        s2.isCompleted = true
        s2.exerciseLog = log
        context.insert(s2)
        try context.save()

        // s2 is the last set and it's completed — all sets done
        #expect(WorkoutEngine.isLastSetInExercise(s2, in: log))
    }

    @Test func isLastSetInExercise_false_moreToGo() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let log = ExerciseLog(exerciseName: "Bench", sortOrder: 0)
        context.insert(log)

        let s1 = SetLog(setNumber: 1, reps: 10, weightKg: 80)
        s1.exerciseLog = log
        context.insert(s1)

        let s2 = SetLog(setNumber: 2, reps: 10, weightKg: 80)
        s2.exerciseLog = log
        context.insert(s2)
        try context.save()

        // s1 is not the last set — s2 still exists after it
        #expect(!WorkoutEngine.isLastSetInExercise(s1, in: log))
    }
}
