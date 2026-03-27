import SwiftUI

struct NutritionTabView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()
                Image(systemName: "fork.knife")
                    .font(.system(size: 48))
                    .foregroundStyle(.green.opacity(0.5))
                Text("Meal Tracking")
                    .font(.title3.bold())
                Text("Coming in Phase 2")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Track calories, macros, and meals with our USDA food database")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Spacer()
            }
            .navigationTitle("Nutrition")
        }
    }
}
