import Foundation

struct DashboardCalculations {
    static func thisWeekCount(sessions: [WorkoutSession], now: Date = .now) -> Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        return sessions.filter { $0.date >= weekAgo }.count
    }

    static func totalVolume(sessions: [WorkoutSession], now: Date = .now) -> String {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        let volume = sessions
            .filter { $0.date >= weekAgo }
            .flatMap(\.exerciseLogs)
            .flatMap(\.sets)
            .filter { $0.isCompleted && !$0.isWarmUp }
            .reduce(0.0) { $0 + Double($1.reps) * $1.weightKg }
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return "\(Int(volume))"
    }

    static func streakDays(sessions: [WorkoutSession], now: Date = .now) -> Int {
        guard !sessions.isEmpty else { return 0 }
        var streak = 0
        var checkDate = Calendar.current.startOfDay(for: now)
        let calendar = Calendar.current
        while true {
            let hasWorkout = sessions.contains { calendar.isDate($0.date, inSameDayAs: checkDate) }
            if hasWorkout {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        return streak
    }

    static func greeting(for date: Date = .now) -> String {
        let hour = Calendar.current.component(.hour, from: date)
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    // MARK: - Chart Data

    /// Daily volume data point for bar charts.
    struct DailyVolume: Equatable, Identifiable {
        let date: Date
        let volume: Double
        var id: Date { date }
    }

    /// Weekly frequency data point for bar charts.
    struct WeeklyFrequency: Equatable, Identifiable {
        let weekStart: Date
        let count: Int
        var id: Date { weekStart }
    }

    /// Weight data point for line charts.
    struct WeightPoint: Equatable, Identifiable {
        let date: Date
        let weightKg: Double
        var id: Date { date }
    }

    /// Returns volume per day for the last 7 days (including days with zero volume).
    static func dailyVolume(sessions: [WorkoutSession], now: Date = .now) -> [DailyVolume] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        return (0..<7).reversed().map { daysAgo in
            let day = calendar.date(byAdding: .day, value: -daysAgo, to: today)!
            let volume = sessions
                .filter { calendar.isDate($0.date, inSameDayAs: day) }
                .flatMap(\.exerciseLogs)
                .flatMap(\.sets)
                .filter { $0.isCompleted && !$0.isWarmUp }
                .reduce(0.0) { $0 + Double($1.reps) * $1.weightKg }
            return DailyVolume(date: day, volume: volume)
        }
    }

    /// Returns workout count per week for the last 4 weeks.
    static func weeklyFrequency(sessions: [WorkoutSession], now: Date = .now) -> [WeeklyFrequency] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        return (0..<4).reversed().map { weeksAgo in
            let weekEnd = calendar.date(byAdding: .day, value: -(weeksAgo * 7), to: today)!
            let weekStart = calendar.date(byAdding: .day, value: -6, to: weekEnd)!
            let count = sessions.filter { $0.date >= weekStart && $0.date < calendar.date(byAdding: .day, value: 1, to: weekEnd)! }.count
            return WeeklyFrequency(weekStart: weekStart, count: count)
        }
    }

    /// Returns weight entries as chart points, sorted by date.
    static func weightTrend(entries: [WeightEntry], days: Int = 30, now: Date = .now) -> [WeightPoint] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
        return entries
            .filter { $0.date >= cutoff }
            .sorted { $0.date < $1.date }
            .map { WeightPoint(date: $0.date, weightKg: $0.weightKg) }
    }
}
