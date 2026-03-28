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

    // MARK: - Measurement Chart Data

    struct MeasurementChartPoint: Identifiable {
        let id = UUID()
        let date: Date
        let value: Double
        let type: String
    }

    /// Extracts chart data from body measurements. Returns data points for each non-nil measurement type.
    static func measurementChartData(
        measurements: [BodyMeasurement],
        limit: Int = 20
    ) -> [MeasurementChartPoint] {
        let sorted = measurements
            .sorted { $0.date < $1.date }
            .suffix(limit)

        var points: [MeasurementChartPoint] = []
        for m in sorted {
            if let v = m.waistCm { points.append(MeasurementChartPoint(date: m.date, value: v, type: "Waist")) }
            if let v = m.chestCm { points.append(MeasurementChartPoint(date: m.date, value: v, type: "Chest")) }
            if let v = m.leftBicepCm { points.append(MeasurementChartPoint(date: m.date, value: v, type: "L. Bicep")) }
            if let v = m.rightBicepCm { points.append(MeasurementChartPoint(date: m.date, value: v, type: "R. Bicep")) }
        }
        return points
    }

    // MARK: - BMI

    /// Calculates BMI: weight(kg) / (height(m))²
    static func bmi(weightKg: Double, heightCm: Double) -> Double {
        guard heightCm > 0 else { return 0 }
        let heightM = heightCm / 100.0
        return weightKg / (heightM * heightM)
    }

    static func bmiCategory(bmi: Double) -> String {
        switch bmi {
        case ..<18.5: "Underweight"
        case 18.5..<25: "Normal"
        case 25..<30: "Overweight"
        default: "Obese"
        }
    }

    static func bmiCategoryColor(bmi: Double) -> String {
        switch bmi {
        case ..<18.5: "blue"
        case 18.5..<25: "green"
        case 25..<30: "yellow"
        default: "red"
        }
    }

    // MARK: - Rate of Change

    /// Calculates weekly rate of weight change in kg/week.
    /// Requires at least 2 entries spanning 3+ days. Returns nil otherwise.
    static func weeklyRateOfChange(entries: [WeightEntry], now: Date = .now) -> Double? {
        guard let latest = entries.max(by: { $0.date < $1.date }) else { return nil }

        // Find earliest entry that's at least 3 days before latest
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: latest.date) ?? latest.date
        let earlier = entries
            .filter { $0.date <= threeDaysAgo }
            .max(by: { $0.date < $1.date })
        guard let earlier else { return nil }

        let daysDiff = latest.date.timeIntervalSince(earlier.date) / 86400
        guard daysDiff >= 3 else { return nil }

        let weightDiff = latest.weightKg - earlier.weightKg
        return (weightDiff / daysDiff) * 7 // Convert to per-week
    }

    static func weeklyRateArrow(_ rate: Double) -> String {
        if abs(rate) < 0.1 { return "→" }
        return rate > 0 ? "↑" : "↓"
    }

    static func weeklyRateFormatted(_ rate: Double?) -> String {
        guard let rate else { return "--" }
        let sign = rate >= 0 ? "+" : ""
        return String(format: "%@%.1f kg/wk", sign, rate)
    }

    // MARK: - Weight Goal

    /// Progress toward a weight goal (0.0 to 1.0).
    /// Works for both loss (target < start) and gain (target > start).
    static func goalProgress(current: Double, start: Double, target: Double) -> Double {
        let totalChange = abs(target - start)
        guard totalChange > 0 else { return 1.0 }
        let actualChange = abs(current - start)
        // Check direction: are we moving toward or away from goal?
        let isCorrectDirection: Bool
        if target < start { // losing
            isCorrectDirection = current <= start
        } else { // gaining
            isCorrectDirection = current >= start
        }
        guard isCorrectDirection else { return 0 }
        return min(actualChange / totalChange, 1.0)
    }

    /// Estimated date to reach goal based on weekly rate of change.
    /// Returns nil if rate is zero, wrong direction, or already past goal.
    static func estimatedGoalDate(current: Double, target: Double, weeklyRate: Double, now: Date = .now) -> Date? {
        let remaining = target - current
        // Check if already at or past goal
        if abs(remaining) < 0.1 { return now }
        // Rate must be moving toward the goal
        guard weeklyRate != 0 else { return nil }
        let weeksNeeded = remaining / weeklyRate
        guard weeksNeeded > 0 else { return nil } // wrong direction
        let daysNeeded = Int(weeksNeeded * 7)
        return Calendar.current.date(byAdding: .day, value: daysNeeded, to: now)
    }

    /// Returns the latest values for each measurement type, used for smart defaults.
    static func latestMeasurementValues(measurements: [BodyMeasurement]) -> (waist: Double?, chest: Double?, leftBicep: Double?, rightBicep: Double?) {
        let sorted = measurements.sorted { $0.date > $1.date }
        let waist = sorted.first(where: { $0.waistCm != nil })?.waistCm
        let chest = sorted.first(where: { $0.chestCm != nil })?.chestCm
        let leftBicep = sorted.first(where: { $0.leftBicepCm != nil })?.leftBicepCm
        let rightBicep = sorted.first(where: { $0.rightBicepCm != nil })?.rightBicepCm
        return (waist, chest, leftBicep, rightBicep)
    }
}
