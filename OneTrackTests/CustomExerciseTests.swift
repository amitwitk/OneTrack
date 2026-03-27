import Testing
import Foundation
import SwiftData
@testable import OneTrack

@Suite("Custom Exercises")
@MainActor
struct CustomExerciseTests {

    @Test func createCustomExercise() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let exercise = CustomExercise(name: "Hip Thrust", category: "Legs", defaultSets: 4, defaultReps: 12)
        context.insert(exercise)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<CustomExercise>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Hip Thrust")
        #expect(fetched.first?.category == "Legs")
    }

    @Test func customExerciseToTemplate() {
        let exercise = CustomExercise(name: "Box Jump", category: "Legs", defaultSets: 3, defaultReps: 8)
        let template = exercise.toTemplate()
        #expect(template.name == "Box Jump")
        #expect(template.category == "Legs")
        #expect(template.defaultSets == 3)
        #expect(template.defaultReps == 8)
        #expect(!template.isIsometric)
    }

    @Test func isometricCustomExercise() {
        let exercise = CustomExercise(name: "L-Sit", category: "Core", defaultSets: 3, defaultReps: 0, isIsometric: true, defaultSeconds: 20)
        let template = exercise.toTemplate()
        #expect(template.isIsometric)
        #expect(template.defaultSeconds == 20)
        #expect(template.displayTarget == "3 x 20s")
    }

    @Test func multipleCustomExercisesPersist() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        context.insert(CustomExercise(name: "Exercise A", category: "Chest"))
        context.insert(CustomExercise(name: "Exercise B", category: "Back"))
        context.insert(CustomExercise(name: "Exercise C", category: "Core", isIsometric: true))
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<CustomExercise>())
        #expect(fetched.count == 3)
    }
}
