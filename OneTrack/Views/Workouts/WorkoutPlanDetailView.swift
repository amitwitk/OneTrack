import SwiftUI
import SwiftData

struct WorkoutPlanDetailView: View {
    @Bindable var plan: WorkoutPlan
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    @State private var exerciseToEdit: Exercise?
    @State private var showAddGroup = false
    @State private var newGroupName = ""
    @State private var showExercisePicker = false
    @State private var flatList: [PlanListItem] = []
    @State private var groupToDelete: String?
    @State private var showDeleteGroupConfirmation = false

    private var completedSessions: [WorkoutSession] {
        plan.sessions.filter(\.isCompleted).sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            // Flat list of headers + exercises
            Section {
                ForEach(flatList) { item in
                    switch item {
                    case .sectionHeader(let name):
                        sectionHeaderRow(name)
                            .moveDisabled(true)
                    case .exercise(let exercise):
                        exerciseRow(exercise)
                    }
                }
                .onMove(perform: moveItems)
                .onDelete(perform: deleteItems)
            }

            // Actions
            Section {
                Button {
                    showExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus.circle.fill")
                }

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
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(plan.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .onAppear { rebuildFlatList() }
        .onChange(of: plan.exercises.count) { rebuildFlatList() }
        .sheet(item: $exerciseToEdit) { exercise in
            NavigationStack {
                EditExerciseView(exercise: exercise, plan: plan)
            }
            .onDisappear { rebuildFlatList() }
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerView { templates in
                addExercises(templates)
            }
        }
        .alert("New Group", isPresented: $showAddGroup) {
            TextField("Group name", text: $newGroupName)
            Button("Cancel", role: .cancel) { newGroupName = "" }
            Button("Add") {
                addGroup(newGroupName.trimmingCharacters(in: .whitespaces))
                newGroupName = ""
            }
        } message: {
            Text("Enter a name for the exercise group")
        }
        .confirmationDialog(
            "Delete Group?",
            isPresented: $showDeleteGroupConfirmation,
            presenting: groupToDelete
        ) { name in
            Button("Delete Group & Exercises", role: .destructive) {
                deleteGroupWithExercises(name)
            }
            Button("Cancel", role: .cancel) {
                groupToDelete = nil
                rebuildFlatList()
            }
        } message: { name in
            let count = plan.exercises.filter { $0.section == name }.count
            Text("This will delete the \"\(name.isEmpty ? "Exercises" : name)\" group and its \(count) exercise\(count == 1 ? "" : "s").")
        }
    }

    // MARK: - Rows

    private func sectionHeaderRow(_ name: String) -> some View {
        let hasExercises = plan.exercises.contains { $0.section == name }

        return HStack {
            Image(systemName: "folder.fill")
                .font(.caption)
                .foregroundStyle(.blue)
            Text(name.isEmpty ? "Exercises" : name)
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)
            Spacer()
            if !hasExercises {
                Image(systemName: "xmark.circle")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .listRowBackground(Color(.systemGroupedBackground))
        .contextMenu {
            Button(role: .destructive) {
                if hasExercises {
                    groupToDelete = name
                    showDeleteGroupConfirmation = true
                } else {
                    deleteGroup(name)
                }
            } label: {
                Label(hasExercises ? "Delete Group & Exercises" : "Delete Group", systemImage: "trash")
            }
        }
    }

    private func deleteGroup(_ name: String) {
        plan.knownGroups.removeAll { $0 == name }
        try? modelContext.save()
        rebuildFlatList()
    }

    private func deleteGroupWithExercises(_ name: String) {
        for exercise in plan.exercises where exercise.section == name {
            modelContext.delete(exercise)
        }
        plan.knownGroups.removeAll { $0 == name }
        try? modelContext.save()
        groupToDelete = nil
        rebuildFlatList()
    }

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

    // MARK: - Actions

    private func rebuildFlatList() {
        flatList = PlanManagement.buildFlatList(
            exercises: Array(plan.exercises),
            knownGroups: plan.knownGroups
        )
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        PlanManagement.applyMove(flatList: &flatList, from: source, to: destination)
        // Sync knownGroups from current headers
        plan.knownGroups = flatList.compactMap {
            if case .sectionHeader(let name) = $0 { return name }
            return nil
        }
        try? modelContext.save()
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            switch flatList[index] {
            case .exercise(let exercise):
                modelContext.delete(exercise)
                flatList.remove(at: index)
                PlanManagement.reassignSectionsAndOrder(flatList: flatList)
                try? modelContext.save()
            case .sectionHeader(let name):
                let hasExercises = plan.exercises.contains { $0.section == name }
                if hasExercises {
                    groupToDelete = name
                    showDeleteGroupConfirmation = true
                } else {
                    deleteGroup(name)
                    flatList.remove(at: index)
                }
            }
        }
    }

    private func addExercises(_ templates: [ExerciseTemplate]) {
        let maxOrder = plan.exercises.map(\.sortOrder).max() ?? -1
        // Determine which section to add to (last non-empty section, or "")
        let lastSection = flatList.reversed().first(where: {
            if case .sectionHeader = $0 { return true }
            return false
        })
        let section: String
        if case .sectionHeader(let name) = lastSection {
            section = name
        } else {
            section = ""
        }

        for (i, template) in templates.enumerated() {
            let exercise = Exercise(
                name: template.name,
                targetSets: template.defaultSets,
                targetReps: template.defaultReps,
                sortOrder: maxOrder + 1 + i,
                isIsometric: template.isIsometric,
                targetSeconds: template.defaultSeconds,
                section: section
            )
            exercise.plan = plan
            modelContext.insert(exercise)
        }
        try? modelContext.save()
        rebuildFlatList()
    }

    private func addGroup(_ name: String) {
        guard !name.isEmpty else { return }
        if !plan.knownGroups.contains(name) {
            plan.knownGroups.append(name)
        }
        try? modelContext.save()
        rebuildFlatList()
    }
}

// MARK: - Edit Exercise Sheet

struct EditExerciseView: View {
    @Bindable var exercise: Exercise
    let plan: WorkoutPlan
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var customGroupName = ""

    private var availableSections: [String] {
        var sections = Set(plan.exercises.map(\.section))
        for group in plan.knownGroups {
            sections.insert(group)
        }
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
                Picker("Group", selection: $exercise.section) {
                    Text("None").tag("")
                    ForEach(availableSections.filter { !$0.isEmpty }, id: \.self) { section in
                        Text(section).tag(section)
                    }
                }

                HStack {
                    TextField("New group name", text: $customGroupName)
                    Button("Set") {
                        let name = customGroupName.trimmingCharacters(in: .whitespaces)
                        guard !name.isEmpty else { return }
                        exercise.section = name
                        if !plan.knownGroups.contains(name) {
                            plan.knownGroups.append(name)
                        }
                        customGroupName = ""
                    }
                    .disabled(customGroupName.trimmingCharacters(in: .whitespaces).isEmpty)
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
