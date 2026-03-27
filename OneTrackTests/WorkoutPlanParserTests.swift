import Testing
import Foundation
@testable import OneTrack

@Suite("Workout Plan Parser")
struct WorkoutPlanParserTests {

    @Test func parseSinglePlan() throws {
        let input = """
        ---
        name: Push Day

        - Bench Press: 4x10
        - Overhead Press: 3x10
        """
        let plans = try WorkoutPlanParser.parse(input)
        #expect(plans.count == 1)
        #expect(plans[0].name == "Push Day")
        #expect(plans[0].exercises.count == 2)
        #expect(plans[0].exercises[0].name == "Bench Press")
        #expect(plans[0].exercises[0].sets == 4)
        #expect(plans[0].exercises[0].reps == 10)
        #expect(!plans[0].exercises[0].isIsometric)
    }

    @Test func parseMultiplePlans() throws {
        let input = """
        ---
        name: Push

        - Bench Press: 4x10

        ---
        name: Pull

        - Deadlift: 4x6
        - Barbell Rows: 4x10
        """
        let plans = try WorkoutPlanParser.parse(input)
        #expect(plans.count == 2)
        #expect(plans[0].name == "Push")
        #expect(plans[1].name == "Pull")
        #expect(plans[1].exercises.count == 2)
    }

    @Test func parseRestTimer() throws {
        let input = """
        ---
        name: Heavy Day
        rest: 180

        - Squats: 5x5
        """
        let plans = try WorkoutPlanParser.parse(input)
        #expect(plans[0].rest == 180)
    }

    @Test func parseDefaultRest() throws {
        let input = """
        ---
        name: Light Day

        - Curls: 3x12
        """
        let plans = try WorkoutPlanParser.parse(input)
        #expect(plans[0].rest == 90)
    }

    @Test func parseIsometricExercise() throws {
        let input = """
        ---
        name: Core

        - Plank: 3x60s
        - Crunches: 3x15
        """
        let plans = try WorkoutPlanParser.parse(input)
        #expect(plans[0].exercises[0].isIsometric)
        #expect(plans[0].exercises[0].seconds == 60)
        #expect(plans[0].exercises[0].reps == 0)
        #expect(!plans[0].exercises[1].isIsometric)
        #expect(plans[0].exercises[1].reps == 15)
    }

    @Test func parseWithoutSeparator() throws {
        let input = """
        name: Quick Workout

        - Push-ups: 3x20
        """
        let plans = try WorkoutPlanParser.parse(input)
        #expect(plans.count == 1)
        #expect(plans[0].name == "Quick Workout")
    }

    @Test func parseBulletPointFormat() throws {
        let input = """
        ---
        name: Test

        • Bench Press: 4x10
        • Squats: 4x8
        """
        let plans = try WorkoutPlanParser.parse(input)
        #expect(plans[0].exercises.count == 2)
    }

    @Test func emptyInputThrows() {
        #expect(throws: PlanParseError.self) {
            try WorkoutPlanParser.parse("")
        }
    }

    @Test func whitespaceOnlyThrows() {
        #expect(throws: PlanParseError.self) {
            try WorkoutPlanParser.parse("   \n   \n   ")
        }
    }

    @Test func invalidExerciseFormatThrows() {
        let input = """
        ---
        name: Bad Plan

        - No colon here
        """
        #expect(throws: PlanParseError.self) {
            try WorkoutPlanParser.parse(input)
        }
    }

    @Test func planWithNoExercisesThrows() {
        let input = """
        ---
        name: Empty Plan
        ---
        name: Good Plan

        - Bench: 4x10
        """
        #expect(throws: PlanParseError.self) {
            try WorkoutPlanParser.parse(input)
        }
    }

    @Test func parseExerciseDirectly() throws {
        let exercise = try WorkoutPlanParser.parseExercise("Bench Press: 4x10", lineNumber: 1)
        #expect(exercise.name == "Bench Press")
        #expect(exercise.sets == 4)
        #expect(exercise.reps == 10)
    }

    @Test func parseIsometricExerciseDirectly() throws {
        let exercise = try WorkoutPlanParser.parseExercise("Plank: 3x60s", lineNumber: 1)
        #expect(exercise.name == "Plank")
        #expect(exercise.sets == 3)
        #expect(exercise.seconds == 60)
        #expect(exercise.isIsometric)
    }

    @Test func parseExerciseWithExtraSpaces() throws {
        let exercise = try WorkoutPlanParser.parseExercise("  Bench Press  :  4x10  ", lineNumber: 1)
        #expect(exercise.name == "Bench Press")
        #expect(exercise.sets == 4)
    }

    @Test func fullRealisticImport() throws {
        let input = """
        ---
        name: Push Day A
        rest: 90

        - Bench Press: 4x10
        - Overhead Press: 3x10
        - Incline Dumbbell Press: 3x12
        - Lateral Raises: 3x15
        - Tricep Pushdowns: 3x12

        ---
        name: Pull Day A
        rest: 120

        - Deadlift: 4x6
        - Barbell Rows: 4x10
        - Lat Pulldowns: 3x12
        - Face Pulls: 3x15
        - Barbell Curls: 3x12

        ---
        name: Legs + Core
        rest: 120

        - Squats: 4x8
        - Romanian Deadlift: 3x10
        - Leg Press: 3x12
        - Calf Raises: 4x15
        - Plank: 3x60s
        """
        let plans = try WorkoutPlanParser.parse(input)
        #expect(plans.count == 3)
        #expect(plans[0].exercises.count == 5)
        #expect(plans[1].exercises.count == 5)
        #expect(plans[2].exercises.count == 5)
        #expect(plans[2].exercises[4].isIsometric)
        #expect(plans[2].exercises[4].seconds == 60)
        #expect(plans[0].rest == 90)
        #expect(plans[1].rest == 120)
    }
}
