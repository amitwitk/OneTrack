import Foundation
import SwiftData

@Model
final class WorkoutSession {
    var date: Date = Date()
    var startedAt: Date = Date()
    var durationSeconds: Int?
    var isCompleted: Bool = false
    var plan: WorkoutPlan?
    @Relationship(deleteRule: .cascade, inverse: \ExerciseLog.session)
    var exerciseLogs: [ExerciseLog] = []
    var notes: String = ""

    init(date: Date = .now, plan: WorkoutPlan? = nil) {
        self.date = date
        self.startedAt = date
        self.plan = plan
    }
}
