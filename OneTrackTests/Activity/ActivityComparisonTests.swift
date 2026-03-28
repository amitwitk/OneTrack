import Testing
import Foundation
@testable import OneTrack

@Suite("Activity Week Comparison")
struct ActivityComparisonTests {

    @Test func weekOverWeek_increase() {
        let result = ActivityCalculations.weekOverWeekChange(thisWeek: 70000, lastWeek: 50000)
        #expect(result.direction == "up")
        #expect(abs(result.percentage - 40) < 0.1)
    }

    @Test func weekOverWeek_decrease() {
        let result = ActivityCalculations.weekOverWeekChange(thisWeek: 40000, lastWeek: 50000)
        #expect(result.direction == "down")
        #expect(abs(result.percentage - (-20)) < 0.1)
    }

    @Test func weekOverWeek_same() {
        let result = ActivityCalculations.weekOverWeekChange(thisWeek: 50000, lastWeek: 50000)
        #expect(result.direction == "same")
    }

    @Test func weekOverWeek_lastWeekZero_thisWeekPositive() {
        let result = ActivityCalculations.weekOverWeekChange(thisWeek: 10000, lastWeek: 0)
        #expect(result.direction == "up")
    }

    @Test func weekOverWeek_bothZero() {
        let result = ActivityCalculations.weekOverWeekChange(thisWeek: 0, lastWeek: 0)
        #expect(result.direction == "same")
    }

    @Test func splitWeeks_14days() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var data: [(date: Date, value: Int)] = []
        for i in (0..<14).reversed() {
            data.append((date: calendar.date(byAdding: .day, value: -i, to: today)!, value: i < 7 ? 10000 : 5000))
        }
        let (thisWeek, lastWeek) = ActivityCalculations.splitWeeks(data: data)
        #expect(thisWeek == 7 * 10000)
        #expect(lastWeek == 7 * 5000)
    }

    @Test func splitWeeks_lessThan14days() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        var data: [(date: Date, value: Int)] = []
        for i in (0..<5).reversed() {
            data.append((date: calendar.date(byAdding: .day, value: -i, to: today)!, value: 8000))
        }
        let (thisWeek, lastWeek) = ActivityCalculations.splitWeeks(data: data)
        #expect(thisWeek == 5 * 8000)
        #expect(lastWeek == 0)
    }
}
