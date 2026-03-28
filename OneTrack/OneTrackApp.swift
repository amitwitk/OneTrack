import SwiftUI
import SwiftData

@main
struct OneTrackApp: App {
    let sharedModelContainer: ModelContainer

    init() {
        let schema = Schema([
            WorkoutPlan.self,
            Exercise.self,
            WorkoutSession.self,
            ExerciseLog.self,
            SetLog.self,
            MealEntry.self,
            Ingredient.self,
            BodyMeasurement.self,
            WeightEntry.self,
            CustomExercise.self,
            WeightGoal.self,
            ProgressPhoto.self
        ])
        // CloudKit sync: set to .automatic when using a paid Apple Developer account.
        // With a free account, use .none to avoid provisioning errors.
        let useCloudKit = false // flip to true with paid Apple Developer account ($99/year)

        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: useCloudKit ? .automatic : .none
        )
        do {
            sharedModelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
