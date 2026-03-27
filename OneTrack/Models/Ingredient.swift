import Foundation
import SwiftData

@Model
final class Ingredient {
    var name: String = ""
    var quantity: Double = 0
    var unit: String = "g"
    var calories: Double = 0
    var proteinG: Double = 0
    var carbsG: Double = 0
    var fatG: Double = 0
    var fdcId: Int?
    var meal: MealEntry?

    init(name: String, quantity: Double, unit: String, calories: Double, proteinG: Double, carbsG: Double, fatG: Double, fdcId: Int? = nil) {
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.calories = calories
        self.proteinG = proteinG
        self.carbsG = carbsG
        self.fatG = fatG
        self.fdcId = fdcId
    }
}
