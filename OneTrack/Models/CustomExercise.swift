import Foundation
import SwiftData

@Model
final class CustomExercise {
    var name: String = ""
    var category: String = ""
    var defaultSets: Int = 3
    var defaultReps: Int = 10
    var isIsometric: Bool = false
    var defaultSeconds: Int = 30
    var createdAt: Date = Date()

    init(name: String, category: String, defaultSets: Int = 3, defaultReps: Int = 10, isIsometric: Bool = false, defaultSeconds: Int = 30) {
        self.name = name
        self.category = category
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.isIsometric = isIsometric
        self.defaultSeconds = defaultSeconds
    }

    func toTemplate() -> ExerciseTemplate {
        ExerciseTemplate(
            name: name,
            category: category,
            defaultSets: defaultSets,
            defaultReps: defaultReps,
            isIsometric: isIsometric,
            defaultSeconds: defaultSeconds
        )
    }
}
