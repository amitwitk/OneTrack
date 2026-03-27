import Foundation

struct ExerciseTemplate: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: String
    let defaultSets: Int
    let defaultReps: Int
    let isIsometric: Bool
    let defaultSeconds: Int

    init(name: String, category: String, defaultSets: Int, defaultReps: Int, isIsometric: Bool = false, defaultSeconds: Int = 30) {
        self.name = name
        self.category = category
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.isIsometric = isIsometric
        self.defaultSeconds = defaultSeconds
    }

    var displayTarget: String {
        isIsometric ? "\(defaultSets) x \(defaultSeconds)s" : "\(defaultSets) x \(defaultReps)"
    }
}

struct ExerciseDatabase {
    static let exercises: [ExerciseTemplate] = [
        // Chest
        ExerciseTemplate(name: "Bench Press", category: "Chest", defaultSets: 4, defaultReps: 10),
        ExerciseTemplate(name: "Incline Bench Press", category: "Chest", defaultSets: 3, defaultReps: 10),
        ExerciseTemplate(name: "Dumbbell Bench Press", category: "Chest", defaultSets: 4, defaultReps: 10),
        ExerciseTemplate(name: "Incline Dumbbell Press", category: "Chest", defaultSets: 3, defaultReps: 12),
        ExerciseTemplate(name: "Cable Flyes", category: "Chest", defaultSets: 3, defaultReps: 12),
        ExerciseTemplate(name: "Dips (Chest)", category: "Chest", defaultSets: 3, defaultReps: 12),
        ExerciseTemplate(name: "Push-ups", category: "Chest", defaultSets: 3, defaultReps: 15),

        // Back
        ExerciseTemplate(name: "Deadlift", category: "Back", defaultSets: 4, defaultReps: 6),
        ExerciseTemplate(name: "Barbell Rows", category: "Back", defaultSets: 4, defaultReps: 10),
        ExerciseTemplate(name: "Lat Pulldowns", category: "Back", defaultSets: 3, defaultReps: 12),
        ExerciseTemplate(name: "Pull-ups", category: "Back", defaultSets: 4, defaultReps: 8),
        ExerciseTemplate(name: "Weighted Pull-ups", category: "Back", defaultSets: 4, defaultReps: 8),
        ExerciseTemplate(name: "Cable Rows", category: "Back", defaultSets: 3, defaultReps: 12),
        ExerciseTemplate(name: "T-Bar Rows", category: "Back", defaultSets: 4, defaultReps: 10),
        ExerciseTemplate(name: "Face Pulls", category: "Back", defaultSets: 3, defaultReps: 15),
        ExerciseTemplate(name: "Dead Hang", category: "Back", defaultSets: 3, defaultReps: 0, isIsometric: true, defaultSeconds: 30),

        // Shoulders
        ExerciseTemplate(name: "Overhead Press", category: "Shoulders", defaultSets: 3, defaultReps: 10),
        ExerciseTemplate(name: "Arnold Press", category: "Shoulders", defaultSets: 3, defaultReps: 10),
        ExerciseTemplate(name: "Lateral Raises", category: "Shoulders", defaultSets: 3, defaultReps: 15),
        ExerciseTemplate(name: "Front Raises", category: "Shoulders", defaultSets: 3, defaultReps: 12),
        ExerciseTemplate(name: "Reverse Flyes", category: "Shoulders", defaultSets: 3, defaultReps: 15),

        // Arms
        ExerciseTemplate(name: "Barbell Curls", category: "Arms", defaultSets: 3, defaultReps: 12),
        ExerciseTemplate(name: "Hammer Curls", category: "Arms", defaultSets: 3, defaultReps: 12),
        ExerciseTemplate(name: "Tricep Pushdowns", category: "Arms", defaultSets: 3, defaultReps: 12),
        ExerciseTemplate(name: "Overhead Tricep Extension", category: "Arms", defaultSets: 3, defaultReps: 12),
        ExerciseTemplate(name: "Skull Crushers", category: "Arms", defaultSets: 3, defaultReps: 10),

        // Legs
        ExerciseTemplate(name: "Squats", category: "Legs", defaultSets: 4, defaultReps: 8),
        ExerciseTemplate(name: "Front Squats", category: "Legs", defaultSets: 3, defaultReps: 8),
        ExerciseTemplate(name: "Romanian Deadlift", category: "Legs", defaultSets: 3, defaultReps: 10),
        ExerciseTemplate(name: "Leg Press", category: "Legs", defaultSets: 3, defaultReps: 12),
        ExerciseTemplate(name: "Leg Curls", category: "Legs", defaultSets: 3, defaultReps: 12),
        ExerciseTemplate(name: "Leg Extensions", category: "Legs", defaultSets: 3, defaultReps: 12),
        ExerciseTemplate(name: "Calf Raises", category: "Legs", defaultSets: 4, defaultReps: 15),
        ExerciseTemplate(name: "Bulgarian Split Squats", category: "Legs", defaultSets: 3, defaultReps: 10),
        ExerciseTemplate(name: "Wall Sit", category: "Legs", defaultSets: 3, defaultReps: 0, isIsometric: true, defaultSeconds: 45),

        // Core
        ExerciseTemplate(name: "Plank", category: "Core", defaultSets: 3, defaultReps: 0, isIsometric: true, defaultSeconds: 60),
        ExerciseTemplate(name: "Hanging Leg Raises", category: "Core", defaultSets: 3, defaultReps: 12),
        ExerciseTemplate(name: "Cable Crunches", category: "Core", defaultSets: 3, defaultReps: 15),
        ExerciseTemplate(name: "Ab Wheel Rollouts", category: "Core", defaultSets: 3, defaultReps: 10),

        // Carry / Functional
        ExerciseTemplate(name: "Farmer Walk", category: "Core", defaultSets: 3, defaultReps: 0, isIsometric: true, defaultSeconds: 45),
    ]

    static var categories: [String] {
        let cats = Set(exercises.map(\.category))
        let order = ["Chest", "Back", "Shoulders", "Arms", "Legs", "Core"]
        return order.filter { cats.contains($0) }
    }

    static func search(_ query: String) -> [ExerciseTemplate] {
        guard !query.isEmpty else { return exercises }
        let lower = query.lowercased()
        return exercises.filter {
            $0.name.lowercased().contains(lower) || $0.category.lowercased().contains(lower)
        }
    }

    static func exercises(in category: String) -> [ExerciseTemplate] {
        exercises.filter { $0.category == category }
    }
}
