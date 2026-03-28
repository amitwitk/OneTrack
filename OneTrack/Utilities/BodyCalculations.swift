import Foundation

/// Lightweight transfer object for weight data from HealthKit.
/// Keeps HealthKit types out of the model layer.
struct WeightSample: Equatable, Sendable {
    let date: Date
    let weightKg: Double
    let source: String // "healthkit" or "onetrack"
}

struct BodyCalculations {

    // MARK: - HealthKit Sync Helpers

    /// Determines which HealthKit samples are new and should be imported.
    /// Deduplicates by checking if a WeightEntry with the same date (within tolerance) and weight already exists.
    static func samplesToImport(
        samples: [WeightSample],
        existingEntries: [WeightEntry],
        dateTolerance: TimeInterval = 60
    ) -> [WeightSample] {
        samples.filter { sample in
            // Skip samples that OneTrack itself wrote
            guard sample.source != "onetrack" else { return false }

            // Check for existing entry with same date (within tolerance) and weight
            let isDuplicate = existingEntries.contains { entry in
                abs(entry.date.timeIntervalSince(sample.date)) < dateTolerance
                    && abs(entry.weightKg - sample.weightKg) < 0.01
            }
            return !isDuplicate
        }
    }

    /// Converts a WeightSample to WeightEntry values (does not create the model object).
    static func weightEntryValues(from sample: WeightSample) -> (date: Date, weightKg: Double, source: String) {
        (date: sample.date, weightKg: sample.weightKg, source: "healthkit")
    }
    static func currentWeight(entries: [WeightEntry]) -> Double? {
        entries.max(by: { $0.date < $1.date })?.weightKg
    }

    static func weeklyChange(entries: [WeightEntry], now: Date = .now) -> Double? {
        guard let latest = entries.max(by: { $0.date < $1.date }) else { return nil }
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let earlier = entries
            .filter { $0.date <= sevenDaysAgo }
            .max(by: { $0.date < $1.date })
        guard let earlier else { return nil }
        return latest.weightKg - earlier.weightKg
    }

    static func latestWaist(measurements: [BodyMeasurement]) -> Double? {
        measurements
            .filter { $0.waistCm != nil }
            .max(by: { $0.date < $1.date })?
            .waistCm
    }

    static func entriesThisMonth(entries: [WeightEntry], now: Date = .now) -> Int {
        let calendar = Calendar.current
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        return entries.filter { $0.date >= startOfMonth }.count
    }

    static func filteredEntries(entries: [WeightEntry], days: Int, now: Date = .now) -> [WeightEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
        return entries.filter { $0.date >= cutoff }.sorted { $0.date < $1.date }
    }

    static func weeklyChangeFormatted(_ change: Double?) -> String {
        guard let change else { return "--" }
        let sign = change >= 0 ? "+" : ""
        return String(format: "%@%.1f kg", sign, change)
    }

    static func weeklyChangeColor(_ change: Double?) -> String {
        guard let change else { return "gray" }
        if change < 0 { return "green" }
        if change > 0 { return "red" }
        return "gray"
    }
}
