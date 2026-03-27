import Foundation
import SwiftData

@Model
final class MealEntry {
    var date: Date = Date()
    var mealType: String = ""
    var notes: String = ""
    @Relationship(deleteRule: .cascade, inverse: \Ingredient.meal)
    var ingredients: [Ingredient] = []

    var totalCalories: Double {
        ingredients.reduce(0) { $0 + $1.calories }
    }

    var totalProtein: Double {
        ingredients.reduce(0) { $0 + $1.proteinG }
    }

    var totalCarbs: Double {
        ingredients.reduce(0) { $0 + $1.carbsG }
    }

    var totalFat: Double {
        ingredients.reduce(0) { $0 + $1.fatG }
    }

    init(date: Date = .now, mealType: String) {
        self.date = date
        self.mealType = mealType
    }
}
