import Testing
import Foundation
@testable import OneTrack

@Suite("Activity Streak")
struct ActivityStreakTests {
    private let calendar = Calendar.current
    private let today = Calendar.current.startOfDay(for: .now)

    private func daysAgo(_ n: Int, steps: Int) -> (date: Date, steps: Int) {
        (date: calendar.date(byAdding: .day, value: -n, to: today)!, steps: steps)
    }

    @Test func streak_emptyData() {
        #expect(ActivityCalculations.streakDays(dailySteps: [], goal: 10000) == 0)
    }

    @Test func streak_zeroGoal() {
        let data = [daysAgo(0, steps: 5000)]
        #expect(ActivityCalculations.streakDays(dailySteps: data, goal: 0) == 0)
    }

    @Test func streak_todayMeetsGoal() {
        let data = [
            daysAgo(0, steps: 12000),
            daysAgo(1, steps: 11000),
            daysAgo(2, steps: 10500),
        ]
        #expect(ActivityCalculations.streakDays(dailySteps: data, goal: 10000) == 3)
    }

    @Test func streak_todayNotMet_startsFromYesterday() {
        let data = [
            daysAgo(0, steps: 3000),  // not met
            daysAgo(1, steps: 12000),
            daysAgo(2, steps: 11000),
        ]
        #expect(ActivityCalculations.streakDays(dailySteps: data, goal: 10000) == 2)
    }

    @Test func streak_brokenByGap() {
        let data = [
            daysAgo(0, steps: 12000),
            daysAgo(1, steps: 5000),  // broke streak
            daysAgo(2, steps: 12000),
        ]
        #expect(ActivityCalculations.streakDays(dailySteps: data, goal: 10000) == 1)
    }

    @Test func streak_noGoalMet() {
        let data = [
            daysAgo(0, steps: 3000),
            daysAgo(1, steps: 2000),
        ]
        #expect(ActivityCalculations.streakDays(dailySteps: data, goal: 10000) == 0)
    }

    @Test func goalProgress_half() {
        #expect(ActivityCalculations.goalProgress(current: 5000, goal: 10000) == 0.5)
    }

    @Test func goalProgress_over() {
        #expect(ActivityCalculations.goalProgress(current: 15000, goal: 10000) == 1.0)
    }

    @Test func goalProgress_zeroGoal() {
        #expect(ActivityCalculations.goalProgress(current: 5000, goal: 0) == 0)
    }
}
