import SwiftUI
import SwiftData
import Charts

struct ActivityTabView: View {
    var healthKit: HealthKitManager

    @State private var dailySteps: [(date: Date, steps: Int)] = []
    @State private var dailyCalories: [(date: Date, calories: Double)] = []
    @State private var streakSteps: [(date: Date, steps: Int)] = [] // 30 days for streak calc
    @State private var hasLoaded = false
    @State private var chartRange: ActivityChartRange = .week

    @Query(filter: #Predicate<WorkoutSession> { $0.isCompleted },
           sort: \WorkoutSession.date, order: .reverse)
    private var completedSessions: [WorkoutSession]

    @AppStorage("dailyStepGoal") private var stepGoal: Int = 10000
    @AppStorage("dailyCalorieGoal") private var calorieGoal: Int = 500

    private var dailyActivity: [ActivityCalculations.DailyActivity] {
        let displayDays = chartRange == .week ? 7 : 30
        let stepsSlice = Array(dailySteps.suffix(displayDays))
        let calsSlice = Array(dailyCalories.suffix(displayDays))
        return ActivityCalculations.dailyActivity(dailySteps: stepsSlice, dailyCalories: calsSlice)
    }

    private var streak: Int {
        ActivityCalculations.streakDays(dailySteps: streakSteps, goal: stepGoal)
    }

    private var stepsComparison: ActivityCalculations.WeekComparison {
        let (thisWeek, lastWeek) = ActivityCalculations.splitWeeks(
            data: dailySteps.map { (date: $0.date, value: $0.steps) }
        )
        return ActivityCalculations.weekOverWeekChange(thisWeek: thisWeek, lastWeek: lastWeek)
    }

    private var caloriesComparison: ActivityCalculations.WeekComparison {
        let (thisWeek, lastWeek) = ActivityCalculations.splitWeeks(
            data: dailyCalories.map { (date: $0.date, value: Int($0.calories)) }
        )
        return ActivityCalculations.weekOverWeekChange(thisWeek: thisWeek, lastWeek: lastWeek)
    }

