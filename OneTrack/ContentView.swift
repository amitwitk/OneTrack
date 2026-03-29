import SwiftUI
@preconcurrency import UserNotifications

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
            await requestNotificationPermission()
        }
    }

    private func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        try? await center.requestAuthorization(options: [.alert, .sound])
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
