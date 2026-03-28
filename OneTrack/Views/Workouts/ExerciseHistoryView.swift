import SwiftUI
import SwiftData
import Charts

struct ExerciseHistoryView: View {
    let exerciseName: String
    @Environment(\.dismiss) private var dismiss

    @Query(filter: #Predicate<WorkoutSession> { $0.isCompleted },
           sort: \WorkoutSession.date, order: .reverse)
    private var sessions: [WorkoutSession]

    @State private var showVolume = false

    private var history: [ExerciseHistoryEntry] {
        ExerciseHistoryCalculations.extractHistory(
            exerciseName: exerciseName,
            sessions: sessions
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if history.isEmpty {
                        emptyState
                    } else {
                        chartSection
                        statsSection
                        historyList
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(exerciseName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(showVolume ? "Volume Progression" : "Weight Progression")
                    .font(.headline)
                Spacer()
                Picker("", selection: $showVolume) {
                    Text("Weight").tag(false)
                    Text("Volume").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 160)
            }
            .padding(.horizontal)

            Chart(history) { entry in
                LineMark(
                    x: .value("Date", entry.date),
                    y: .value(showVolume ? "Volume" : "Weight",
                             showVolume ? entry.totalVolume : entry.maxWeight)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("Date", entry.date),
                    y: .value(showVolume ? "Volume" : "Weight",
                             showVolume ? entry.totalVolume : entry.maxWeight)
                )
                .foregroundStyle(.blue)
                .symbolSize(30)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            if showVolume && v >= 1000 {
                                Text(String(format: "%.0fk", v / 1000))
                                    .font(.caption2)
                            } else {
                                Text(String(format: "%.0f", v))
                                    .font(.caption2)
                            }
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding(.horizontal)
        }
        .cardStyle()
        .padding(.horizontal)
    }

    // MARK: - Stats Summary

    private var statsSection: some View {
        let allTimeMax = history.map(\.maxWeight).max() ?? 0
        let latestVolume = history.last?.totalVolume ?? 0
        let sessionCount = history.count

        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            miniStat("Max Weight", value: allTimeMax.formattedWeight, icon: "trophy.fill")
            miniStat("Latest Vol.", value: formatVolume(latestVolume), icon: "scalemass.fill")
            miniStat("Sessions", value: "\(sessionCount)", icon: "calendar")
        }
        .padding(.horizontal)
    }

    private func miniStat(_ title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold().monospacedDigit())
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    // MARK: - History List

    private var historyList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Session History")
                .font(.headline)
                .padding(.horizontal)

            ForEach(history.reversed()) { entry in
                HStack {
                    Text(entry.date.shortDate)
                        .font(.subheadline)
                    Spacer()
                    Text(entry.maxWeight.compactWeight)
                        .font(.subheadline.monospacedDigit().bold())
                    Text("\(entry.totalSets) sets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatVolume(entry.totalVolume))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No History Yet")
                .font(.title3.bold())
            Text("Complete workouts with this exercise to see progression data.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private func formatVolume(_ volume: Double) -> String {
        volume >= 1000 ? String(format: "%.1fk", volume / 1000) : "\(Int(volume))kg"
    }
}
