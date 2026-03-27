import Testing
import Foundation
@testable import OneTrack

@Suite("Exercise Database")
struct ExerciseDatabaseTests {

    @Test func exercisesNotEmpty() {
        #expect(ExerciseDatabase.exercises.count >= 36)
    }

    @Test func categoriesOrder() {
        let expected = ["Chest", "Back", "Shoulders", "Arms", "Legs", "Core"]
        #expect(ExerciseDatabase.categories == expected)
    }

    @Test func searchByName() {
        let results = ExerciseDatabase.search("bench")
        #expect(!results.isEmpty)
        #expect(results.allSatisfy { $0.name.lowercased().contains("bench") })
    }

    @Test func searchByCategory() {
        let results = ExerciseDatabase.search("chest")
        #expect(!results.isEmpty)
    }

    @Test func searchEmpty() {
        let results = ExerciseDatabase.search("")
        #expect(results.count == ExerciseDatabase.exercises.count)
    }

    @Test func searchNoResults() {
        let results = ExerciseDatabase.search("zzzzzzz")
        #expect(results.isEmpty)
    }

    @Test func exercisesInCategory() {
        let chest = ExerciseDatabase.exercises(in: "Chest")
        #expect(chest.count == 7)
    }

    @Test func exercisesInInvalidCategory() {
        let results = ExerciseDatabase.exercises(in: "Nonexistent")
        #expect(results.isEmpty)
    }

    @Test func allExercisesHaveValidDefaults() {
        for exercise in ExerciseDatabase.exercises {
            #expect(exercise.defaultSets > 0, "Exercise \(exercise.name) has invalid sets")
            #expect(exercise.defaultReps > 0, "Exercise \(exercise.name) has invalid reps")
        }
    }
}
