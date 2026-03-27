import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(filter: #Predicate<WorkoutSession> { $0.isCompleted },
           sort: \WorkoutSession.date, order: .reverse)
    private var recentSessions: [WorkoutSession]

    private var thisWeekCount: Int { DashboardCalculations.thisWeekCount(sessions: recentSessions) }
    private var totalVolume: String { DashboardCalculations.totalVolume(sessions: recentSessions) }
    private var streakDays: Int { DashboardCalculations.streakDays(sessions: recentSessions) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(greetingText)
                                .font(.title2.bold())
                            Text(Date.now.formatted(.dateTime.weekday(.wide).month().day()))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if streakDays > 0 {
                            VStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.title2)
                                    .foregroundStyle(.orange)
                                Text("\(streakDays)")
                                    .font(.caption.bold())
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(
                            title: "This Week",
                            value: "\(thisWeekCount)",
                            icon: "dumbbell.fill",
                            color: .blue
                        )
                        StatCard(
                            title: "Volume (kg)",
                            value: totalVolume,
                            icon: "scalemass.fill",
                            color: .purple
                        )
                        StatCard(
                            title: "Total Workouts",
                            value: "\(recentSessions.count)",
                            icon: "trophy.fill",
                            color: .orange
                        )
                        StatCard(
                            title: "Streak",
                            value: streakDays > 0 ? "\(streakDays) days" : "--",
                            icon: "flame.fill",
                            color: .red
                        )
                    }
                    .padding(.horizontal)

                    // Recent Workouts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Workouts")
                            .font(.headline)
                            .padding(.horizontal)

                        if recentSessions.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.largeTitle)
                                    .foregroundStyle(.tertiary)
                                Text("No workouts yet")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text("Start your first workout from the Workouts tab")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        } else {
                            ForEach(recentSessions.prefix(5)) { session in
                                recentSessionRow(session)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("OneTrack")
        }
    }

    private func recentSessionRow(_ session: WorkoutSession) -> some View {
        let completedSets = session.exerciseLogs.flatMap(\.sets).filter(\.isCompleted).count
        let totalSets = session.exerciseLogs.flatMap(\.sets).count

        return HStack(spacing: 14) {
            Image(systemName: "dumbbell.fill")
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
                .background(.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(session.plan?.name ?? "Workout")
                    .font(.subheadline.bold())
                HStack(spacing: 8) {
                    Text(session.date.relativeDay)
                    if let d = session.durationSeconds {
                        Text(d.durationString)
                    }
                    Text("\(completedSets)/\(totalSets) sets")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        .padding(.horizontal)
    }

    private var greetingText: String { DashboardCalculations.greeting() }
}
