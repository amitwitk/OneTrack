import Foundation

/// Tagged item for a flat list representation of a workout plan.
enum PlanListItem: Identifiable, Equatable {
    case sectionHeader(String)
    case exercise(Exercise)

    var id: String {
        switch self {
        case .sectionHeader(let name): return "header-\(name)"
        case .exercise(let ex): return ex.persistentModelID.hashValue.description
        }
    }

    static func == (lhs: PlanListItem, rhs: PlanListItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct PlanManagement {

    /// Builds a flat list of headers and exercises from sorted exercises.
    /// Headers appear based on section changes in sortOrder.
    /// Empty groups (from knownGroups) are included as standalone headers.
    static func buildFlatList(exercises: [Exercise], knownGroups: [String] = []) -> [PlanListItem] {
        let sorted = exercises.sorted { $0.sortOrder < $1.sortOrder }

        // Collect section order from exercises
        var sectionOrder: [String] = []
        for ex in sorted {
            if !sectionOrder.contains(ex.section) {
                sectionOrder.append(ex.section)
            }
        }

        // Add known groups that aren't already represented
        for group in knownGroups {
            if !sectionOrder.contains(group) {
                sectionOrder.append(group)
            }
        }

        // Group exercises by section
        let grouped = Dictionary(grouping: sorted, by: \.section)

        var result: [PlanListItem] = []
        for section in sectionOrder {
            result.append(.sectionHeader(section))
            if let exercises = grouped[section] {
                for ex in exercises {
                    result.append(.exercise(ex))
                }
            }
        }
        return result
    }

    /// After a flat list move, determines which section each exercise belongs to
    /// by scanning backwards to find the nearest header.
    /// Returns the updated section assignments and recalculates sortOrder.
    static func applyMove(flatList: inout [PlanListItem], from: IndexSet, to: Int) {
        flatList.move(fromOffsets: from, toOffset: to)
        reassignSectionsAndOrder(flatList: flatList)
    }

    /// Reassigns section and sortOrder to all exercises based on their position
    /// relative to headers in the flat list.
    static func reassignSectionsAndOrder(flatList: [PlanListItem]) {
        var currentSection = ""
        var exerciseOrder = 0
        for item in flatList {
            switch item {
            case .sectionHeader(let name):
                currentSection = name
            case .exercise(let ex):
                ex.section = currentSection
                ex.sortOrder = exerciseOrder
                exerciseOrder += 1
            }
        }
    }

    /// Finds the section name for an item at a given index by scanning backwards.
    static func sectionForIndex(_ index: Int, in flatList: [PlanListItem]) -> String {
        for i in stride(from: index, through: 0, by: -1) {
            if case .sectionHeader(let name) = flatList[i] {
                return name
            }
        }
        return ""
    }

    /// Deletes an exercise from the flat list and the plan.
    static func deleteExercise(_ exercise: Exercise) {
        exercise.plan?.exercises.removeAll { $0.id == exercise.id }
    }

    /// Renumbers sortOrder for all exercises in a plan based on current flat list order.
    static func renumberSortOrder(exercises: [Exercise]) {
        let sorted = exercises.sorted { $0.sortOrder < $1.sortOrder }
        for (index, ex) in sorted.enumerated() {
            ex.sortOrder = index
        }
    }

    /// Reorders plans by applying an IndexSet move and recalculating sortOrder.
    static func reorderPlans(_ plans: inout [WorkoutPlan], from: IndexSet, to: Int) {
        plans.move(fromOffsets: from, toOffset: to)
        for (index, plan) in plans.enumerated() {
            plan.sortOrder = index
        }
    }

    /// Deletes a set from an exercise log and renumbers remaining sets.
    static func deleteSet(_ setLog: SetLog, from log: ExerciseLog) {
        let deletedNumber = setLog.setNumber
        for remainingSet in log.sets where remainingSet.setNumber > deletedNumber {
            remainingSet.setNumber -= 1
        }
    }
}
