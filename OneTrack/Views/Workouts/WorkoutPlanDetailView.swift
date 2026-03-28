import SwiftUI
import SwiftData

struct WorkoutPlanDetailView: View {
    let plan: WorkoutPlan
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    @State private var exerciseToEdit: Exercise?

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
        // Include known empty groups
        for group in plan.knownGroups {
            if !sectionOrder.contains(group) {
                sectionOrder.append(group)
            }
        }
        return sectionOrder.map { section in
            (section, grouped[section] ?? [])
        }
    }

    private var completedSessions: [WorkoutSession] {
        plan.sessions.filter(\.isCompleted).sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            ForEach(sections, id: \.0) { sectionName, exercises in
                Section {
                    if exercises.isEmpty {
                        Text("No exercises")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    } else {
                        ForEach(exercises) { exercise in
                            exerciseRow(exercise)
                        }
                        .onMove { from, to in
                            PlanManagement.reorderExercises(
                                allExercises: Array(plan.exercises),
                                inSection: sectionName,
                                from: from,
                                to: to
                            )
                            try? modelContext.save()
                        }
                        .onDelete { offsets in
                            let toDelete = PlanManagement.deleteExercises(
                                allExercises: Array(plan.exercises),
                                inSection: sectionName,
                                at: offsets
                            )
                            for exercise in toDelete {
                                modelContext.delete(exercise)
                            }
                            try? modelContext.save()
                        }
                    }
                } header: {
                    if sectionName.isEmpty {
                        Text("Exercises")
                    } else {
                        Text(sectionName)
                    }
                }
            }

            // Add group
            Section {
                addGroupButton
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

            // Recent sessions
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
                EditExerciseView(exercise: exercise, knownGroups: plan.knownGroups)
            }
        }
    }

    // MARK: - Exercise Row

    private func exerciseRow(_ exercise: Exercise) -> some View {
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

    // MARK: - Add Group

    @State private var showAddGroup = false
    @State private var newGroupName = ""

    private var addGroupButton: some View {
        Button {
            showAddGroup = true
        } label: {
            Label("Add Group", systemImage: "folder.badge.plus")
        }
        .alert("New Group", isPresented: $showAddGroup) {
            TextField("Group name", text: $newGroupName)
            Button("Cancel", role: .cancel) { newGroupName = "" }
            Button("Add") {
                let trimmed = newGroupName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    var groups = plan.knownGroups
                    if !groups.contains(trimmed) {
                        groups.append(trimmed)
                        plan.knownGroups = groups
                        try? modelContext.save()
                    }
                }
                newGroupName = ""
            }
        } message: {
            Text("Enter a name for the exercise group")
        }
    }
}

// MARK: - Edit Exercise Sheet

struct EditExerciseView: View {
    @Bindable var exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let knownGroups: [String]

    private var availableSections: [String] {
        guard let plan = exercise.plan else { return knownGroups }
        let usedSections = Set(plan.exercises.map(\.section))
        let all = Set(knownGroups).union(usedSections)
        return all.sorted()
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
