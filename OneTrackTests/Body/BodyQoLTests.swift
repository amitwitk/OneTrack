import Testing
import Foundation
import SwiftData
@testable import OneTrack

@Suite("Body QoL")
@MainActor
struct BodyQoLTests {

    // MARK: - BMI Calculation

    @Test func bmi_normalWeight() {
        let bmi = BodyCalculations.bmi(weightKg: 70, heightCm: 175)
        #expect(abs(bmi - 22.86) < 0.1)
    }

    @Test func bmi_underweight() {
        let bmi = BodyCalculations.bmi(weightKg: 50, heightCm: 175)
        #expect(bmi < 18.5)
    }

    @Test func bmi_overweight() {
        let bmi = BodyCalculations.bmi(weightKg: 85, heightCm: 175)
        let cat = BodyCalculations.bmiCategory(bmi: bmi)
        #expect(cat == "Overweight")
    }

    @Test func bmi_obese() {
        let bmi = BodyCalculations.bmi(weightKg: 110, heightCm: 175)
        let cat = BodyCalculations.bmiCategory(bmi: bmi)
        #expect(cat == "Obese")
    }

    @Test func bmi_zeroHeight() {
        let bmi = BodyCalculations.bmi(weightKg: 70, heightCm: 0)
        #expect(bmi == 0)
    }

    @Test func bmiCategory_allRanges() {
        #expect(BodyCalculations.bmiCategory(bmi: 16) == "Underweight")
        #expect(BodyCalculations.bmiCategory(bmi: 22) == "Normal")
        #expect(BodyCalculations.bmiCategory(bmi: 27) == "Overweight")
        #expect(BodyCalculations.bmiCategory(bmi: 35) == "Obese")
    }

    // MARK: - Rate of Change

    @Test func weeklyRate_withEnoughData() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let now = Date.now
        let e1 = WeightEntry(date: Calendar.current.date(byAdding: .day, value: -7, to: now)!, weightKg: 80)
        let e2 = WeightEntry(date: now, weightKg: 79)
        context.insert(e1)
        context.insert(e2)
        try context.save()

        let rate = BodyCalculations.weeklyRateOfChange(entries: [e1, e2], now: now)
        #expect(rate != nil)
        #expect(abs(rate! - (-1.0)) < 0.1) // Lost 1kg in 7 days = -1 kg/week
    }

    @Test func weeklyRate_notEnoughData() {
        let rate = BodyCalculations.weeklyRateOfChange(entries: [])
        #expect(rate == nil)
    }

    @Test func weeklyRate_entriesTooClose() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let now = Date.now
        let e1 = WeightEntry(date: Calendar.current.date(byAdding: .day, value: -1, to: now)!, weightKg: 80)
        let e2 = WeightEntry(date: now, weightKg: 79)
        context.insert(e1)
        context.insert(e2)
        try context.save()

        let rate = BodyCalculations.weeklyRateOfChange(entries: [e1, e2], now: now)
        #expect(rate == nil) // Less than 3 days apart
    }

    @Test func weeklyRate_stable() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let now = Date.now
        let e1 = WeightEntry(date: Calendar.current.date(byAdding: .day, value: -7, to: now)!, weightKg: 80)
        let e2 = WeightEntry(date: now, weightKg: 80)
        context.insert(e1)
        context.insert(e2)
        try context.save()

        let rate = BodyCalculations.weeklyRateOfChange(entries: [e1, e2], now: now)
        #expect(rate != nil)
        #expect(abs(rate!) < 0.1) // Stable
    }

    @Test func weeklyRateArrow_gaining() {
        #expect(BodyCalculations.weeklyRateArrow(0.5) == "↑")
    }

    @Test func weeklyRateArrow_losing() {
        #expect(BodyCalculations.weeklyRateArrow(-0.5) == "↓")
    }

    @Test func weeklyRateArrow_stable() {
        #expect(BodyCalculations.weeklyRateArrow(0.05) == "→")
    }

    // MARK: - Measurement Trends

    @Test func measurementTrends_extractsAllTypes() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let m = BodyMeasurement(date: .now)
        m.waistCm = 80
        m.chestCm = 95
        context.insert(m)
        try context.save()

        let data = BodyCalculations.measurementChartData(measurements: [m])
        #expect(data.count == 2)
        #expect(data.contains(where: { $0.type == "Waist" }))
        #expect(data.contains(where: { $0.type == "Chest" }))
    }

    @Test func measurementTrends_skipsNilValues() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let m = BodyMeasurement(date: .now)
        m.waistCm = 80
        // chest, biceps are nil
        context.insert(m)
        try context.save()

        let data = BodyCalculations.measurementChartData(measurements: [m])
        #expect(data.count == 1)
        #expect(data[0].type == "Waist")
    }
}
