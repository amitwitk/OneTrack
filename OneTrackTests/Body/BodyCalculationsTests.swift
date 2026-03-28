import Testing
import Foundation
import SwiftData
@testable import OneTrack

@Suite("Body Calculations")
struct BodyCalculationsTests {

    @Test func currentWeightReturnsLatest() {
        let older = WeightEntry(date: Date.now.addingTimeInterval(-86400), weightKg: 78.0)
        let newer = WeightEntry(date: Date.now, weightKg: 80.0)
        let result = BodyCalculations.currentWeight(entries: [older, newer])
        #expect(result == 80.0)
    }

    @Test func currentWeightEmptyReturnsNil() {
        let result = BodyCalculations.currentWeight(entries: [])
        #expect(result == nil)
    }

    @Test func weeklyChangePositive() {
        let now = Date.now
        let eightDaysAgo = Calendar.current.date(byAdding: .day, value: -8, to: now)!
        let older = WeightEntry(date: eightDaysAgo, weightKg: 78.0)
        let newer = WeightEntry(date: now, weightKg: 79.5)
        let result = BodyCalculations.weeklyChange(entries: [older, newer], now: now)
        #expect(result == 1.5)
    }

    @Test func weeklyChangeNegative() {
        let now = Date.now
        let eightDaysAgo = Calendar.current.date(byAdding: .day, value: -8, to: now)!
        let older = WeightEntry(date: eightDaysAgo, weightKg: 80.0)
        let newer = WeightEntry(date: now, weightKg: 79.0)
        let result = BodyCalculations.weeklyChange(entries: [older, newer], now: now)
        #expect(result == -1.0)
    }

    @Test func weeklyChangeNoPriorData() {
        let now = Date.now
        let recent = WeightEntry(date: now, weightKg: 80.0)
        let result = BodyCalculations.weeklyChange(entries: [recent], now: now)
        #expect(result == nil)
    }

    @Test func weeklyChangeEmpty() {
        let result = BodyCalculations.weeklyChange(entries: [])
        #expect(result == nil)
    }

    @Test func latestWaist() {
        let m1 = BodyMeasurement(date: Date.now.addingTimeInterval(-86400))
        m1.waistCm = 82.0
        let m2 = BodyMeasurement(date: Date.now)
        m2.waistCm = 81.0
        let result = BodyCalculations.latestWaist(measurements: [m1, m2])
        #expect(result == 81.0)
    }

    @Test func latestWaistSkipsNil() {
        let m1 = BodyMeasurement(date: Date.now.addingTimeInterval(-86400))
        m1.waistCm = 82.0
        let m2 = BodyMeasurement(date: Date.now)
        // m2 has no waist
        let result = BodyCalculations.latestWaist(measurements: [m1, m2])
        #expect(result == 82.0)
    }

    @Test func latestWaistEmpty() {
        let result = BodyCalculations.latestWaist(measurements: [])
        #expect(result == nil)
    }

    @Test func entriesThisMonth() {
        let now = Date.now
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let thisMonth = WeightEntry(date: startOfMonth.addingTimeInterval(3600), weightKg: 80)
        let lastMonth = WeightEntry(date: calendar.date(byAdding: .month, value: -1, to: now)!, weightKg: 79)
        let result = BodyCalculations.entriesThisMonth(entries: [thisMonth, lastMonth], now: now)
        #expect(result == 1)
    }

    @Test func filteredEntriesByDays() {
        let now = Date.now
        let recent = WeightEntry(date: now.addingTimeInterval(-86400), weightKg: 80)
        let old = WeightEntry(date: now.addingTimeInterval(-86400 * 10), weightKg: 78)
        let result = BodyCalculations.filteredEntries(entries: [recent, old], days: 7, now: now)
        #expect(result.count == 1)
        #expect(result.first?.weightKg == 80)
    }

    @Test func filteredEntriesSortedByDate() {
        let now = Date.now
        let e1 = WeightEntry(date: now.addingTimeInterval(-86400 * 2), weightKg: 79)
        let e2 = WeightEntry(date: now.addingTimeInterval(-86400), weightKg: 80)
        let result = BodyCalculations.filteredEntries(entries: [e2, e1], days: 7, now: now)
        #expect(result.first?.weightKg == 79)
        #expect(result.last?.weightKg == 80)
    }

    @Test func weeklyChangeFormatted() {
        #expect(BodyCalculations.weeklyChangeFormatted(1.5) == "+1.5 kg")
        #expect(BodyCalculations.weeklyChangeFormatted(-0.5) == "-0.5 kg")
        #expect(BodyCalculations.weeklyChangeFormatted(0.0) == "+0.0 kg")
        #expect(BodyCalculations.weeklyChangeFormatted(nil) == "--")
    }

    @Test func weeklyChangeColorValues() {
        #expect(BodyCalculations.weeklyChangeColor(-1.0) == "green")
        #expect(BodyCalculations.weeklyChangeColor(1.0) == "red")
        #expect(BodyCalculations.weeklyChangeColor(0.0) == "gray")
        #expect(BodyCalculations.weeklyChangeColor(nil) == "gray")
    }

    @Test func weightEntrySourceTracking() {
        let manual = WeightEntry(weightKg: 80)
        #expect(manual.source == "manual")

        let healthkit = WeightEntry(weightKg: 80, source: "healthkit")
        #expect(healthkit.source == "healthkit")
    }

    @Test func bodyMeasurementOptionalFieldsSave() {
        let m = BodyMeasurement(date: .now)
        m.waistCm = 82.0
        // other fields stay nil
        #expect(m.waistCm == 82.0)
        #expect(m.chestCm == nil)
        #expect(m.leftBicepCm == nil)
        #expect(m.rightBicepCm == nil)
    }
}
