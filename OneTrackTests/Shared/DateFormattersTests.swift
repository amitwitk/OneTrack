import Testing
import Foundation
@testable import OneTrack

@Suite("Date Formatters")
struct DateFormattersTests {

    @Test func durationString_minutesAndSeconds() {
        #expect(90.durationString == "1m 30s")
    }

    @Test func durationString_secondsOnly() {
        #expect(45.durationString == "45s")
    }

    @Test func durationString_zero() {
        #expect(0.durationString == "0s")
    }

    @Test func durationString_exactMinute() {
        #expect(120.durationString == "2m 0s")
    }

    @Test func relativeDay_today() {
        #expect(Date.now.relativeDay == "Today")
    }

    @Test func relativeDay_yesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now)!
        #expect(yesterday.relativeDay == "Yesterday")
    }

    @Test func relativeDay_olderDate() {
        let oldDate = Calendar.current.date(byAdding: .day, value: -5, to: .now)!
        let result = oldDate.relativeDay
        #expect(result != "Today")
        #expect(result != "Yesterday")
    }
}
