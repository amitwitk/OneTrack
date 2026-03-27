import Testing
import Foundation
@testable import OneTrack

@Suite("Exercise Database")
struct ExerciseDatabaseTests {

    @Test func exercisesNotEmpty() {
        #expect(ExerciseDatabase.exercises.count >= 40)
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

    @Test func isometricExercisesExist() {
        let iso = ExerciseDatabase.exercises.filter(\.isIsometric)
        #expect(iso.count >= 4)
        #expect(iso.allSatisfy { $0.defaultSeconds > 0 })
    }

    @Test func isometricDisplayTarget() {
        let plank = ExerciseDatabase.exercises.first { $0.name == "Plank" }!
        #expect(plank.isIsometric)
        #expect(plank.displayTarget == "3 x 60s")
    }

    @Test func repBasedDisplayTarget() {
        let bench = ExerciseDatabase.exercises.first { $0.name == "Bench Press" }!
        #expect(!bench.isIsometric)
        #expect(bench.displayTarget == "4 x 10")
    }

    @Test func exercisesInInvalidCategory() {
        let results = ExerciseDatabase.exercises(in: "Nonexistent")
        #expect(results.isEmpty)
    }

    @Test func allExercisesHaveValidDefaults() {
        for exercise in ExerciseDatabase.exercises {
            #expect(exercise.defaultSets > 0, "Exercise \(exercise.name) has invalid sets")
            if exercise.isIsometric {
                #expect(exercise.defaultSeconds > 0, "Isometric exercise \(exercise.name) has invalid seconds")
            } else {
                #expect(exercise.defaultReps > 0, "Exercise \(exercise.name) has invalid reps")
            }
        }
    }
}
