import SwiftUI

struct ContentView: View {
    @State private var healthKit = HealthKitManager()

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
                ActivityTabView(healthKit: healthKit)
            }
        }
        .task {
            await healthKit.requestAuthorization()
            await healthKit.fetchAll()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            WorkoutPlan.self, Exercise.self,
            WorkoutSession.self, ExerciseLog.self, SetLog.self,
            MealEntry.self, Ingredient.self,
            BodyMeasurement.self, WeightEntry.self,
            CustomExercise.self,
            WeightGoal.self, ProgressPhoto.self
        ], inMemory: true)
}
