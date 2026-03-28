import Testing
import Foundation
import SwiftData
@testable import OneTrack

@Suite("Body Measurement Chart")
@MainActor
struct BodyMeasurementChartTests {

    @Test func chartData_extractsAllTypes() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let m = BodyMeasurement(date: .now)
        m.waistCm = 80
        m.chestCm = 95
        m.leftBicepCm = 32
        m.rightBicepCm = 33
        context.insert(m)
        try context.save()

        let data = BodyCalculations.measurementChartData(measurements: [m])
        #expect(data.count == 4)
        #expect(data.contains(where: { $0.type == "Waist" && $0.value == 80 }))
        #expect(data.contains(where: { $0.type == "Chest" && $0.value == 95 }))
        #expect(data.contains(where: { $0.type == "L. Bicep" && $0.value == 32 }))
        #expect(data.contains(where: { $0.type == "R. Bicep" && $0.value == 33 }))
    }

    @Test func chartData_handlesPartialMeasurements() throws {
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

    @Test func chartData_emptyMeasurements() {
        let data = BodyCalculations.measurementChartData(measurements: [])
        #expect(data.isEmpty)
    }

    @Test func chartData_respectsLimit() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        var measurements: [BodyMeasurement] = []
        for i in 0..<25 {
            let m = BodyMeasurement(date: Calendar.current.date(byAdding: .day, value: -i, to: .now)!)
            m.waistCm = Double(80 + i)
            context.insert(m)
            measurements.append(m)
        }
        try context.save()

        let data = BodyCalculations.measurementChartData(measurements: measurements, limit: 20)
        // Only waist type, so max 20 data points
        #expect(data.count == 20)
    }

    @Test func chartData_sortedByDate() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let older = BodyMeasurement(date: Calendar.current.date(byAdding: .day, value: -5, to: .now)!)
        older.waistCm = 82
        context.insert(older)

        let newer = BodyMeasurement(date: .now)
        newer.waistCm = 80
        context.insert(newer)
        try context.save()

        let data = BodyCalculations.measurementChartData(measurements: [older, newer])
        let waistPoints = data.filter { $0.type == "Waist" }
        #expect(waistPoints.count == 2)
        #expect(waistPoints[0].date < waistPoints[1].date)
    }

    // MARK: - Latest Measurement Values

    @Test func latestMeasurementValues_findsMostRecent() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let older = BodyMeasurement(date: Calendar.current.date(byAdding: .day, value: -5, to: .now)!)
        older.waistCm = 82
        older.chestCm = 90
        context.insert(older)

        let newer = BodyMeasurement(date: .now)
        newer.waistCm = 80
        // No chest this time
        context.insert(newer)
        try context.save()

        let latest = BodyCalculations.latestMeasurementValues(measurements: [older, newer])
        #expect(latest.waist == 80)     // from newer
        #expect(latest.chest == 90)     // from older (newest with chest)
        #expect(latest.leftBicep == nil)
    }

    @Test func latestMeasurementValues_empty() {
        let latest = BodyCalculations.latestMeasurementValues(measurements: [])
        #expect(latest.waist == nil)
        #expect(latest.chest == nil)
        #expect(latest.leftBicep == nil)
        #expect(latest.rightBicep == nil)
    }
}
