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
            .filter(\.isCompleted)
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
}
