import Foundation
import SwiftData

@Model
final class ExerciseLog {
    var exerciseName: String = ""
    var sortOrder: Int = 0
    var session: WorkoutSession?
    @Relationship(deleteRule: .cascade, inverse: \SetLog.exerciseLog)
    var sets: [SetLog] = []

    init(exerciseName: String, sortOrder: Int) {
        self.exerciseName = exerciseName
        self.sortOrder = sortOrder
    }
}
