import Foundation
import SwiftData

@Model
final class BodyMeasurement {
    var date: Date = Date()
    var waistCm: Double?
    var chestCm: Double?
    var leftBicepCm: Double?
    var rightBicepCm: Double?
    var notes: String = ""

    init(date: Date = .now) {
        self.date = date
    }
}
