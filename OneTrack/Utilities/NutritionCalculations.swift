import Foundation

struct NutritionCalculations {

    /// Scales per-100g food macros to the given quantity in grams.
    static func scaleMacros(food: FoodItem, grams: Double) -> (calories: Double, protein: Double, carbs: Double, fat: Double) {
        let factor = grams / 100.0
        return (
            calories: food.calories * factor,
            protein: food.protein * factor,
            carbs: food.carbs * factor,
            fat: food.fat * factor
        )
    }

    /// Calculates remaining calories from a daily budget.
    static func remainingCalories(budget: Double, consumed: Double) -> Double {
        budget - consumed
    }

    /// Calculates macro percentage of total calories.
    /// Protein/carbs = 4 cal/g, fat = 9 cal/g.
    static func macroPercentage(proteinG: Double, carbsG: Double, fatG: Double) -> (protein: Double, carbs: Double, fat: Double) {
        let proteinCal = proteinG * 4
        let carbsCal = carbsG * 4
        let fatCal = fatG * 9
        let total = proteinCal + carbsCal + fatCal
        guard total > 0 else { return (0, 0, 0) }
        return (
            protein: proteinCal / total,
            carbs: carbsCal / total,
            fat: fatCal / total
        )
    }

    /// Sums calories from an array of meals.
    static func totalCalories(meals: [MealEntry]) -> Double {
        meals.reduce(0) { $0 + $1.totalCalories }
    }

    /// Sums macros from an array of meals.
    static func totalMacros(meals: [MealEntry]) -> (protein: Double, carbs: Double, fat: Double) {
        let protein = meals.reduce(0) { $0 + $1.totalProtein }
        let carbs = meals.reduce(0) { $0 + $1.totalCarbs }
        let fat = meals.reduce(0) { $0 + $1.totalFat }
        return (protein, carbs, fat)
    }

    /// Progress fraction (0-1) for a calorie budget.
    static func budgetProgress(consumed: Double, budget: Double) -> Double {
        guard budget > 0 else { return 0 }
        return min(consumed / budget, 1.0)
    }
}
