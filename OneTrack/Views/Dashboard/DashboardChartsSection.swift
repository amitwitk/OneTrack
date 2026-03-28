import SwiftUI
import Charts

struct DashboardChartsSection: View {
    let sessions: [WorkoutSession]
    let weightEntries: [WeightEntry]

    private var dailyVolume: [DashboardCalculations.DailyVolume] {
        DashboardCalculations.dailyVolume(sessions: sessions)
    }

    private var weeklyFrequency: [DashboardCalculations.WeeklyFrequency] {
        DashboardCalculations.weeklyFrequency(sessions: sessions)
    }

    private var weightTrend: [DashboardCalculations.WeightPoint] {
        DashboardCalculations.weightTrend(entries: weightEntries, days: 90)
    }

    private var hasVolumeData: Bool {
        dailyVolume.contains { $0.volume > 0 }
    }

    private var hasFrequencyData: Bool {
        weeklyFrequency.contains { $0.count > 0 }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Weekly Volume Chart
            chartCard(title: "Weekly Volume (kg)") {
                if hasVolumeData {
                    volumeChart
                } else {
                    chartPlaceholder("Log a workout to see volume trends")
                }
            }

            // Monthly Frequency Chart
            chartCard(title: "Monthly Frequency") {
                if hasFrequencyData {
                    frequencyChart
                } else {
                    chartPlaceholder("Complete workouts to see frequency")
                }
            }

            // Weight Trend Chart
            chartCard(title: "Weight Trend") {
                if !weightTrend.isEmpty {
                    weightChart
                } else {
                    chartPlaceholder("Log weight to see your trend")
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Volume Chart

    private var volumeChart: some View {
        Chart(dailyVolume) { point in
            BarMark(
                x: .value("Day", point.date, unit: .day),
                y: .value("Volume", point.volume)
            )
            .foregroundStyle(.blue.gradient)
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { value in
                AxisValueLabel(format: .dateTime.weekday(.narrow))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(v >= 1000 ? String(format: "%.0fk", v / 1000) : "\(Int(v))")
                            .font(.caption2)
                    }
                }
            }
        }
        .frame(height: 150)
    }

    // MARK: - Frequency Chart

    private var frequencyChart: some View {
        Chart(weeklyFrequency) { week in
            BarMark(
                x: .value("Week", week.weekStart, unit: .weekOfYear),
                y: .value("Workouts", week.count)
            )
            .foregroundStyle(.orange.gradient)
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .frame(height: 150)
    }

    // MARK: - Weight Chart

    private var weightChart: some View {
        Chart(weightTrend) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Weight", point.weightKg)
            )
            .foregroundStyle(.green)
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("Date", point.date),
                y: .value("Weight", point.weightKg)
            )
            .foregroundStyle(.green)
            .symbolSize(20)
        }
        .chartYScale(domain: weightYDomain)
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(String(format: "%.0f", v))
                            .font(.caption2)
                    }
                }
            }
        }
        .frame(height: 150)
    }

    private var weightYDomain: ClosedRange<Double> {
        let weights = weightTrend.map(\.weightKg)
        let minW = (weights.min() ?? 0) - 2
        let maxW = (weights.max() ?? 100) + 2
        return minW...maxW
    }

    // MARK: - Helpers

    private func chartCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
            content()
        }
        .cardStyle()
    }

    private func chartPlaceholder(_ message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.title3)
                .foregroundStyle(.tertiary)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }
}
