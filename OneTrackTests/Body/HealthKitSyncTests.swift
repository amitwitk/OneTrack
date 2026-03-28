import Testing
import Foundation
@testable import OneTrack

@Suite("HealthKit Sync Logic")
struct HealthKitSyncTests {

    // MARK: - Deduplication

    @Test func samplesToImportFiltersExistingEntries() {
        let date = Date.now
        let existing = [
            WeightEntry(date: date, weightKg: 80.0, source: "healthkit")
        ]
        let samples = [
            WeightSample(date: date, weightKg: 80.0, source: "healthkit"),
            WeightSample(date: date.addingTimeInterval(3600), weightKg: 81.0, source: "healthkit")
        ]

        let result = BodyCalculations.samplesToImport(samples: samples, existingEntries: existing)

        #expect(result.count == 1)
        #expect(result.first?.weightKg == 81.0)
    }

    @Test func samplesToImportAllowsSameWeightDifferentDate() {
        let date1 = Date.now
        let date2 = date1.addingTimeInterval(86400) // next day
        let existing = [
            WeightEntry(date: date1, weightKg: 80.0, source: "healthkit")
        ]
        let samples = [
            WeightSample(date: date2, weightKg: 80.0, source: "healthkit")
        ]

        let result = BodyCalculations.samplesToImport(samples: samples, existingEntries: existing)

        #expect(result.count == 1)
    }

    @Test func samplesToImportDeduplicatesWithinDateTolerance() {
        let date = Date.now
        let existing = [
            WeightEntry(date: date, weightKg: 80.0, source: "manual")
        ]
        // Sample is 30 seconds off — within default 60s tolerance
        let samples = [
            WeightSample(date: date.addingTimeInterval(30), weightKg: 80.0, source: "healthkit")
        ]

        let result = BodyCalculations.samplesToImport(samples: samples, existingEntries: existing)

        #expect(result.isEmpty)
    }

    @Test func samplesToImportDoesNotDeduplicateOutsideTolerance() {
        let date = Date.now
        let existing = [
            WeightEntry(date: date, weightKg: 80.0, source: "manual")
        ]
        // Sample is 120 seconds off — outside default 60s tolerance
        let samples = [
            WeightSample(date: date.addingTimeInterval(120), weightKg: 80.0, source: "healthkit")
        ]

        let result = BodyCalculations.samplesToImport(samples: samples, existingEntries: existing)

        #expect(result.count == 1)
    }

    @Test func samplesToImportSkipsOneTrackSource() {
        let samples = [
            WeightSample(date: .now, weightKg: 80.0, source: "onetrack"),
            WeightSample(date: .now.addingTimeInterval(100), weightKg: 81.0, source: "healthkit")
        ]

        let result = BodyCalculations.samplesToImport(samples: samples, existingEntries: [])

        #expect(result.count == 1)
        #expect(result.first?.source == "healthkit")
    }

    @Test func samplesToImportEmptySamples() {
        let result = BodyCalculations.samplesToImport(samples: [], existingEntries: [])
        #expect(result.isEmpty)
    }

    @Test func samplesToImportNoExistingEntries() {
        let samples = [
            WeightSample(date: .now, weightKg: 80.0, source: "healthkit"),
            WeightSample(date: .now.addingTimeInterval(3600), weightKg: 81.0, source: "healthkit")
        ]

        let result = BodyCalculations.samplesToImport(samples: samples, existingEntries: [])

        #expect(result.count == 2)
    }

    @Test func samplesToImportWithCustomTolerance() {
        let date = Date.now
        let existing = [
            WeightEntry(date: date, weightKg: 80.0, source: "healthkit")
        ]
        let samples = [
            WeightSample(date: date.addingTimeInterval(90), weightKg: 80.0, source: "healthkit")
        ]

        // With 120s tolerance, this should be filtered out
        let result120 = BodyCalculations.samplesToImport(
            samples: samples, existingEntries: existing, dateTolerance: 120
        )
        #expect(result120.isEmpty)

        // With 60s tolerance (default), this should pass through
        let result60 = BodyCalculations.samplesToImport(
            samples: samples, existingEntries: existing, dateTolerance: 60
        )
        #expect(result60.count == 1)
    }

    // MARK: - Conversion

    @Test func weightEntryValuesFromSample() {
        let date = Date.now
        let sample = WeightSample(date: date, weightKg: 82.5, source: "healthkit")
        let values = BodyCalculations.weightEntryValues(from: sample)

        #expect(values.date == date)
        #expect(values.weightKg == 82.5)
        #expect(values.source == "healthkit")
    }

    @Test func weightEntryValuesAlwaysMarksAsHealthKit() {
        // Even if the sample source was something else, conversion marks it as healthkit
        let sample = WeightSample(date: .now, weightKg: 75.0, source: "some-other-app")
        let values = BodyCalculations.weightEntryValues(from: sample)

        #expect(values.source == "healthkit")
    }

    // MARK: - WeightSample

    @Test func weightSampleEquality() {
        let date = Date.now
        let a = WeightSample(date: date, weightKg: 80.0, source: "healthkit")
        let b = WeightSample(date: date, weightKg: 80.0, source: "healthkit")
        #expect(a == b)
    }

    @Test func weightSampleInequality() {
        let date = Date.now
        let a = WeightSample(date: date, weightKg: 80.0, source: "healthkit")
        let b = WeightSample(date: date, weightKg: 81.0, source: "healthkit")
        #expect(a != b)
    }
}
