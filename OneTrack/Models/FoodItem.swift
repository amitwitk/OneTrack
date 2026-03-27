import Foundation

struct FoodItem: Codable, Identifiable, Sendable {
    let fdcId: Int
    let description: String
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double

    var id: Int { fdcId }
}
