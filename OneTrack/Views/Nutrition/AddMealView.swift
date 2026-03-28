import SwiftUI
import SwiftData

struct AddMealView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var editingMeal: MealEntry?

    @State private var mealType: String
    @State private var ingredients: [IngredientDraft] = []
    @State private var showFoodSearch = false
    @State private var quickAddText = ""
    @State private var showQuickAddResults = false
    @State private var parsedIngredients: [ParsedIngredient] = []

    private let mealTypes = ["Breakfast", "Lunch", "Dinner", "Snack"]

    init(editingMeal: MealEntry? = nil) {
        self.editingMeal = editingMeal
        _mealType = State(initialValue: editingMeal?.mealType ?? "Breakfast")
        if let meal = editingMeal {
            _ingredients = State(initialValue: meal.ingredients.map {
                IngredientDraft(name: $0.name, grams: $0.quantity, unit: $0.unit,
                                caloriesPer100g: $0.quantity > 0 ? $0.calories / ($0.quantity / 100) : 0,
                                proteinPer100g: $0.quantity > 0 ? $0.proteinG / ($0.quantity / 100) : 0,
                                carbsPer100g: $0.quantity > 0 ? $0.carbsG / ($0.quantity / 100) : 0,
                                fatPer100g: $0.quantity > 0 ? $0.fatG / ($0.quantity / 100) : 0,
                                fdcId: $0.fdcId)
            })
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Meal type
                Section("Meal Type") {
                    Picker("Type", selection: $mealType) {
                        ForEach(mealTypes, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }

                // Ingredients
                Section {
                    if ingredients.isEmpty {
                        Text("No ingredients yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(ingredients.enumerated()), id: \.element.id) { index, draft in
                            ingredientRow(draft, index: index)
                        }
                        .onDelete { indices in
                            ingredients.remove(atOffsets: indices)
                        }
                    }

                    Button {
                        showFoodSearch = true
                    } label: {
                        Label("Search Food Database", systemImage: "magnifyingglass")
                    }
                } header: {
                    Text("Ingredients")
                } footer: {
                    if !ingredients.isEmpty {
                        let totalCal = ingredients.reduce(0.0) { $0 + $1.scaledCalories }
                        Text("Total: \(Int(totalCal)) cal")
                    }
                }

                // Quick add
                Section("Quick Add") {
                    TextField("e.g. 3 eggs, 200g chicken breast", text: $quickAddText, axis: .vertical)
                        .lineLimit(3...6)
                    Button("Parse & Add") {
                        parseQuickAdd()
                    }
                    .disabled(quickAddText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(editingMeal != nil ? "Edit Meal" : "Add Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .bold()
                        .disabled(ingredients.isEmpty)
                }
            }
            .sheet(isPresented: $showFoodSearch) {
                FoodSearchView { food in
                    addFood(food)
                }
            }
        }
    }

    // MARK: - Ingredient Row

    private func ingredientRow(_ draft: IngredientDraft, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(draft.name)
                .font(.subheadline.bold())
            HStack {
                Stepper(
                    "\(Int(draft.grams))g",
                    value: Binding(
                        get: { ingredients[index].grams },
                        set: { ingredients[index].grams = $0 }
                    ),
                    in: 10...2000,
                    step: 10
                )
                .font(.caption)
            }
            HStack(spacing: 12) {
                Text("\(Int(draft.scaledCalories)) cal")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.orange)
                Text("P:\(Int(draft.scaledProtein))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.blue)
                Text("C:\(Int(draft.scaledCarbs))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.green)
                Text("F:\(Int(draft.scaledFat))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Actions

    private func addFood(_ food: FoodItem) {
        ingredients.append(IngredientDraft(
            name: food.description,
            grams: 100,
            unit: "g",
            caloriesPer100g: food.calories,
            proteinPer100g: food.protein,
            carbsPer100g: food.carbs,
            fatPer100g: food.fat,
            fdcId: food.fdcId
        ))
    }

    private func parseQuickAdd() {
        let service = USDAFoodService()
        let parsed = IngredientParser.parse(quickAddText)
        for item in parsed {
            let results = service.search(query: item.foodName)
            if let food = results.first {
                let grams = item.unit == "g" ? item.quantity : item.quantity * 100
                ingredients.append(IngredientDraft(
                    name: food.description,
                    grams: grams,
                    unit: "g",
                    caloriesPer100g: food.calories,
                    proteinPer100g: food.protein,
                    carbsPer100g: food.carbs,
                    fatPer100g: food.fat,
                    fdcId: food.fdcId
                ))
            } else {
                // Unmatched: add with zero macros, user can edit later
                ingredients.append(IngredientDraft(
                    name: item.foodName,
                    grams: item.unit == "g" ? item.quantity : item.quantity * 100,
                    unit: "g",
                    caloriesPer100g: 0,
                    proteinPer100g: 0,
                    carbsPer100g: 0,
                    fatPer100g: 0,
                    fdcId: nil
                ))
            }
        }
        quickAddText = ""
    }

    private func save() {
        if let meal = editingMeal {
            meal.mealType = mealType
            // Remove old ingredients
            for ingredient in meal.ingredients {
                modelContext.delete(ingredient)
            }
            // Add new ones
            for draft in ingredients {
                let ingredient = draft.toIngredient()
                ingredient.meal = meal
                modelContext.insert(ingredient)
            }
        } else {
            let meal = MealEntry(mealType: mealType)
            modelContext.insert(meal)
            for draft in ingredients {
                let ingredient = draft.toIngredient()
                ingredient.meal = meal
                modelContext.insert(ingredient)
            }
        }
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Draft Model

struct IngredientDraft: Identifiable {
    let id = UUID()
    var name: String
    var grams: Double
    var unit: String
    var caloriesPer100g: Double
    var proteinPer100g: Double
    var carbsPer100g: Double
    var fatPer100g: Double
    var fdcId: Int?

    var scaledCalories: Double { caloriesPer100g * grams / 100 }
    var scaledProtein: Double { proteinPer100g * grams / 100 }
    var scaledCarbs: Double { carbsPer100g * grams / 100 }
    var scaledFat: Double { fatPer100g * grams / 100 }

    func toIngredient() -> Ingredient {
        Ingredient(
            name: name,
            quantity: grams,
            unit: unit,
            calories: scaledCalories,
            proteinG: scaledProtein,
            carbsG: scaledCarbs,
            fatG: scaledFat,
            fdcId: fdcId
        )
    }
}
