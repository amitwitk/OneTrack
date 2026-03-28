import Foundation

struct ExerciseHistoryEntry: Identifiable {
    let id = UUID()
    let date: Date
    let maxWeight: Double
    let totalVolume: Double
    let totalSets: Int
    let bestReps: Int
}

struct ExerciseHistoryCalculations {

    /// Extracts per-session history for a specific exercise from completed sessions.
    /// Returns entries sorted by date ascending, limited to the last `limit` sessions.
    static func extractHistory(
        exerciseName: String,
        sessions: [WorkoutSession],
        limit: Int = 20
    ) -> [ExerciseHistoryEntry] {
        sessions
            .filter { $0.isCompleted }
            .sorted { $0.date < $1.date }
            .compactMap { session -> ExerciseHistoryEntry? in
                guard let log = session.exerciseLogs.first(where: { $0.exerciseName == exerciseName }) else {
                    return nil
                }
                let workingSets = log.sets.filter { $0.isCompleted && !$0.isWarmUp }
                guard !workingSets.isEmpty else { return nil }

                let maxWeight = workingSets.map(\.weightKg).max() ?? 0
                let totalVolume = workingSets.reduce(0.0) { $0 + Double($1.reps) * $1.weightKg }
                let totalSets = workingSets.count
                let bestReps = workingSets.map(\.reps).max() ?? 0

                return ExerciseHistoryEntry(
                    date: session.date,
                    maxWeight: maxWeight,
                    totalVolume: totalVolume,
                    totalSets: totalSets,
                    bestReps: bestReps
                )
            }
            .suffix(limit)
            .map { $0 } // Convert ArraySlice to Array
    }
}
