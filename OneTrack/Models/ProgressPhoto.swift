import Foundation
import SwiftData

@Model
final class ProgressPhoto {
    var date: Date = Date()
    var filename: String = ""
    var weightKg: Double?
    var notes: String = ""

    init(date: Date = .now, filename: String, weightKg: Double? = nil, notes: String = "") {
        self.date = date
        self.filename = filename
        self.weightKg = weightKg
        self.notes = notes
    }
}
