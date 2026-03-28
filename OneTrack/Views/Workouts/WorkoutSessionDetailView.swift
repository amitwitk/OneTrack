import SwiftUI
import SwiftData

struct WorkoutSessionDetailView: View {
    let session: WorkoutSession

    @State private var exerciseForHistory: String?

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
                if let rpe = session.rpe {
                    LabeledContent("RPE", value: "\(rpe)/10")
                }
            }

            ForEach(sortedLogs) { log in
                Section {
                    // Notes
                    if !log.notes.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "note.text")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(log.notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    ForEach(log.sets.sorted { $0.setNumber < $1.setNumber }) { setLog in
                        HStack {
                            setTypeBadge(setLog)

                            if setLog.isPersonalRecord {
                                Image(systemName: "trophy.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                            }
                            Spacer()
                            Text(log.isIsometric ? "\(setLog.seconds)s" : "\(setLog.reps) reps")
                                .monospacedDigit()
                            Text("@")
                                .foregroundStyle(.secondary)
                            Text(setLog.weightKg.formattedWeight)
                                .monospacedDigit()
                            Image(systemName: setLog.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(setLog.isCompleted ? .green : .gray)
                        }
                    }
                } header: {
                    Button {
                        exerciseForHistory = log.exerciseName
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(log.exerciseName)
                                Image(systemName: "chart.xyaxis.line")
                                    .font(.caption2)
                                    .foregroundStyle(.blue)
                            }
                            if !log.swappedFromExercise.isEmpty {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.triangle.swap")
                                        .font(.caption2)
                                    Text("from \(log.swappedFromExercise)")
                                        .font(.caption2)
                                }
                                .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(session.plan?.name ?? "Workout")
        .sheet(item: Binding(
            get: { exerciseForHistory.map { HistorySheetID(name: $0) } },
            set: { exerciseForHistory = $0?.name }
        )) { item in
            ExerciseHistoryView(exerciseName: item.name)
        }
    }

    @ViewBuilder
    private func setTypeBadge(_ setLog: SetLog) -> some View {
        switch setLog.setType {
        case .warmUp:
            Text("W")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(.gray.opacity(0.5), in: Circle())
        case .dropSet:
            Text("D")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(.orange, in: Circle())
        case .toFailure:
            Text("F")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(.red, in: Circle())
        case .normal:
            Text("Set \(setLog.setNumber)")
                .font(.subheadline)
        }
    }
}

private struct HistorySheetID: Identifiable {
    let name: String
    var id: String { name }
}
