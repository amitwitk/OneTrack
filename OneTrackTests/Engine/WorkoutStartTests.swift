import Testing
import Foundation
import SwiftData
@testable import OneTrack

@Suite("Workout Start")
@MainActor
struct WorkoutStartTests {

    @Test func startWorkout_createsSessionWithExerciseLogs() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let plan = WorkoutPlan(name: "Push Day", planDescription: "", sortOrder: 0)
        context.insert(plan)

        let ex1 = Exercise(name: "Bench Press", targetSets: 3, targetReps: 10, sortOrder: 0)
        ex1.plan = plan
        context.insert(ex1)

        let ex2 = Exercise(name: "OHP", targetSets: 3, targetReps: 8, sortOrder: 1)
        ex2.plan = plan
        context.insert(ex2)
        try context.save()

        // Simulate what WorkoutPlanListView.startWorkout does
        let session = WorkoutSession(plan: plan)
        context.insert(session)

        for exercise in plan.exercises.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            let log = ExerciseLog(
                exerciseName: exercise.name,
                sortOrder: exercise.sortOrder,
                isIsometric: exercise.isIsometric,
                section: exercise.section
            )
            log.session = session
            context.insert(log)

            for setIndex in 0..<exercise.targetSets {
                let setLog = SetLog(
                    setNumber: setIndex + 1,
                    reps: exercise.targetReps,
                    weightKg: 0
                )
                setLog.exerciseLog = log
                context.insert(setLog)
            }
        }
        try context.save()

        #expect(session.exerciseLogs.count == 2)
        #expect(session.exerciseLogs.flatMap(\.sets).count == 6)
    }

    @Test func startWorkout_engineResumesSuccessfully() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let plan = WorkoutPlan(name: "Test", planDescription: "", sortOrder: 0)
        context.insert(plan)

        let exercise = Exercise(name: "Squat", targetSets: 4, targetReps: 8, sortOrder: 0)
        exercise.plan = plan
        context.insert(exercise)

        let session = WorkoutSession(plan: plan)
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Squat", sortOrder: 0)
        log.session = session
        context.insert(log)

        for i in 1...4 {
            let setLog = SetLog(setNumber: i, reps: 8, weightKg: 0)
            setLog.exerciseLog = log
            context.insert(setLog)
        }
        try context.save()

        // Simulate what ActiveWorkoutView.onAppear does
        let engine = WorkoutEngine(modelContext: context)
        engine.resumeSession(session, previous: nil)

        #expect(engine.isActive)
        #expect(engine.sortedLogs.count == 1)
        #expect(engine.totalCount == 4)
        #expect(engine.completedCount == 0)
    }

    @Test func startWorkout_withPreviousSession_autoFillsWeights() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let plan = WorkoutPlan(name: "Test", planDescription: "", sortOrder: 0)
        context.insert(plan)

        let exercise = Exercise(name: "Bench", targetSets: 3, targetReps: 10, sortOrder: 0)
        exercise.plan = plan
        context.insert(exercise)

        // Previous completed session
        let prevSession = WorkoutSession(
            date: Calendar.current.date(byAdding: .day, value: -3, to: .now)!,
            plan: plan
        )
        prevSession.isCompleted = true
        context.insert(prevSession)

        let prevLog = ExerciseLog(exerciseName: "Bench", sortOrder: 0)
        prevLog.session = prevSession
        context.insert(prevLog)

        let prevSet = SetLog(setNumber: 1, reps: 10, weightKg: 80)
        prevSet.isCompleted = true
        prevSet.exerciseLog = prevLog
        context.insert(prevSet)
        try context.save()

        // Start new session (simulating WorkoutPlanListView.startWorkout)
        let newSession = WorkoutSession(plan: plan)
        context.insert(newSession)

        let previous = plan.sessions
            .filter { $0.isCompleted && $0.id != newSession.id }
            .sorted { $0.date > $1.date }
            .first

        #expect(previous != nil)

        let prevSets = previous?.exerciseLogs
            .first { $0.exerciseName == "Bench" }?
            .sets.sorted { $0.setNumber < $1.setNumber } ?? []

        let log = ExerciseLog(exerciseName: "Bench", sortOrder: 0)
        log.session = newSession
        context.insert(log)

        for setIndex in 0..<exercise.targetSets {
            let prevSetData = setIndex < prevSets.count ? prevSets[setIndex] : nil
            let setLog = SetLog(
                setNumber: setIndex + 1,
                reps: prevSetData?.reps ?? exercise.targetReps,
                weightKg: prevSetData?.weightKg ?? 0
            )
            setLog.exerciseLog = log
            context.insert(setLog)
        }
        try context.save()

        // First set should have previous session's weight
        let newSets = log.sets.sorted { $0.setNumber < $1.setNumber }
        #expect(newSets[0].weightKg == 80)
        #expect(newSets[0].reps == 10)
    }

    @Test func startWorkout_isometricExercise_setsSeconds() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let plan = WorkoutPlan(name: "Core", planDescription: "", sortOrder: 0)
        context.insert(plan)

        let exercise = Exercise(name: "Plank", targetSets: 3, targetReps: 0, sortOrder: 0, isIsometric: true, targetSeconds: 60)
        exercise.plan = plan
        context.insert(exercise)

        let session = WorkoutSession(plan: plan)
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Plank", sortOrder: 0, isIsometric: true)
        log.session = session
        context.insert(log)

        for setIndex in 0..<exercise.targetSets {
            let setLog = SetLog(
                setNumber: setIndex + 1,
                reps: exercise.targetReps,
                seconds: exercise.targetSeconds,
                weightKg: 0
            )
            setLog.exerciseLog = log
            context.insert(setLog)
        }
        try context.save()

        let sets = log.sets.sorted { $0.setNumber < $1.setNumber }
        #expect(sets.count == 3)
        #expect(sets[0].seconds == 60)
        #expect(log.isIsometric)
    }
}
