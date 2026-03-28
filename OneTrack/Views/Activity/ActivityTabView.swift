import SwiftUI
import Charts

struct ActivityTabView: View {
    @State private var healthKit = HealthKitManager()
    @State private var weeklySteps: [(date: Date, steps: Int)] = []
    @State private var weeklyCalories: [(date: Date, calories: Double)] = []
    @State private var hasLoaded = false

    private var dailyActivity: [ActivityCalculations.DailyActivity] {
        ActivityCalculations.dailyActivity(dailySteps: weeklySteps, dailyCalories: weeklyCalories)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if !healthKit.isAvailable {
                        unavailableView
                    } else if !healthKit.isAuthorized && hasLoaded {
                        unauthorizedView
                    } else {
                        todayCards
                        stepsChart
                        caloriesChart
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Activity")
            .task {
                if !hasLoaded {
                    await healthKit.requestAuthorization()
                    await loadWeeklyData()
                    hasLoaded = true
                }
            }
            .refreshable {
                await healthKit.fetchAll()
                await loadWeeklyData()
            }
        }
    }

    // MARK: - Today Cards

    private var todayCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "Steps Today",
                value: ActivityCalculations.formattedSteps(healthKit.todaySteps),
                icon: "figure.walk",
                color: .green
            )
            StatCard(
                title: "Active Cal",
                value: ActivityCalculations.formattedCalories(healthKit.todayActiveCalories),
                icon: "flame.fill",
                color: .orange
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Steps Chart

    private var stepsChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Steps (7 Days)")
                .font(.subheadline.bold())

            if dailyActivity.isEmpty || dailyActivity.allSatisfy({ $0.steps == 0 }) {
                chartPlaceholder("Step data will appear here")
            } else {
                Chart(dailyActivity) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Steps", day.steps)
                    )
                    .foregroundStyle(.green.gradient)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text(v >= 1000 ? String(format: "%.0fk", Double(v) / 1000) : "\(v)")
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 150)
            }
        }
        .cardStyle()
        .padding(.horizontal)
    }

    // MARK: - Calories Chart

    private var caloriesChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Calories (7 Days)")
                .font(.subheadline.bold())

            if dailyActivity.isEmpty || dailyActivity.allSatisfy({ $0.calories == 0 }) {
                chartPlaceholder("Calorie data will appear here")
            } else {
                Chart(dailyActivity) { day in
                    BarMark(
                        x: .value("Day", day.date, unit: .day),
                        y: .value("Calories", day.calories)
                    )
                    .foregroundStyle(.orange.gradient)
                    .cornerRadius(4)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { _ in
                        AxisValueLabel(format: .dateTime.weekday(.narrow))
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
        }
        .cardStyle()
        .padding(.horizontal)
    }

    // MARK: - States

    private var unavailableView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "heart.slash")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("HealthKit Not Available")
                .font(.title3.bold())
            Text("Activity tracking requires an iPhone with Apple Health.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var unauthorizedView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(.orange.opacity(0.5))
            Text("Health Access Required")
                .font(.title3.bold())
            Text("OneTrack needs access to Apple Health to show your steps and calories.\n\nGo to Settings > Health > Data Access > OneTrack to enable.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                Task { await healthKit.requestAuthorization() }
            } label: {
                Label("Request Access", systemImage: "heart.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue, in: Capsule())
            }
            Spacer()
        }
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

    // MARK: - Data Loading

    private func loadWeeklyData() async {
        weeklySteps = await healthKit.fetchWeeklySteps()
        weeklyCalories = await healthKit.fetchWeeklyCalories()
    }
}
