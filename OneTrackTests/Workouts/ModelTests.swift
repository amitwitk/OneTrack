import Testing
import Foundation
import SwiftData
@testable import OneTrack

@Suite("SwiftData Models")
@MainActor
struct ModelTests {

    @Test func createWorkoutPlan() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let plan = WorkoutPlan(name: "Test Plan", planDescription: "A test", sortOrder: 0)
        context.insert(plan)
        try context.save()

        let descriptor = FetchDescriptor<WorkoutPlan>()
        let plans = try context.fetch(descriptor)
        #expect(plans.count == 1)
        #expect(plans.first?.name == "Test Plan")
        #expect(plans.first?.defaultRestSeconds == 90)
    }

    @Test func planExerciseRelationship() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let plan = WorkoutPlan(name: "Push", planDescription: "", sortOrder: 0)
        context.insert(plan)

        for i in 0..<3 {
            let ex = Exercise(name: "Exercise \(i)", targetSets: 3, targetReps: 10, sortOrder: i)
            ex.plan = plan
            context.insert(ex)
        }
        try context.save()

        #expect(plan.exercises.count == 3)
        #expect(plan.exercises.allSatisfy { $0.plan?.name == "Push" })
    }

    @Test func cascadeDeletePlanDeletesExercises() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let plan = WorkoutPlan(name: "Delete Me", planDescription: "", sortOrder: 0)
        context.insert(plan)

        let ex = Exercise(name: "Bench", targetSets: 4, targetReps: 10, sortOrder: 0)
        ex.plan = plan
        context.insert(ex)
        try context.save()

        context.delete(plan)
        try context.save()

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.isEmpty)
    }

    @Test func createWorkoutSession() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let plan = WorkoutPlan(name: "Test", planDescription: "", sortOrder: 0)
        context.insert(plan)

        let session = WorkoutSession(plan: plan)
        context.insert(session)
        try context.save()

        #expect(session.isCompleted == false)
        #expect(session.plan?.name == "Test")
    }

    @Test func sessionExerciseLogRelationship() throws {
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

        let set2 = SetLog(setNumber: 2, reps: 8, weightKg: 85)
        set2.exerciseLog = log
        context.insert(set2)
        try context.save()

        #expect(session.exerciseLogs.count == 1)
        #expect(log.sets.count == 2)
    }

    @Test func cascadeDeleteSessionDeletesLogs() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let session = WorkoutSession()
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Squat", sortOrder: 0)
        log.session = session
        context.insert(log)

        let setLog = SetLog(setNumber: 1, reps: 5, weightKg: 100)
        setLog.exerciseLog = log
        context.insert(setLog)
        try context.save()

        context.delete(session)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<ExerciseLog>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<SetLog>()).isEmpty)
    }

    @Test func mealEntryTotalCalories() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let meal = MealEntry(mealType: "Lunch")
        context.insert(meal)

        let ing1 = Ingredient(name: "Chicken", quantity: 200, unit: "g", calories: 240, proteinG: 45, carbsG: 0, fatG: 5.2)
        ing1.meal = meal
        context.insert(ing1)

        let ing2 = Ingredient(name: "Rice", quantity: 150, unit: "g", calories: 195, proteinG: 4, carbsG: 42, fatG: 0.5)
        ing2.meal = meal
        context.insert(ing2)
        try context.save()

        #expect(meal.totalCalories == 435)
        #expect(meal.totalProtein == 49)
    }

    @Test func mealEntryEmptyIngredients() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let meal = MealEntry(mealType: "Snack")
        context.insert(meal)
        try context.save()

        #expect(meal.totalCalories == 0)
    }

    @Test func weightEntryDefaults() {
        let entry = WeightEntry(weightKg: 80)
        #expect(entry.source == "manual")
    }

    @Test func bodyMeasurementOptionalFields() {
        let measurement = BodyMeasurement()
        #expect(measurement.waistCm == nil)
        #expect(measurement.chestCm == nil)
        #expect(measurement.leftBicepCm == nil)
        #expect(measurement.rightBicepCm == nil)
    }

    // MARK: - SetType Tests

    @Test func setLog_defaultSetType_isNormal() {
        let setLog = SetLog(setNumber: 1, reps: 10, weightKg: 80)
        #expect(setLog.setType == .normal)
        #expect(setLog.isWarmUp == false)
    }

    @Test func setLog_warmUpSetType() {
        let setLog = SetLog(setNumber: 1, reps: 10, weightKg: 40, setType: .warmUp)
        #expect(setLog.setType == .warmUp)
        #expect(setLog.isWarmUp == true)
    }

    @Test func setLog_setTypeCycling() {
        let setLog = SetLog(setNumber: 1, reps: 10, weightKg: 60)
        #expect(setLog.setType == .normal)

        setLog.setType = .warmUp
        #expect(setLog.setType == .warmUp)
        #expect(setLog.setTypeRaw == "warmUp")

        setLog.setType = .dropSet
        #expect(setLog.setType == .dropSet)

        setLog.setType = .toFailure
        #expect(setLog.setType == .toFailure)

        setLog.setType = .normal
        #expect(setLog.setType == .normal)
    }

    @Test func setLog_allSetTypes() {
        let allTypes: [SetType] = [.normal, .warmUp, .dropSet, .toFailure]
        #expect(SetType.allCases.count == 4)
        for setType in allTypes {
            let setLog = SetLog(setNumber: 1, setType: setType)
            #expect(setLog.setType == setType)
        }
    }

    // MARK: - RPE Tests

    @Test func workoutSession_rpeDefaultsToNil() {
        let session = WorkoutSession()
        #expect(session.rpe == nil)
    }

    @Test func workoutSession_rpeCanBeSet() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let session = WorkoutSession()
        session.rpe = 8
        context.insert(session)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<WorkoutSession>())
        #expect(fetched.first?.rpe == 8)
    }
}
