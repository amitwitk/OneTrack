import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomExercise.name) private var customExercises: [CustomExercise]
    @State private var searchText = ""
    @State private var selected: Set<String> = []
    @State private var showCreateExercise = false
    let onAdd: ([ExerciseTemplate]) -> Void

    private var allTemplates: [ExerciseTemplate] {
        let custom = customExercises.map { $0.toTemplate() }
        return ExerciseDatabase.exercises + custom
    }

    private var filteredTemplates: [ExerciseTemplate] {
        guard !searchText.isEmpty else { return allTemplates }
        let lower = searchText.lowercased()
        return allTemplates.filter {
            $0.name.lowercased().contains(lower) || $0.category.lowercased().contains(lower)
        }
    }

    private var allCategories: [String] {
        let cats = Set(allTemplates.map(\.category))
        let order = ["Chest", "Back", "Shoulders", "Arms", "Legs", "Core"]
        var result = order.filter { cats.contains($0) }
        let extra = cats.subtracting(Set(order)).sorted()
        result.append(contentsOf: extra)
        return result
    }

    private var groupedTemplates: [(String, [ExerciseTemplate])] {
        let grouped = Dictionary(grouping: filteredTemplates, by: \.category)
        return allCategories.compactMap { cat in
            guard let exercises = grouped[cat] else { return nil }
            return (cat, exercises)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // Create custom exercise button
                Section {
                    Button {
                        showCreateExercise = true
                    } label: {
                        Label("Create Custom Exercise", systemImage: "plus.circle")
                            .foregroundStyle(.blue)
                    }
                }

                ForEach(groupedTemplates, id: \.0) { category, exercises in
                    Section(category) {
                        ForEach(exercises) { exercise in
                            exerciseRow(exercise)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search exercises")
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add\(selected.count > 0 ? " (\(selected.count))" : "")") {
                        let templates = allTemplates.filter { selected.contains($0.name) }
                        onAdd(templates)
                        dismiss()
                    }
                    .bold()
                    .disabled(selected.isEmpty)
                }
            }
            .sheet(isPresented: $showCreateExercise) {
                NavigationStack {
                    CreateExerciseView()
                }
            }
        }
    }

    private func exerciseRow(_ exercise: ExerciseTemplate) -> some View {
        Button {
            if selected.contains(exercise.name) {
                selected.remove(exercise.name)
            } else {
                selected.insert(exercise.name)
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(exercise.name)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        if customExercises.contains(where: { $0.name == exercise.name }) {
                            Image(systemName: "person.fill")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                    }
                    Text(exercise.displayTarget)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if exercise.isIsometric {
                    Text("iso")
                        .font(.caption2.bold())
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.orange.opacity(0.1), in: Capsule())
                }

                if selected.contains(exercise.name) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.title3)
                }
            }
        }
    }
}

// MARK: - Create Exercise View

struct CreateExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category = "Chest"
    @State private var sets = 3
    @State private var reps = 10
    @State private var isIsometric = false
    @State private var seconds = 30

    private let categories = ["Chest", "Back", "Shoulders", "Arms", "Legs", "Core", "Cardio", "Other"]

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        Form {
            Section("Exercise Details") {
                TextField("Exercise name", text: $name)
                Picker("Category", selection: $category) {
                    ForEach(categories, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
            }

            Section("Type") {
                Toggle("Time-based (isometric)", isOn: $isIsometric)

                Stepper("Sets: \(sets)", value: $sets, in: 1...10)

                if isIsometric {
                    Stepper("Seconds: \(seconds)", value: $seconds, in: 5...300, step: 5)
                } else {
                    Stepper("Reps: \(reps)", value: $reps, in: 1...100)
                }
            }

            Section {
                HStack {
                    Text("Preview")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(isIsometric ? "\(sets) x \(seconds)s" : "\(sets) x \(reps)")
                        .font(.subheadline.bold().monospacedDigit())
                }
            }
        }
        .navigationTitle("New Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") { save() }
                    .bold()
                    .disabled(!canSave)
            }
        }
    }

    private func save() {
        let exercise = CustomExercise(
            name: name.trimmingCharacters(in: .whitespaces),
            category: category,
            defaultSets: sets,
            defaultReps: isIsometric ? 0 : reps,
            isIsometric: isIsometric,
            defaultSeconds: seconds
        )
        modelContext.insert(exercise)
        try? modelContext.save()
        dismiss()
    }
}
