import SwiftUI
import SwiftData

struct WorkoutPlanDetailView: View {
    let plan: WorkoutPlan

    private var sortedExercises: [Exercise] {
        plan.exercises.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var completedSessions: [WorkoutSession] {
        plan.sessions.filter(\.isCompleted).sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            // Exercises
            Section("Exercises") {
                ForEach(Array(sortedExercises.enumerated()), id: \.element.id) { index, exercise in
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(.blue, in: Circle())

                        Text(exercise.name)

                        Spacer()

                        Text("\(exercise.targetSets) x \(exercise.targetReps)")
                            .foregroundStyle(.secondary)
                            .font(.subheadline.monospacedDigit())
                    }
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
    }
}
