import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "chart.bar.fill") {
                DashboardView()
            }
            Tab("Workouts", systemImage: "dumbbell.fill") {
                WorkoutsTabView()
            }
            Tab("Nutrition", systemImage: "fork.knife") {
                NutritionTabView()
            }
            Tab("Body", systemImage: "figure.arms.open") {
                BodyTabView()
            }
            Tab("Activity", systemImage: "flame.fill") {
                ActivityTabView()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            WorkoutPlan.self, Exercise.self,
            WorkoutSession.self, ExerciseLog.self, SetLog.self,
            MealEntry.self, Ingredient.self,
            BodyMeasurement.self, WeightEntry.self
        ], inMemory: true)
}
