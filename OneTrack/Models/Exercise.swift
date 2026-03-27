import Foundation
import SwiftData

@Model
final class Exercise {
    var name: String = ""
    var targetSets: Int = 3
    var targetReps: Int = 10
    var sortOrder: Int = 0
    var plan: WorkoutPlan?

    init(name: String, targetSets: Int, targetReps: Int, sortOrder: Int) {
        self.name = name
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.sortOrder = sortOrder
    }
}
