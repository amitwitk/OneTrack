import SwiftUI
import SwiftData

struct WorkoutPlanDetailView: View {
    let plan: WorkoutPlan
    @Environment(\.modelContext) private var modelContext
    @State private var exerciseToEdit: Exercise?

    private var sortedExercises: [Exercise] {
        plan.exercises.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var completedSessions: [WorkoutSession] {
        plan.sessions.filter(\.isCompleted).sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            Section("Exercises") {
                ForEach(sortedExercises) { exercise in
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
                    var exercises = sortedExercises
                    exercises.move(fromOffsets: from, toOffset: to)
                    for (index, exercise) in exercises.enumerated() {
                        exercise.sortOrder = index
                    }
                    try? modelContext.save()
                }
            }

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
    }
}

// MARK: - Edit Exercise Sheet

struct EditExerciseView: View {
    @Bindable var exercise: Exercise
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Form {
            Section("Exercise") {
                Text(exercise.name)
                    .font(.headline)
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
