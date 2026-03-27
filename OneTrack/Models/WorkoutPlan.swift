import Foundation
import SwiftData

@Model
final class WorkoutPlan {
    var name: String = ""
    var planDescription: String = ""
    var sortOrder: Int = 0
    @Relationship(deleteRule: .cascade, inverse: \Exercise.plan)
    var exercises: [Exercise] = []
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSession.plan)
    var sessions: [WorkoutSession] = []
    var defaultRestSeconds: Int = 90
    var createdAt: Date = Date()

    init(name: String, planDescription: String, sortOrder: Int, defaultRestSeconds: Int = 90, createdAt: Date = .now) {
        self.name = name
        self.planDescription = planDescription
        self.sortOrder = sortOrder
        self.defaultRestSeconds = defaultRestSeconds
        self.createdAt = createdAt
    }
}
