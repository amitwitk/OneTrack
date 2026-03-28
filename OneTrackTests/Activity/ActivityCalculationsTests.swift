import Testing
import Foundation
@testable import OneTrack

@Suite("Activity Calculations")
struct ActivityCalculationsTests {

    @Test func formattedSteps_zero() {
        #expect(ActivityCalculations.formattedSteps(0) == "0")
    }

    @Test func formattedSteps_hundreds() {
        #expect(ActivityCalculations.formattedSteps(500) == "500")
    }

    @Test func formattedSteps_thousands() {
        let result = ActivityCalculations.formattedSteps(8_432)
        #expect(result == "8,432")
    }

    @Test func formattedSteps_tenThousands() {
        let result = ActivityCalculations.formattedSteps(12_345)
        #expect(result == "12,345")
    }

    @Test func formattedCalories_zero() {
        #expect(ActivityCalculations.formattedCalories(0) == "0")
    }

    @Test func formattedCalories_truncatesDecimals() {
        #expect(ActivityCalculations.formattedCalories(523.7) == "523")
    }

    @Test func dailyActivity_mergesArrays() {
        let now = Date.now
        let steps = [(date: now, steps: 1000)]
        let cals = [(date: now, calories: 250.0)]
        let result = ActivityCalculations.dailyActivity(dailySteps: steps, dailyCalories: cals)
        #expect(result.count == 1)
        #expect(result[0].steps == 1000)
        #expect(result[0].calories == 250.0)
    }

    @Test func dailyActivity_emptyInput() {
        let result = ActivityCalculations.dailyActivity(
            dailySteps: [],
            dailyCalories: []
        )
        #expect(result.isEmpty)
    }

    @Test func dailyActivity_multipleEntries() {
        let d1 = Date.now
        let d2 = Calendar.current.date(byAdding: .day, value: -1, to: d1)!
        let steps = [(date: d1, steps: 5000), (date: d2, steps: 8000)]
        let cals = [(date: d1, calories: 300.0), (date: d2, calories: 500.0)]
        let result = ActivityCalculations.dailyActivity(dailySteps: steps, dailyCalories: cals)
        #expect(result.count == 2)
        #expect(result[0].steps == 5000)
        #expect(result[1].steps == 8000)
    }
}
