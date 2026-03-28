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
}
