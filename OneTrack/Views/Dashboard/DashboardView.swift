import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(filter: #Predicate<WorkoutSession> { $0.isCompleted },
           sort: \WorkoutSession.date, order: .reverse)
    private var recentSessions: [WorkoutSession]

    private var thisWeekCount: Int {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        return recentSessions.filter { $0.date >= weekAgo }.count
    }

    private var totalVolume: String {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
        let volume = recentSessions
            .filter { $0.date >= weekAgo }
            .flatMap(\.exerciseLogs)
            .flatMap(\.sets)
            .filter(\.isCompleted)
            .reduce(0.0) { $0 + Double($1.reps) * $1.weightKg }
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return "\(Int(volume))"
    }

    private var streakDays: Int {
        guard !recentSessions.isEmpty else { return 0 }
        var streak = 0
        var checkDate = Calendar.current.startOfDay(for: .now)
        let calendar = Calendar.current
        while true {
            let hasWorkout = recentSessions.contains { calendar.isDate($0.date, inSameDayAs: checkDate) }
            if hasWorkout {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        return streak
    }

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

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }
}
