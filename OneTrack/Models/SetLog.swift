import Foundation
import SwiftData

enum SetType: String, Codable, CaseIterable {
    case normal
    case warmUp
    case dropSet
    case toFailure
}

@Model
final class SetLog {
    var setNumber: Int = 0
    var reps: Int = 0
    var seconds: Int = 0
    var weightKg: Double = 0
    var isCompleted: Bool = false
    var setTypeRaw: String = SetType.normal.rawValue
    var exerciseLog: ExerciseLog?

    var setType: SetType {
        get { SetType(rawValue: setTypeRaw) ?? .normal }
        set { setTypeRaw = newValue.rawValue }
    }

    var isWarmUp: Bool { setType == .warmUp }

    init(setNumber: Int, reps: Int = 0, seconds: Int = 0, weightKg: Double = 0, setType: SetType = .normal) {
        self.setNumber = setNumber
        self.reps = reps
        self.seconds = seconds
        self.weightKg = weightKg
        self.setTypeRaw = setType.rawValue
    }
}
