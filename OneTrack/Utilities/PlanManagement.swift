import Foundation

/// Testable utility functions for workout plan management operations.
struct PlanManagement {

    /// Reorders exercises within a section by applying an IndexSet move, then recalculates
    /// sortOrder globally across all sections to maintain consistent ordering.
    ///
    /// - Parameters:
    ///   - exercises: All exercises in the plan (will be mutated in place via reference)
    ///   - sectionName: The section in which the move is occurring
    ///   - from: Source indices (relative to the section)
    ///   - to: Destination index (relative to the section)
    static func reorderExercises(
        allExercises: [Exercise],
        inSection sectionName: String,
        from: IndexSet,
        to: Int
    ) {
        let sorted = allExercises.sorted { $0.sortOrder < $1.sortOrder }

        // Build ordered sections
        var sectionOrder: [String] = []
        for exercise in sorted {
            if !sectionOrder.contains(exercise.section) {
                sectionOrder.append(exercise.section)
            }
        }

        // Group by section preserving order
        var grouped: [String: [Exercise]] = [:]
        for exercise in sorted {
            grouped[exercise.section, default: []].append(exercise)
        }

        // Apply the move in the target section
        if var sectionExercises = grouped[sectionName] {
            sectionExercises.move(fromOffsets: from, toOffset: to)
            grouped[sectionName] = sectionExercises
        }

        // Recalculate sort orders globally
        var order = 0
        for section in sectionOrder {
            for exercise in grouped[section] ?? [] {
                exercise.sortOrder = order
                order += 1
            }
        }
    }

    /// Moves an exercise to a different section, placing it at the end of the target section.
    static func moveExerciseToSection(_ exercise: Exercise, newSection: String, allExercises: [Exercise]) {
        exercise.section = newSection

        // Recalculate sort orders: exercises keep their relative order within sections
        let sorted = allExercises.sorted { $0.sortOrder < $1.sortOrder }
        var sectionOrder: [String] = []
        for ex in sorted {
            if !sectionOrder.contains(ex.section) {
                sectionOrder.append(ex.section)
            }
        }

        var order = 0
        for section in sectionOrder {
            let sectionExercises = sorted.filter { $0.section == section }
            for ex in sectionExercises {
                ex.sortOrder = order
                order += 1
            }
        }
    }

    /// Deletes exercises at the given indices within a section, then recalculates sort order.
    static func deleteExercises(
        allExercises: [Exercise],
        inSection sectionName: String,
        at offsets: IndexSet
    ) -> [Exercise] {
        let sorted = allExercises.sorted { $0.sortOrder < $1.sortOrder }
        let sectionExercises = sorted.filter { $0.section == sectionName }
        let toDelete = offsets.map { sectionExercises[$0] }

        // Recalculate sort orders for remaining exercises
        let remaining = sorted.filter { !toDelete.contains($0) }
        for (index, exercise) in remaining.enumerated() {
            exercise.sortOrder = index
        }

        return toDelete
    }

    /// Reorders plans by applying an IndexSet move and recalculating sortOrder.
    static func reorderPlans(_ plans: inout [WorkoutPlan], from: IndexSet, to: Int) {
        plans.move(fromOffsets: from, toOffset: to)
        for (index, plan) in plans.enumerated() {
            plan.sortOrder = index
        }
    }

    /// Deletes a set from an exercise log and renumbers remaining sets.
    static func deleteSet(_ setLog: SetLog, from exerciseLog: ExerciseLog) {
        let remaining = exerciseLog.sets
            .filter { $0.id != setLog.id }
            .sorted { $0.setNumber < $1.setNumber }
        for (index, s) in remaining.enumerated() {
            s.setNumber = index + 1
        }
    }
}

// Exercise needs Equatable conformance for contains() — @Model provides identity via id
extension Exercise: Equatable {
    static func == (lhs: Exercise, rhs: Exercise) -> Bool {
        lhs.id == rhs.id
    }
}
