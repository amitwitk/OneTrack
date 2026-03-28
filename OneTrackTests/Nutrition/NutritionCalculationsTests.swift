import Testing
import Foundation
import SwiftData
@testable import OneTrack

@Suite("Nutrition Calculations")
@MainActor
struct NutritionCalculationsTests {

    @Test func scaleMacros_100g() {
        let food = FoodItem(fdcId: 1, description: "Test", calories: 200, protein: 25, carbs: 10, fat: 8)
        let result = NutritionCalculations.scaleMacros(food: food, grams: 100)
        #expect(result.calories == 200)
        #expect(result.protein == 25)
    }

    @Test func scaleMacros_250g() {
        let food = FoodItem(fdcId: 1, description: "Test", calories: 200, protein: 20, carbs: 10, fat: 5)
        let result = NutritionCalculations.scaleMacros(food: food, grams: 250)
        #expect(result.calories == 500)
        #expect(result.protein == 50)
        #expect(result.carbs == 25)
        #expect(result.fat == 12.5)
    }

    @Test func scaleMacros_zeroGrams() {
        let food = FoodItem(fdcId: 1, description: "Test", calories: 200, protein: 20, carbs: 10, fat: 5)
        let result = NutritionCalculations.scaleMacros(food: food, grams: 0)
        #expect(result.calories == 0)
    }

    @Test func remainingCalories_underBudget() {
        let remaining = NutritionCalculations.remainingCalories(budget: 2000, consumed: 1500)
        #expect(remaining == 500)
    }

    @Test func remainingCalories_overBudget() {
        let remaining = NutritionCalculations.remainingCalories(budget: 2000, consumed: 2300)
        #expect(remaining == -300)
    }

    @Test func macroPercentage_balanced() {
        // 100g protein (400 cal), 100g carbs (400 cal), ~44g fat (400 cal) ≈ 33% each
        let result = NutritionCalculations.macroPercentage(proteinG: 100, carbsG: 100, fatG: 44.44)
        #expect(abs(result.protein - 0.333) < 0.01)
        #expect(abs(result.carbs - 0.333) < 0.01)
        #expect(abs(result.fat - 0.333) < 0.01)
    }

    @Test func macroPercentage_zeroAll() {
        let result = NutritionCalculations.macroPercentage(proteinG: 0, carbsG: 0, fatG: 0)
        #expect(result.protein == 0)
        #expect(result.carbs == 0)
        #expect(result.fat == 0)
    }

    @Test func budgetProgress_half() {
        let progress = NutritionCalculations.budgetProgress(consumed: 1000, budget: 2000)
        #expect(progress == 0.5)
    }

    @Test func budgetProgress_caps() {
        let progress = NutritionCalculations.budgetProgress(consumed: 3000, budget: 2000)
        #expect(progress == 1.0)
    }

    @Test func budgetProgress_zeroBudget() {
        let progress = NutritionCalculations.budgetProgress(consumed: 500, budget: 0)
        #expect(progress == 0)
    }

    @Test func totalCalories_multipleMeals() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let m1 = MealEntry(mealType: "Breakfast")
        context.insert(m1)
        let i1 = Ingredient(name: "Eggs", quantity: 100, unit: "g", calories: 155, proteinG: 13, carbsG: 1, fatG: 11)
        i1.meal = m1
        context.insert(i1)

        let m2 = MealEntry(mealType: "Lunch")
        context.insert(m2)
        let i2 = Ingredient(name: "Chicken", quantity: 200, unit: "g", calories: 330, proteinG: 62, carbsG: 0, fatG: 7)
        i2.meal = m2
        context.insert(i2)
        try context.save()

        let total = NutritionCalculations.totalCalories(meals: [m1, m2])
        #expect(total == 485)
    }
}
