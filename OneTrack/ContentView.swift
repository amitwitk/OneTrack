import SwiftUI
import UserNotifications

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
            // Request notification permission at app launch — NOT during workout
            // to avoid conflicts with fullScreenCover presentation
            requestNotificationPermission()
        }
    }

    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
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
            BodyMeasurement.self, WeightEntry.self,
            CustomExercise.self,
            WeightGoal.self, ProgressPhoto.self
        ], inMemory: true)
}