    private var workoutDates: Set<Date> {
        let calendar = Calendar.current
        return Set(completedSessions.map { calendar.startOfDay(for: $0.date) })
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
                        if streak > 0 { streakCard }
                        chartRangePicker
                        stepsChart
                        caloriesChart
                        goalsSection
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Activity")
            .task {
                if !hasLoaded || healthKit.isStale {
                    if !healthKit.isAuthorized {
                        await healthKit.requestAuthorization()
                    }
                    await loadData()
                    hasLoaded = true
                }
            }
            .refreshable {
                await healthKit.fetchAll()
                await loadData()
            }
            .onChange(of: chartRange) {
                Task { await loadData() }
            }
        }
    }

    // MARK: - Today Cards with Progress Rings

    private var todayCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            goalCard(
                title: "Steps",
                current: healthKit.todaySteps,
                goal: stepGoal,
                formatted: ActivityCalculations.formattedSteps(healthKit.todaySteps),
                icon: "figure.walk",
                color: .green
            )
            goalCard(
                title: "Active Cal",
                current: Int(healthKit.todayActiveCalories),
                goal: calorieGoal,
                formatted: ActivityCalculations.formattedCalories(healthKit.todayActiveCalories),
                icon: "flame.fill",
                color: .orange
            )
        }
        .padding(.horizontal)
    }

    private func goalCard(title: String, current: Int, goal: Int, formatted: String, icon: String, color: Color) -> some View {
        let progress = ActivityCalculations.goalProgress(current: current, goal: goal)
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(color.opacity(0.15), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(color)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    Text(formatted)
                        .font(.title3.bold().monospacedDigit())
                    Text("/ \(ActivityCalculations.formattedSteps(goal))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(streak) day streak")
                    .font(.subheadline.bold())
                Text("Meeting your \(ActivityCalculations.formattedSteps(stepGoal)) step goal")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .cardStyle()
        .padding(.horizontal)
    }

    // MARK: - Chart Range Picker

    private var chartRangePicker: some View {
        Picker("Range", selection: $chartRange) {
            ForEach(ActivityChartRange.allCases) { range in
                Text(range.label).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }

    // MARK: - Steps Chart

    private var stepsChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Steps (\(chartRange.label))")
                .font(.subheadline.bold())

            if dailyActivity.isEmpty || dailyActivity.allSatisfy({ $0.steps == 0 }) {
                chartPlaceholder("Step data will appear here")
            } else {
                Chart {
                    ForEach(dailyActivity) { day in
                        BarMark(
                            x: .value("Day", day.date, unit: .day),
                            y: .value("Steps", day.steps)
                        )
                        .foregroundStyle(.green.gradient)
                        .cornerRadius(chartRange == .month ? 2 : 4)
                    }
                    // Workout day indicators
                    ForEach(dailyActivity.filter { workoutDates.contains(Calendar.current.startOfDay(for: $0.date)) }) { day in
                        PointMark(
                            x: .value("Day", day.date, unit: .day),
                            y: .value("Steps", 0)
                        )
                        .symbolSize(20)
                        .foregroundStyle(.blue)
                        .annotation(position: .bottom, spacing: 2) {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: chartRange == .month ? 5 : 1)) { _ in
                        AxisValueLabel(format: chartRange == .month ? .dateTime.day() : .dateTime.weekday(.narrow))
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

            comparisonText(stepsComparison)
        }
        .cardStyle()
        .padding(.horizontal)
    }

    // MARK: - Calories Chart

    private var caloriesChart: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Calories (\(chartRange.label))")
                .font(.subheadline.bold())

            if dailyActivity.isEmpty || dailyActivity.allSatisfy({ $0.calories == 0 }) {
                chartPlaceholder("Calorie data will appear here")
            } else {
                Chart {
                    ForEach(dailyActivity) { day in
                        BarMark(
                            x: .value("Day", day.date, unit: .day),
                            y: .value("Calories", day.calories)
                        )
                        .foregroundStyle(.orange.gradient)
                        .cornerRadius(chartRange == .month ? 2 : 4)
                    }
                    ForEach(dailyActivity.filter { workoutDates.contains(Calendar.current.startOfDay(for: $0.date)) }) { day in
                        PointMark(
                            x: .value("Day", day.date, unit: .day),
                            y: .value("Calories", 0)
                        )
                        .symbolSize(20)
                        .foregroundStyle(.blue)
                        .annotation(position: .bottom, spacing: 2) {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(.blue)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: chartRange == .month ? 5 : 1)) { _ in
                        AxisValueLabel(format: chartRange == .month ? .dateTime.day() : .dateTime.weekday(.narrow))
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

            comparisonText(caloriesComparison)
        }
        .cardStyle()
        .padding(.horizontal)
    }

    // MARK: - Comparison Text

    private func comparisonText(_ comparison: ActivityCalculations.WeekComparison) -> some View {
        Group {
            switch comparison.direction {
            case "up":
                Label("↑ \(Int(comparison.percentage))% vs last week", systemImage: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.green)
            case "down":
                Label("↓ \(Int(abs(comparison.percentage)))% vs last week", systemImage: "arrow.down.right")
                    .font(.caption)
                    .foregroundStyle(.red)
            default:
                Text("— same as last week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Goals Section

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Goals")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 12) {
                HStack {
                    Text("Daily Steps")
                        .font(.subheadline)
                    Spacer()
                    Stepper(
                        ActivityCalculations.formattedSteps(stepGoal),
                        value: $stepGoal,
                        in: 1000...50000,
                        step: 1000
                    )
                    .font(.subheadline.monospacedDigit())
                }

                HStack {
                    Text("Active Calories")
                        .font(.subheadline)
                    Spacer()
                    Stepper(
                        "\(calorieGoal) cal",
                        value: $calorieGoal,
                        in: 100...2000,
                        step: 50
                    )
                    .font(.subheadline.monospacedDigit())
                }
            }
            .cardStyle()
            .padding(.horizontal)
        }
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

    private func loadData() async {
        let fetchDays = max(chartRange.days, 14) // at least 14 for week comparison
        dailySteps = await healthKit.fetchDailySteps(days: fetchDays)
        dailyCalories = await healthKit.fetchDailyCalories(days: fetchDays)
        streakSteps = await healthKit.fetchDailySteps(days: 30)
    }
}

// MARK: - Chart Range

enum ActivityChartRange: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"

    var id: String { rawValue }
    var label: String { rawValue }

    var days: Int {
        switch self {
        case .week: 7
        case .month: 30
        }
    }
}
