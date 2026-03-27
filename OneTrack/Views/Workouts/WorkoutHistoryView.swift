import SwiftUI
import SwiftData

struct WorkoutHistoryView: View {
    @Query(filter: #Predicate<WorkoutSession> { $0.isCompleted },
           sort: \WorkoutSession.date, order: .reverse)
    private var sessions: [WorkoutSession]

    var body: some View {
        Group {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No Workouts Yet",
                    systemImage: "dumbbell",
                    description: Text("Complete a workout to see it here.")
                )
            } else {
                List(sessions) { session in
                    NavigationLink {
                        WorkoutSessionDetailView(session: session)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(session.plan?.name ?? "Workout")
                                    .font(.headline)
                                Spacer()
                                if let duration = session.durationSeconds {
                                    Text(duration.durationString)
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Text(session.date.shortDateTime)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            let completedSets = session.exerciseLogs.flatMap(\.sets).filter(\.isCompleted).count
                            let totalSets = session.exerciseLogs.flatMap(\.sets).count
                            Text("\(completedSets)/\(totalSets) sets completed")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
        }
    }
}
