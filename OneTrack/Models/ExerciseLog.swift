import Foundation
import SwiftData

@Model
final class ExerciseLog {
    var exerciseName: String = ""
    var isIsometric: Bool = false
    var section: String = ""
    var notes: String = ""
    var swappedFromExercise: String = ""
    var sortOrder: Int = 0
    var session: WorkoutSession?
    @Relationship(deleteRule: .cascade, inverse: \SetLog.exerciseLog)
    var sets: [SetLog] = []

    init(exerciseName: String, sortOrder: Int, isIsometric: Bool = false, section: String = "") {
        self.exerciseName = exerciseName
        self.sortOrder = sortOrder
        self.isIsometric = isIsometric
        self.section = section
    }
}
