import Foundation
import SwiftData

@Model
final class WeightEntry {
    var date: Date = Date()
    var weightKg: Double = 0
    var source: String = "manual"

    init(date: Date = .now, weightKg: Double, source: String = "manual") {
        self.date = date
        self.weightKg = weightKg
        self.source = source
    }
}
