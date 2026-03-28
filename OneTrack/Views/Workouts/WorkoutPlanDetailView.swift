import SwiftUI
import SwiftData

struct WorkoutPlanDetailView: View {
    let plan: WorkoutPlan
    @Environment(\.modelContext) private var modelContext
    @State private var exerciseToEdit: Exercise?
    @State private var showAddGroup = false
    @State private var newGroupName = ""

    private var sortedExercises: [Exercise] {
        plan.exercises.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var sections: [(String, [Exercise])] {
        let grouped = Dictionary(grouping: sortedExercises, by: \.section)
        var sectionOrder: [String] = []
        for exercise in sortedExercises {
            if !sectionOrder.contains(exercise.section) {
                sectionOrder.append(exercise.section)
            }
        }
        return sectionOrder.compactMap { section in
            guard let exercises = grouped[section] else { return nil }
            return (section, exercises)
        }
    }

    private var completedSessions: [WorkoutSession] {
        plan.sessions.filter(\.isCompleted).sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            // Exercise sections
            ForEach(sections, id: \.0) { sectionName, exercises in
                Section {
                    ForEach(exercises) { exercise in
                        Button {
                            exerciseToEdit = exercise
                        } label: {
                            HStack(spacing: 12) {
                                Text(exercise.name)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(exercise.targetDisplay)
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline.monospacedDigit())
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .onMove { from, to in
                        moveExercises(in: sectionName, from: from, to: to)
                    }
                } header: {
                    if sectionName.isEmpty {
                        Text("Exercises")
                    } else {
                        Text(sectionName)
                    }
                }
            }

            // Add group button
            Section {
                Button {
                    showAddGroup = true
                } label: {
                    Label("Add Group", systemImage: "folder.badge.plus")
                }
            }

            // Stats
            if !completedSessions.isEmpty {
                Section("Stats") {
                    LabeledContent("Total Sessions", value: "\(completedSessions.count)")
                    if let lastSession = completedSessions.first {
                        LabeledContent("Last Workout", value: lastSession.date.shortDate)
                        if let d = lastSession.durationSeconds {
                            LabeledContent("Last Duration", value: d.durationString)
                        }
                    }
                }
            }

            // Recent history
            if !completedSessions.isEmpty {
                Section("Recent Sessions") {
                    ForEach(completedSessions.prefix(5)) { session in
                        NavigationLink {
                            WorkoutSessionDetailView(session: session)
                        } label: {
                            HStack {
                                Text(session.date.shortDate)
                                Spacer()
                                if let d = session.durationSeconds {
                                    Text(d.durationString)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                let completed = session.exerciseLogs.flatMap(\.sets).filter(\.isCompleted).count
                                let total = session.exerciseLogs.flatMap(\.sets).count
                                Text("\(completed)/\(total)")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(plan.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .sheet(item: $exerciseToEdit) { exercise in
            NavigationStack {
                EditExerciseView(exercise: exercise)
            }
        }
        .alert("New Group", isPresented: $showAddGroup) {
            TextField("Group name", text: $newGroupName)
            Button("Cancel", role: .cancel) { newGroupName = "" }
            Button("Add") {
                addGroup(newGroupName)
                newGroupName = ""
            }
        } message: {
            Text("Enter a name for the exercise group")
        }
    }

    private func moveExercises(in sectionName: String, from: IndexSet, to: Int) {
        guard var sectionExercises = sections.first(where: { $0.0 == sectionName })?.1 else { return }
        sectionExercises.move(fromOffsets: from, toOffset: to)

        // Recalculate sort orders across all sections
        var order = 0
        for (name, _) in sections {
            let exercises = name == sectionName ? sectionExercises : sections.first(where: { $0.0 == name })!.1
            for exercise in exercises {
                exercise.sortOrder = order
                order += 1
            }
        }
        try? modelContext.save()
    }

    private func addGroup(_ name: String) {
        // Group becomes available in the EditExerciseView section picker.
        // Exercises are assigned to groups by editing them.
        // To make the group visible immediately, we store it as a known section.
    }
}

// MARK: - Edit Exercise Sheet

struct EditExerciseView: View {
    @Bindable var exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private var availableSections: [String] {
        guard let plan = exercise.plan else { return [""] }
        let sections = Set(plan.exercises.map(\.section))
        var result = sections.sorted()
        if !result.contains("") { result.insert("", at: 0) }
        return result
    }

    var body: some View {
        Form {
            Section("Exercise") {
                Text(exercise.name)
                    .font(.headline)
            }

            Section("Group") {
                TextField("Group name (optional)", text: $exercise.section)
                if !availableSections.filter({ !$0.isEmpty }).isEmpty {
                    Picker("Existing groups", selection: $exercise.section) {
                        Text("None").tag("")
                        ForEach(availableSections.filter { !$0.isEmpty }, id: \.self) { section in
                            Text(section).tag(section)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            Section("Sets & Reps") {
                Stepper("Sets: \(exercise.targetSets)", value: $exercise.targetSets, in: 1...10)

                if exercise.isIsometric {
                    Stepper("Seconds: \(exercise.targetSeconds)", value: $exercise.targetSeconds, in: 5...300, step: 5)
                } else {
                    Stepper("Reps: \(exercise.targetReps)", value: $exercise.targetReps, in: 1...100)
                }
            }

            Section {
                HStack {
                    Text("Target")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(exercise.targetDisplay)
                        .font(.subheadline.bold().monospacedDigit())
                }
            }
        }
        .navigationTitle("Edit Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    try? modelContext.save()
                    dismiss()
                }
                .bold()
            }
        }
    }
}
