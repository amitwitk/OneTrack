import Foundation
import SwiftData

@Model
final class WeightGoal {
    var targetWeightKg: Double = 0
    var startWeightKg: Double = 0
    var startDate: Date = Date()
    var targetDate: Date?
    var isActive: Bool = true

    init(targetWeightKg: Double, startWeightKg: Double, startDate: Date = .now, targetDate: Date? = nil) {
        self.targetWeightKg = targetWeightKg
        self.startWeightKg = startWeightKg
        self.startDate = startDate
        self.targetDate = targetDate
    }
}
