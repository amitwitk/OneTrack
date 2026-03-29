import Testing
import Foundation
import SwiftData
@testable import OneTrack

@Suite("Exercise Iso/Regular Toggle")
struct ExerciseIsoToggleTests {

    @Test func targetDisplay_repBased() {
        let exercise = Exercise(name: "Bench Press", targetSets: 3, targetReps: 10, sortOrder: 0)
        #expect(exercise.targetDisplay == "3 x 10")
    }

    @Test func targetDisplay_isometric() {
        let exercise = Exercise(name: "Plank", targetSets: 3, targetReps: 0, sortOrder: 0, isIsometric: true, targetSeconds: 60)
        #expect(exercise.targetDisplay == "3 x 60s")
    }

    @Test func switchToIso_setsDefaultSeconds() {
        let exercise = Exercise(name: "Wall Sit", targetSets: 3, targetReps: 12, sortOrder: 0)
        #expect(exercise.isIsometric == false)
        #expect(exercise.targetSeconds == 30)

        // Simulate toggle: switch to isometric
        exercise.isIsometric = true
        // EditExerciseView sets default 30s when targetSeconds == 0
        if exercise.isIsometric && exercise.targetSeconds == 0 {
            exercise.targetSeconds = 30
        }

        #expect(exercise.isIsometric == true)
        #expect(exercise.targetSeconds == 30)
        #expect(exercise.targetDisplay == "3 x 30s")
    }

    @Test func switchToReps_setsDefaultReps() {
        let exercise = Exercise(name: "Plank", targetSets: 3, targetReps: 0, sortOrder: 0, isIsometric: true, targetSeconds: 60)
        #expect(exercise.isIsometric == true)

        // Simulate toggle: switch to reps
        exercise.isIsometric = false
        // EditExerciseView sets default 10 reps when targetReps == 0
        if !exercise.isIsometric && exercise.targetReps == 0 {
            exercise.targetReps = 10
        }

        #expect(exercise.isIsometric == false)
        #expect(exercise.targetReps == 10)
        #expect(exercise.targetDisplay == "3 x 10")
    }

    @Test func switchToIso_preservesExistingSeconds() {
        let exercise = Exercise(name: "Plank", targetSets: 3, targetReps: 10, sortOrder: 0, isIsometric: false, targetSeconds: 45)

        exercise.isIsometric = true
        // targetSeconds is already 45, not 0, so no default applied
        if exercise.isIsometric && exercise.targetSeconds == 0 {
            exercise.targetSeconds = 30
        }

        #expect(exercise.targetSeconds == 45)
        #expect(exercise.targetDisplay == "3 x 45s")
    }

    @Test func switchToReps_preservesExistingReps() {
        let exercise = Exercise(name: "Bench Press", targetSets: 4, targetReps: 8, sortOrder: 0)

        exercise.isIsometric = true
        exercise.isIsometric = false
        // targetReps is already 8, not 0, so no default applied
        if !exercise.isIsometric && exercise.targetReps == 0 {
            exercise.targetReps = 10
        }

        #expect(exercise.targetReps == 8)
        #expect(exercise.targetDisplay == "4 x 8")
    }
}
