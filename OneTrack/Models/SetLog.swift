import Foundation
import SwiftData

@Model
final class SetLog {
    var setNumber: Int = 0
    var reps: Int = 0
    var weightKg: Double = 0
    var isCompleted: Bool = false
    var exerciseLog: ExerciseLog?

    init(setNumber: Int, reps: Int = 0, weightKg: Double = 0) {
        self.setNumber = setNumber
        self.reps = reps
        self.weightKg = weightKg
    }
}
