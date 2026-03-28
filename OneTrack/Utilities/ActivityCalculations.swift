import Foundation

struct ActivityCalculations {

    /// Daily activity data point for charts.
    struct DailyActivity: Equatable, Identifiable {
        let date: Date
        let steps: Int
        let calories: Double
        var id: Date { date }
    }

    /// Formats a step count with thousands separator.
    static func formattedSteps(_ steps: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }

    /// Formats calories with no decimal places.
    static func formattedCalories(_ calories: Double) -> String {
        "\(Int(calories))"
    }

    /// Merges parallel arrays of daily steps and calories into DailyActivity points.
    /// Both arrays must be the same length and aligned by index.
    static func dailyActivity(
        dailySteps: [(date: Date, steps: Int)],
        dailyCalories: [(date: Date, calories: Double)]
    ) -> [DailyActivity] {
        zip(dailySteps, dailyCalories).map { steps, cals in
            DailyActivity(date: steps.date, steps: steps.steps, calories: cals.calories)
        }
    }

    // MARK: - Streak

    /// Calculates consecutive days where steps >= goal, starting from today going backwards.
    /// If today's goal is met, today is included. Otherwise starts from yesterday.
    static func streakDays(dailySteps: [(date: Date, steps: Int)], goal: Int) -> Int {
        guard goal > 0 else { return 0 }
        let calendar = Calendar.current
        // Sort by date descending (most recent first)
        let sorted = dailySteps.sorted { $0.date > $1.date }
        guard !sorted.isEmpty else { return 0 }

        var streak = 0
        let today = calendar.startOfDay(for: .now)

        // Check each day going backwards
        for dayOffset in 0..<sorted.count {
            let expectedDate = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            // Find entry for this date
            guard let entry = sorted.first(where: { calendar.isDate($0.date, inSameDayAs: expectedDate) }) else {
                break // no data for this day = streak broken
            }
            if entry.steps >= goal {
                streak += 1
            } else {
                // If today hasn't met goal yet, skip it and start from yesterday
                if dayOffset == 0 { continue }
                break
            }
        }
        return streak
    }

    // MARK: - Week-over-Week Comparison

    struct WeekComparison: Equatable {
        let percentage: Double // positive = increase, negative = decrease
        let direction: String // "up", "down", "same"
    }

    /// Compares this week's total to last week's total.
    static func weekOverWeekChange(thisWeek: Int, lastWeek: Int) -> WeekComparison {
        guard lastWeek > 0 else {
            if thisWeek > 0 { return WeekComparison(percentage: 100, direction: "up") }
            return WeekComparison(percentage: 0, direction: "same")
        }
        let change = Double(thisWeek - lastWeek) / Double(lastWeek) * 100
        if abs(change) < 1 {
            return WeekComparison(percentage: 0, direction: "same")
        }
        return WeekComparison(
            percentage: change,
            direction: change > 0 ? "up" : "down"
        )
    }

    /// Splits daily data into this week (first 7) and last week (next 7).
    /// Expects 14 days of data sorted oldest to newest.
    static func splitWeeks(data: [(date: Date, value: Int)]) -> (thisWeek: Int, lastWeek: Int) {
        guard data.count >= 14 else {
            let total = data.suffix(7).reduce(0) { $0 + $1.value }
            return (thisWeek: total, lastWeek: 0)
        }
        let lastWeek = data.prefix(7).reduce(0) { $0 + $1.value }
        let thisWeek = data.suffix(7).reduce(0) { $0 + $1.value }
        return (thisWeek: thisWeek, lastWeek: lastWeek)
    }

    // MARK: - Goal Progress

    /// Progress fraction (0-1, capped at 1) for a goal.
    static func goalProgress(current: Int, goal: Int) -> Double {
        guard goal > 0 else { return 0 }
        return min(Double(current) / Double(goal), 1.0)
    }
}
