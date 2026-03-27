import SwiftUI
import SwiftData

struct WorkoutSessionDetailView: View {
    let session: WorkoutSession

    private var sortedLogs: [ExerciseLog] {
        session.exerciseLogs.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Date", value: session.date.shortDateTime)
                if let duration = session.durationSeconds {
                    LabeledContent("Duration", value: duration.durationString)
                }
            }

            ForEach(sortedLogs) { log in
                Section(log.exerciseName) {
                    ForEach(log.sets.sorted { $0.setNumber < $1.setNumber }) { setLog in
                        HStack {
                            Text("Set \(setLog.setNumber)")
                                .font(.subheadline)
                            Spacer()
                            Text("\(setLog.reps) reps")
                                .monospacedDigit()
                            Text("@")
                                .foregroundStyle(.secondary)
                            Text(setLog.weightKg.formattedWeight)
                                .monospacedDigit()
                            Image(systemName: setLog.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(setLog.isCompleted ? .green : .gray)
                        }
                    }
                }
            }
        }
        .navigationTitle(session.plan?.name ?? "Workout")
    }
}
