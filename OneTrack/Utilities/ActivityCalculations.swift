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
}
