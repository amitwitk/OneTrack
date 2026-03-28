import SwiftUI

struct FoodSearchView: View {
    @State private var service = USDAFoodService()
    @State private var query = ""
    @State private var results: [FoodItem] = []
    let onSelect: (FoodItem) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if results.isEmpty && !query.isEmpty {
                    ContentUnavailableView("No Results", systemImage: "magnifyingglass", description: Text("Try a different search term"))
                } else {
                    ForEach(results) { food in
                        Button {
                            onSelect(food)
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(food.description)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .lineLimit(2)
                                HStack(spacing: 12) {
                                    macroLabel("Cal", value: food.calories, color: .orange)
                                    macroLabel("P", value: food.protein, color: .blue)
                                    macroLabel("C", value: food.carbs, color: .green)
                                    macroLabel("F", value: food.fat, color: .red)
                                    Text("per 100g")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "Search foods (e.g. chicken, rice, egg)")
            .onChange(of: query) {
                results = service.search(query: query)
            }
            .navigationTitle("Search Foods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func macroLabel(_ label: String, value: Double, color: Color) -> some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.caption2.bold())
                .foregroundStyle(color)
            Text("\(Int(value))")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }
}
