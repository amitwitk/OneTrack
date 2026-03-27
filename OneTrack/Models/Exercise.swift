import Foundation
import SwiftData

@Model
final class Exercise {
    var name: String = ""
    var targetSets: Int = 3
    var targetReps: Int = 10
    var isIsometric: Bool = false
    var targetSeconds: Int = 30
    var sortOrder: Int = 0
    var plan: WorkoutPlan?

    init(name: String, targetSets: Int, targetReps: Int, sortOrder: Int, isIsometric: Bool = false, targetSeconds: Int = 30) {
        self.name = name
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.isIsometric = isIsometric
        self.targetSeconds = targetSeconds
        self.sortOrder = sortOrder
    }

    var targetDisplay: String {
        if isIsometric {
            return "\(targetSets) x \(targetSeconds)s"
        }
        return "\(targetSets) x \(targetReps)"
    }
}
