import Testing
import Foundation
import SwiftData
@testable import OneTrack

@Suite("Workout Engine - Reorder & Swap")
@MainActor
struct WorkoutEngineReorderSwapTests {

    // MARK: - Reorder

    @Test func reorderExercises_moveFirstToLast() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let session = WorkoutSession()
        context.insert(session)

        let log1 = ExerciseLog(exerciseName: "Bench Press", sortOrder: 0)
        log1.session = session
        context.insert(log1)

        let log2 = ExerciseLog(exerciseName: "Squat", sortOrder: 1)
        log2.session = session
        context.insert(log2)

        let log3 = ExerciseLog(exerciseName: "Deadlift", sortOrder: 2)
        log3.session = session
        context.insert(log3)
        try context.save()

        let engine = WorkoutEngine(modelContext: context)
        engine.resumeSession(session, previous: nil)

        // Move Bench Press (index 0) to position 3 (end)
        engine.reorderExercises(from: IndexSet(integer: 0), to: 3)

        let sorted = engine.sortedLogs
        #expect(sorted[0].exerciseName == "Squat")
        #expect(sorted[1].exerciseName == "Deadlift")
        #expect(sorted[2].exerciseName == "Bench Press")
        #expect(sorted[0].sortOrder == 0)
        #expect(sorted[1].sortOrder == 1)
        #expect(sorted[2].sortOrder == 2)
    }

    @Test func reorderExercises_moveLastToFirst() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let session = WorkoutSession()
        context.insert(session)

        let log1 = ExerciseLog(exerciseName: "A", sortOrder: 0)
        log1.session = session
        context.insert(log1)

        let log2 = ExerciseLog(exerciseName: "B", sortOrder: 1)
        log2.session = session
        context.insert(log2)

        let log3 = ExerciseLog(exerciseName: "C", sortOrder: 2)
        log3.session = session
        context.insert(log3)
        try context.save()

        let engine = WorkoutEngine(modelContext: context)
        engine.resumeSession(session, previous: nil)

        // Move C (index 2) to position 0
        engine.reorderExercises(from: IndexSet(integer: 2), to: 0)

        let sorted = engine.sortedLogs
        #expect(sorted[0].exerciseName == "C")
        #expect(sorted[1].exerciseName == "A")
        #expect(sorted[2].exerciseName == "B")
    }

    @Test func reorderExercises_doesNotModifyPlan() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let plan = WorkoutPlan(name: "Test", planDescription: "", sortOrder: 0)
        context.insert(plan)

        let ex1 = Exercise(name: "Bench", targetSets: 3, targetReps: 10, sortOrder: 0)
        ex1.plan = plan
        context.insert(ex1)
        let ex2 = Exercise(name: "Squat", targetSets: 3, targetReps: 10, sortOrder: 1)
        ex2.plan = plan
        context.insert(ex2)

        let session = WorkoutSession(plan: plan)
        context.insert(session)

        let log1 = ExerciseLog(exerciseName: "Bench", sortOrder: 0)
        log1.session = session
        context.insert(log1)
        let log2 = ExerciseLog(exerciseName: "Squat", sortOrder: 1)
        log2.session = session
        context.insert(log2)
        try context.save()

        let engine = WorkoutEngine(modelContext: context)
        engine.resumeSession(session, previous: nil)

        engine.reorderExercises(from: IndexSet(integer: 0), to: 2)

        // Plan exercises should remain unchanged
        let planExercises = plan.exercises.sorted { $0.sortOrder < $1.sortOrder }
        #expect(planExercises[0].name == "Bench")
        #expect(planExercises[1].name == "Squat")
    }

    // MARK: - Swap

    @Test func swapExercise_changesName() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let session = WorkoutSession()
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Bench Press", sortOrder: 0)
        log.session = session
        context.insert(log)

        let set1 = SetLog(setNumber: 1, reps: 10, weightKg: 80)
        set1.exerciseLog = log
        context.insert(set1)
        try context.save()

        let engine = WorkoutEngine(modelContext: context)
        engine.resumeSession(session, previous: nil)

        let replacement = ExerciseTemplate(name: "Dumbbell Press", category: "Chest", defaultSets: 3, defaultReps: 10)
        engine.swapExercise(log, with: replacement)

        #expect(log.exerciseName == "Dumbbell Press")
        #expect(log.swappedFromExercise == "Bench Press")
    }

    @Test func swapExercise_preservesSets() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let session = WorkoutSession()
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Bench Press", sortOrder: 0)
        log.session = session
        context.insert(log)

        let set1 = SetLog(setNumber: 1, reps: 10, weightKg: 80)
        set1.isCompleted = true
        set1.exerciseLog = log
        context.insert(set1)

        let set2 = SetLog(setNumber: 2, reps: 8, weightKg: 85)
        set2.exerciseLog = log
        context.insert(set2)
        try context.save()

        let engine = WorkoutEngine(modelContext: context)
        engine.resumeSession(session, previous: nil)

        let replacement = ExerciseTemplate(name: "Incline Press", category: "Chest", defaultSets: 3, defaultReps: 10)
        engine.swapExercise(log, with: replacement)

        // Sets should be preserved
        #expect(log.sets.count == 2)
        #expect(log.sets.contains(where: { $0.weightKg == 80 }))
        #expect(log.sets.contains(where: { $0.weightKg == 85 }))
    }

    @Test func swapExercise_clearsPRFlags() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let session = WorkoutSession()
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Bench Press", sortOrder: 0)
        log.session = session
        context.insert(log)

        let set1 = SetLog(setNumber: 1, reps: 10, weightKg: 100)
        set1.isCompleted = true
        set1.isPersonalRecord = true
        set1.exerciseLog = log
        context.insert(set1)
        try context.save()

        let engine = WorkoutEngine(modelContext: context)
        engine.resumeSession(session, previous: nil)

        let replacement = ExerciseTemplate(name: "OHP", category: "Shoulders", defaultSets: 3, defaultReps: 10)
        engine.swapExercise(log, with: replacement)

        #expect(!set1.isPersonalRecord) // PR cleared — different exercise
    }

    @Test func swapExercise_updatesIsometric() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let session = WorkoutSession()
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Bench Press", sortOrder: 0)
        log.session = session
        context.insert(log)
        try context.save()

        let engine = WorkoutEngine(modelContext: context)
        engine.resumeSession(session, previous: nil)

        #expect(!log.isIsometric)

        let isoTemplate = ExerciseTemplate(name: "Plank", category: "Core", defaultSets: 3, defaultReps: 0, isIsometric: true, defaultSeconds: 60)
        engine.swapExercise(log, with: isoTemplate)

        #expect(log.isIsometric)
        #expect(log.exerciseName == "Plank")
    }

    @Test func swapExercise_tracksOriginalName() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let session = WorkoutSession()
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Squat", sortOrder: 0)
        log.session = session
        context.insert(log)
        try context.save()

        let engine = WorkoutEngine(modelContext: context)
        engine.resumeSession(session, previous: nil)

        engine.swapExercise(log, with: ExerciseTemplate(name: "Leg Press", category: "Legs", defaultSets: 3, defaultReps: 12))

        #expect(log.swappedFromExercise == "Squat")

        // Swap again
        engine.swapExercise(log, with: ExerciseTemplate(name: "Hack Squat", category: "Legs", defaultSets: 3, defaultReps: 10))

        // Should still track the ORIGINAL exercise name
        #expect(log.swappedFromExercise == "Squat")
    }
}
