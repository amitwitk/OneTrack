import SwiftUI
import SwiftData

struct NutritionTabView: View {
    @Query(sort: \MealEntry.date, order: .reverse)
    private var allMeals: [MealEntry]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedDate: Date = .now
    @State private var showAddMeal = false
    @State private var mealToEdit: MealEntry?
    @AppStorage("dailyCalorieBudget") private var budget: Double = 2000

    private var mealsForDate: [MealEntry] {
        let calendar = Calendar.current
        return allMeals.filter { calendar.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var consumed: Double {
        NutritionCalculations.totalCalories(meals: mealsForDate)
    }

    private var macros: (protein: Double, carbs: Double, fat: Double) {
        NutritionCalculations.totalMacros(meals: mealsForDate)
    }

    private var remaining: Double {
        NutritionCalculations.remainingCalories(budget: budget, consumed: consumed)
    }

    private var mealTypeOrder: [String] { ["Breakfast", "Lunch", "Dinner", "Snack"] }

    private var groupedMeals: [(String, [MealEntry])] {
        let grouped = Dictionary(grouping: mealsForDate, by: \.mealType)
        return mealTypeOrder.compactMap { type in
            guard let meals = grouped[type], !meals.isEmpty else { return nil }
            return (type, meals)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Date picker
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .padding(.horizontal)

                    // Daily summary
                    dailySummary

                    // Meal list
                    if groupedMeals.isEmpty {
                        emptyState
                    } else {
                        ForEach(groupedMeals, id: \.0) { mealType, meals in
                            mealSection(mealType, meals: meals)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Nutrition")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddMeal = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddMeal) {
                AddMealView()
            }
            .sheet(item: $mealToEdit) { meal in
                AddMealView(editingMeal: meal)
            }
        }
    }

    // MARK: - Daily Summary

    private var dailySummary: some View {
        VStack(spacing: 12) {
            // Calorie bar
            VStack(spacing: 6) {
                HStack {
                    Text("Calories")
                        .font(.subheadline.bold())
                    Spacer()
                    Text("\(Int(consumed)) / \(Int(budget))")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: NutritionCalculations.budgetProgress(consumed: consumed, budget: budget))
                    .tint(remaining >= 0 ? Color.green : Color.red)
                Text("\(Int(abs(remaining))) cal \(remaining >= 0 ? "remaining" : "over")")
                    .font(.caption)
                    .foregroundStyle(remaining >= 0 ? Color.secondary : Color.red)
            }

            Divider()

            // Macros
            HStack(spacing: 0) {
                macroStat("Protein", grams: macros.protein, color: .blue)
                Divider().frame(height: 36)
                macroStat("Carbs", grams: macros.carbs, color: .green)
                Divider().frame(height: 36)
                macroStat("Fat", grams: macros.fat, color: .red)
            }
        }
        .cardStyle()
        .padding(.horizontal)
    }

    private func macroStat(_ label: String, grams: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(Int(grams))g")
                .font(.headline.monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Meal Section

    private func mealSection(_ type: String, meals: [MealEntry]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(type)
                    .font(.subheadline.bold())
                Spacer()
                let sectionCal = meals.reduce(0.0) { $0 + $1.totalCalories }
                Text("\(Int(sectionCal)) cal")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            ForEach(meals) { meal in
                mealRow(meal)
            }
        }
    }

    private func mealRow(_ meal: MealEntry) -> some View {
        Button {
            mealToEdit = meal
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                // Ingredient names
                Text(meal.ingredients.map(\.name).joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    Text("\(Int(meal.totalCalories)) cal")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.orange)
                    Text("P:\(Int(meal.totalProtein))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.blue)
                    Text("C:\(Int(meal.totalCarbs))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.green)
                    Text("F:\(Int(meal.totalFat))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.red)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.background, in: RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(meal)
                try? modelContext.save()
            } label: {
                Label("Delete Meal", systemImage: "trash")
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text("No meals logged")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Tap + to add your first meal")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
