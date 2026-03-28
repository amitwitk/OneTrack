import Testing
import Foundation
@testable import OneTrack

@Suite("Weight Goal Calculations")
struct WeightGoalTests {

    // MARK: - Goal Progress

    @Test func goalProgress_losing_halfwayThere() {
        // Start: 80, Target: 70, Current: 75 → 50%
        let result = BodyCalculations.goalProgress(current: 75, start: 80, target: 70)
        #expect(abs(result - 0.5) < 0.01)
    }

    @Test func goalProgress_gaining_halfwayThere() {
        // Start: 60, Target: 70, Current: 65 → 50%
        let result = BodyCalculations.goalProgress(current: 65, start: 60, target: 70)
        #expect(abs(result - 0.5) < 0.01)
    }

    @Test func goalProgress_pastGoal() {
        // Start: 80, Target: 70, Current: 68 → capped at 1.0
        let result = BodyCalculations.goalProgress(current: 68, start: 80, target: 70)
        #expect(result == 1.0)
    }

    @Test func goalProgress_wrongDirection() {
        // Start: 80, Target: 70, Current: 82 → gaining instead of losing = 0
        let result = BodyCalculations.goalProgress(current: 82, start: 80, target: 70)
        #expect(result == 0)
    }

    @Test func goalProgress_startEqualsTarget() {
        let result = BodyCalculations.goalProgress(current: 80, start: 80, target: 80)
        #expect(result == 1.0) // already at goal
    }

    @Test func goalProgress_noProgress() {
        let result = BodyCalculations.goalProgress(current: 80, start: 80, target: 70)
        #expect(result == 0)
    }

    // MARK: - Estimated Goal Date

    @Test func estimatedDate_losingWeight() {
        // Current: 75, Target: 70, Rate: -0.5 kg/week → 10 weeks = 70 days
        let now = Date.now
        let result = BodyCalculations.estimatedGoalDate(current: 75, target: 70, weeklyRate: -0.5, now: now)
        #expect(result != nil)
        let days = Calendar.current.dateComponents([.day], from: now, to: result!).day ?? 0
        #expect(days == 70)
    }

    @Test func estimatedDate_gainingWeight() {
        // Current: 65, Target: 70, Rate: +0.5 kg/week → 10 weeks = 70 days
        let now = Date.now
        let result = BodyCalculations.estimatedGoalDate(current: 65, target: 70, weeklyRate: 0.5, now: now)
        #expect(result != nil)
        let days = Calendar.current.dateComponents([.day], from: now, to: result!).day ?? 0
        #expect(days == 70)
    }

    @Test func estimatedDate_zeroRate() {
        let result = BodyCalculations.estimatedGoalDate(current: 75, target: 70, weeklyRate: 0)
        #expect(result == nil)
    }

    @Test func estimatedDate_wrongDirection() {
        // Gaining when should be losing
        let result = BodyCalculations.estimatedGoalDate(current: 75, target: 70, weeklyRate: 0.5)
        #expect(result == nil)
    }

    @Test func estimatedDate_alreadyAtGoal() {
        let now = Date.now
        let result = BodyCalculations.estimatedGoalDate(current: 70, target: 70, weeklyRate: -0.5, now: now)
        #expect(result != nil)
    }
}
