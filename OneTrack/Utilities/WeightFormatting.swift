import Foundation

extension Double {
    var formattedWeight: String {
        truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(self)) kg"
            : String(format: "%.1f kg", self)
    }

    var compactWeight: String {
        truncatingRemainder(dividingBy: 1) == 0
            ? "\(Int(self))kg"
            : String(format: "%.1fkg", self)
    }
}
