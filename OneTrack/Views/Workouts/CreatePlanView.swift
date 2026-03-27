import SwiftUI
import SwiftData

struct CreatePlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var editingPlan: WorkoutPlan?

    @State private var planName: String = ""
    @State private var exercises: [EditableExercise] = []
    @State private var showExercisePicker = false

    init(editingPlan: WorkoutPlan? = nil) {
        self.editingPlan = editingPlan
        if let plan = editingPlan {
            _planName = State(initialValue: plan.name)
            _exercises = State(initialValue: plan.exercises
                .sorted { $0.sortOrder < $1.sortOrder }
                .map { EditableExercise(name: $0.name, sets: $0.targetSets, reps: $0.targetReps) }
            )
        }
    }

    private var canSave: Bool {
        !planName.trimmingCharacters(in: .whitespaces).isEmpty && !exercises.isEmpty
    }

    var body: some View {
        List {
            // Plan name
            Section {
                TextField("Workout name", text: $planName)
                    .font(.headline)
            } header: {
                Text("Name")
            }

            // Exercises
            Section {
                if exercises.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.title2)
                            .foregroundStyle(.tertiary)
                        Text("No exercises yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                } else {
                    ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                        exerciseRow(exercise, index: index)
                    }
                    .onDelete { indexSet in
                        exercises.remove(atOffsets: indexSet)
                    }
                    .onMove { from, to in
                        exercises.move(fromOffsets: from, toOffset: to)
                    }
                }

                Button {
                    showExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus.circle.fill")
                }
            } header: {
                HStack {
                    Text("Exercises")
                    Spacer()
                    if !exercises.isEmpty {
                        Text("\(exercises.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(editingPlan == nil ? "New Workout" : "Edit Workout")
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
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerView { templates in
                for template in templates {
                    exercises.append(EditableExercise(
                        name: template.name,
                        sets: template.defaultSets,
                        reps: template.defaultReps
                    ))
                }
            }
        }
    }

    private func exerciseRow(_ exercise: EditableExercise, index: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .foregroundStyle(.tertiary)

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.name)
                    .font(.subheadline.bold())
                Text("\(exercise.sets) sets x \(exercise.reps) reps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Quick set/rep adjustment
            HStack(spacing: 16) {
                Stepper("", value: Binding(
                    get: { exercises[index].sets },
                    set: { exercises[index].sets = $0 }
                ), in: 1...10)
                .labelsHidden()
                .scaleEffect(0.8)
            }
        }
    }

    private func save() {
        if let plan = editingPlan {
            // Update existing
            plan.name = planName.trimmingCharacters(in: .whitespaces)
            // Remove old exercises
            for exercise in plan.exercises {
                modelContext.delete(exercise)
            }
            // Add new
            for (index, ex) in exercises.enumerated() {
                let exercise = Exercise(name: ex.name, targetSets: ex.sets, targetReps: ex.reps, sortOrder: index)
                exercise.plan = plan
                modelContext.insert(exercise)
            }
        } else {
            // Create new plan
            let descriptor = FetchDescriptor<WorkoutPlan>(sortBy: [SortDescriptor(\.sortOrder, order: .reverse)])
            let maxOrder = (try? modelContext.fetch(descriptor).first?.sortOrder) ?? -1

            let plan = WorkoutPlan(
                name: planName.trimmingCharacters(in: .whitespaces),
                planDescription: "",
                sortOrder: maxOrder + 1
            )
            modelContext.insert(plan)

            for (index, ex) in exercises.enumerated() {
                let exercise = Exercise(name: ex.name, targetSets: ex.sets, targetReps: ex.reps, sortOrder: index)
                exercise.plan = plan
                modelContext.insert(exercise)
            }
        }

        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Editable Exercise Model

struct EditableExercise: Identifiable {
    let id = UUID()
    var name: String
    var sets: Int
    var reps: Int
}

// MARK: - Exercise Picker

struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selected: Set<String> = []
    let onAdd: ([ExerciseTemplate]) -> Void

    private var filteredExercises: [ExerciseTemplate] {
        ExerciseDatabase.search(searchText)
    }

    private var groupedExercises: [(String, [ExerciseTemplate])] {
        let grouped = Dictionary(grouping: filteredExercises, by: \.category)
        return ExerciseDatabase.categories
            .filter { grouped[$0] != nil }
            .map { ($0, grouped[$0]!) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedExercises, id: \.0) { category, exercises in
                    Section(category) {
                        ForEach(exercises) { exercise in
                            Button {
                                if selected.contains(exercise.name) {
                                    selected.remove(exercise.name)
                                } else {
                                    selected.insert(exercise.name)
                                }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(exercise.name)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                        Text("\(exercise.defaultSets) x \(exercise.defaultReps)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if selected.contains(exercise.name) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                            .font(.title3)
                                    }
                                }
                            }
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
                    Button("Add \(selected.count > 0 ? "(\(selected.count))" : "")") {
                        let templates = ExerciseDatabase.exercises.filter { selected.contains($0.name) }
                        onAdd(templates)
                        dismiss()
                    }
                    .bold()
                    .disabled(selected.isEmpty)
                }
            }
        }
    }
}
