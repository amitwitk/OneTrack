import Testing
import Foundation
import SwiftData
@testable import OneTrack

@Suite("Plan Management")
@MainActor
struct PlanManagementTests {

    // MARK: - Exercise Reorder

    @Test func reorderExercisesWithinSection() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let plan = WorkoutPlan(name: "Test", planDescription: "", sortOrder: 0)
        context.insert(plan)

        let ex1 = Exercise(name: "Bench", targetSets: 3, targetReps: 10, sortOrder: 0)
        let ex2 = Exercise(name: "Squat", targetSets: 3, targetReps: 10, sortOrder: 1)
        let ex3 = Exercise(name: "Deadlift", targetSets: 3, targetReps: 10, sortOrder: 2)
        for ex in [ex1, ex2, ex3] {
            ex.plan = plan
            context.insert(ex)
        }
        try context.save()

        // Move Deadlift (index 2) to position 0
        PlanManagement.reorderExercises(
            allExercises: plan.exercises,
            inSection: "",
            from: IndexSet(integer: 2),
            to: 0
        )

        let sorted = plan.exercises.sorted { $0.sortOrder < $1.sortOrder }
        #expect(sorted[0].name == "Deadlift")
        #expect(sorted[1].name == "Bench")
        #expect(sorted[2].name == "Squat")
    }

    @Test func reorderExercisesPreservesOtherSections() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let plan = WorkoutPlan(name: "Test", planDescription: "", sortOrder: 0)
        context.insert(plan)

        let ex1 = Exercise(name: "Bench", targetSets: 3, targetReps: 10, sortOrder: 0, section: "Push")
        let ex2 = Exercise(name: "OHP", targetSets: 3, targetReps: 10, sortOrder: 1, section: "Push")
        let ex3 = Exercise(name: "Squat", targetSets: 3, targetReps: 10, sortOrder: 2, section: "Legs")
        for ex in [ex1, ex2, ex3] {
            ex.plan = plan
            context.insert(ex)
        }
        try context.save()

        // Move OHP (index 1 in "Push") to position 0
        PlanManagement.reorderExercises(
            allExercises: plan.exercises,
            inSection: "Push",
            from: IndexSet(integer: 1),
            to: 0
        )

        let sorted = plan.exercises.sorted { $0.sortOrder < $1.sortOrder }
        #expect(sorted[0].name == "OHP")
        #expect(sorted[1].name == "Bench")
        #expect(sorted[2].name == "Squat")
        #expect(sorted[2].section == "Legs")
    }

    // MARK: - Move Exercise to Section

    @Test func moveExerciseToSection() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let plan = WorkoutPlan(name: "Test", planDescription: "", sortOrder: 0)
        context.insert(plan)

        let ex1 = Exercise(name: "Bench", targetSets: 3, targetReps: 10, sortOrder: 0, section: "Push")
        let ex2 = Exercise(name: "Squat", targetSets: 3, targetReps: 10, sortOrder: 1, section: "Push")
        for ex in [ex1, ex2] {
            ex.plan = plan
            context.insert(ex)
        }
        try context.save()

        PlanManagement.moveExerciseToSection(ex2, newSection: "Legs", allExercises: plan.exercises)

        #expect(ex2.section == "Legs")
    }

    // MARK: - Delete Exercises

    @Test func deleteExerciseRecalculatesSortOrder() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let plan = WorkoutPlan(name: "Test", planDescription: "", sortOrder: 0)
        context.insert(plan)

        let ex1 = Exercise(name: "A", targetSets: 3, targetReps: 10, sortOrder: 0)
        let ex2 = Exercise(name: "B", targetSets: 3, targetReps: 10, sortOrder: 1)
        let ex3 = Exercise(name: "C", targetSets: 3, targetReps: 10, sortOrder: 2)
        for ex in [ex1, ex2, ex3] {
            ex.plan = plan
            context.insert(ex)
        }
        try context.save()

        let toDelete = PlanManagement.deleteExercises(
            allExercises: plan.exercises,
            inSection: "",
            at: IndexSet(integer: 1) // Delete "B"
        )

        #expect(toDelete.count == 1)
        #expect(toDelete[0].name == "B")

        let remaining = plan.exercises.filter { !toDelete.contains($0) }
            .sorted { $0.sortOrder < $1.sortOrder }
        #expect(remaining[0].sortOrder == 0)
        #expect(remaining[1].sortOrder == 1)
    }

    // MARK: - Plan Reorder

    @Test func reorderPlans() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let p1 = WorkoutPlan(name: "Push", planDescription: "", sortOrder: 0)
        let p2 = WorkoutPlan(name: "Pull", planDescription: "", sortOrder: 1)
        let p3 = WorkoutPlan(name: "Legs", planDescription: "", sortOrder: 2)
        for p in [p1, p2, p3] { context.insert(p) }
        try context.save()

        var plans = [p1, p2, p3]
        PlanManagement.reorderPlans(&plans, from: IndexSet(integer: 2), to: 0)

        #expect(plans[0].name == "Legs")
        #expect(plans[0].sortOrder == 0)
        #expect(plans[1].name == "Push")
        #expect(plans[1].sortOrder == 1)
        #expect(plans[2].name == "Pull")
        #expect(plans[2].sortOrder == 2)
    }

    // MARK: - Set Deletion

    @Test func deleteSetRenumbersRemaining() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let log = ExerciseLog(exerciseName: "Bench", sortOrder: 0)
        context.insert(log)

        let s1 = SetLog(setNumber: 1, reps: 10, weightKg: 80)
        let s2 = SetLog(setNumber: 2, reps: 8, weightKg: 85)
        let s3 = SetLog(setNumber: 3, reps: 6, weightKg: 90)
        for s in [s1, s2, s3] {
            s.exerciseLog = log
            context.insert(s)
        }
        try context.save()

        PlanManagement.deleteSet(s2, from: log)

        let remaining = log.sets
            .filter { $0.id != s2.id }
            .sorted { $0.setNumber < $1.setNumber }
        #expect(remaining.count == 2)
        #expect(remaining[0].setNumber == 1)
        #expect(remaining[0].reps == 10)
        #expect(remaining[1].setNumber == 2)
        #expect(remaining[1].reps == 6)
    }
}
