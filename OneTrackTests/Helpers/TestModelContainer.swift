import Foundation
import SwiftData
@testable import OneTrack

func makeTestContainer() throws -> ModelContainer {
    let schema = Schema([
        WorkoutPlan.self, Exercise.self,
        WorkoutSession.self, ExerciseLog.self, SetLog.self,
        MealEntry.self, Ingredient.self,
        BodyMeasurement.self, WeightEntry.self,
        CustomExercise.self
    ])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [config])
}
