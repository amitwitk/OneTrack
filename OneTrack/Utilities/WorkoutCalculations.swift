import Foundation

struct WorkoutCalculations {

    // MARK: - Estimated 1RM (Epley Formula)

    /// Calculates estimated one-rep max using the Epley formula: weight x (1 + reps / 30).
    /// Returns nil for zero weight, zero reps, or isometric exercises.
    static func estimated1RM(weightKg: Double, reps: Int) -> Double? {
        guard weightKg > 0, reps > 0 else { return nil }
        return weightKg * (1.0 + Double(reps) / 30.0)
    }

    /// Finds the best estimated 1RM from a list of completed sets (non-isometric only).
    static func bestEstimated1RM(completedSets: [SetLog]) -> Double? {
        completedSets
            .filter { $0.isCompleted }
            .compactMap { estimated1RM(weightKg: $0.weightKg, reps: $0.reps) }
            .max()
    }

    // MARK: - Personal Record Detection

    /// Checks whether a set is a new all-time personal record for the given exercise.
    /// `historicalSets` should contain all completed sets ever recorded for this exercise name.
    /// For non-isometric: PR if weight > max ever, or same weight with more reps than ever at that weight.
    /// For isometric: PR if weight > max ever, or same weight with more seconds than ever at that weight.
    static func isPersonalRecord(
        setLog: SetLog,
        isIsometric: Bool,
        historicalSets: [SetLog]
    ) -> Bool {
        guard setLog.isCompleted else { return false }

        let completed = historicalSets.filter { $0.isCompleted }
        guard !completed.isEmpty else {
            // First ever set for this exercise — PR if there is actual weight or effort
            if isIsometric {
                return setLog.weightKg > 0 || setLog.seconds > 0
            }
            return setLog.weightKg > 0 || setLog.reps > 0
        }

        if isIsometric {
            return isIsometricPR(setLog: setLog, historicalSets: completed)
        } else {
            return isStandardPR(setLog: setLog, historicalSets: completed)
        }
    }

    // MARK: - Private

    private static func isStandardPR(setLog: SetLog, historicalSets: [SetLog]) -> Bool {
        guard setLog.weightKg > 0 else { return false }

        let maxWeight = historicalSets.map(\.weightKg).max() ?? 0

        // New weight record
        if setLog.weightKg > maxWeight {
            return true
        }

        // Same weight, more reps than ever at that weight
        if setLog.weightKg == maxWeight {
            let maxRepsAtWeight = historicalSets
                .filter { $0.weightKg == setLog.weightKg }
                .map(\.reps)
                .max() ?? 0
            return setLog.reps > maxRepsAtWeight
        }

        return false
    }

    private static func isIsometricPR(setLog: SetLog, historicalSets: [SetLog]) -> Bool {
        guard setLog.weightKg > 0 else { return false }

        let maxWeight = historicalSets.map(\.weightKg).max() ?? 0

        // New weight record
        if setLog.weightKg > maxWeight {
            return true
        }

        // Same weight, more seconds than ever at that weight
        if setLog.weightKg == maxWeight {
            let maxSecondsAtWeight = historicalSets
                .filter { $0.weightKg == setLog.weightKg }
                .map(\.seconds)
                .max() ?? 0
            return setLog.seconds > maxSecondsAtWeight
        }

        return false
    }
}
