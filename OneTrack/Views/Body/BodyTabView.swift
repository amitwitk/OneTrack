import SwiftUI
import SwiftData
import Charts

struct BodyTabView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \WeightEntry.date, order: .reverse)
    private var weightEntries: [WeightEntry]

    @Query(sort: \BodyMeasurement.date, order: .reverse)
    private var measurements: [BodyMeasurement]

    @State private var healthKitManager = HealthKitManager()

    // Weight entry — defaults loaded from last entry
    @State private var weightValue: Double = 75.0

    // Measurement entry — defaults loaded from last entry
    @State private var waistValue: Double = 80.0
    @State private var chestValue: Double = 95.0
    @State private var leftBicepValue: Double = 32.0
    @State private var rightBicepValue: Double = 32.0
    @State private var logWaist = false
    @State private var logChest = false
    @State private var logLeftBicep = false
    @State private var logRightBicep = false
    @State private var measurementNotes: String = ""

    // Chart
    @State private var chartRange: ChartRange = .thirtyDays

    // HealthKit
    @State private var showHealthKitDenied = false

    // Collapsible sections
    @State private var showRecentWeights = false
    @State private var showRecentMeasurements = false
    @State private var hasLoadedDefaults = false

    private var currentWeight: Double? {
        BodyCalculations.currentWeight(entries: weightEntries)
    }

    private var weeklyChange: Double? {
        BodyCalculations.weeklyChange(entries: weightEntries)
    }

    private var latestWaist: Double? {
        BodyCalculations.latestWaist(measurements: measurements)
    }

    private var entriesThisMonth: Int {
        BodyCalculations.entriesThisMonth(entries: weightEntries)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statsGrid
                    weightChartSection
                    measurementChartSection
                    logWeightSection
                    logMeasurementsSection
                    recentWeightsSection
                    recentMeasurementsSection
                }
                .padding(.vertical)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Body")
        }
        .task {
            await initialSync()
            loadDefaults()
        }
        .onDisappear {
            healthKitManager.stopObservingWeightChanges()
        }
        .alert("HealthKit Access Denied", isPresented: $showHealthKitDenied) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please enable Health access in Settings > Privacy > Health > OneTrack.")
        }
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(
                title: "Current Weight",
                value: currentWeight?.formattedWeight ?? "--",
                icon: "scalemass.fill",
                color: .blue
            )
            StatCard(
                title: "Weekly Change",
                value: BodyCalculations.weeklyChangeFormatted(weeklyChange),
                icon: "arrow.up.arrow.down",
                color: .purple
            )
            StatCard(
                title: "Latest Waist",
                value: latestWaist.map { String(format: "%.1f cm", $0) } ?? "--",
                icon: "ruler.fill",
                color: .orange
            )
            StatCard(
                title: "Entries",
                value: "\(entriesThisMonth)",
                icon: "calendar",
                color: .teal
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Weight Chart

    private var weightChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Weight Trend")
                .font(.headline)
                .padding(.horizontal)

            Picker("Range", selection: $chartRange) {
                ForEach(ChartRange.allCases) { range in
                    Text(range.label).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            let chartData = BodyCalculations.filteredEntries(entries: weightEntries, days: chartRange.days)

            if chartData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                    Text("No weight data yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .cardStyle()
                .padding(.horizontal)
            } else {
                Chart(chartData, id: \.date) { entry in
                    LineMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weightKg)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", entry.date),
                        y: .value("Weight", entry.weightKg)
                    )
                    .foregroundStyle(.blue)
                    .symbolSize(30)
                }
                .chartYScale(domain: chartYDomain(for: chartData))
                .frame(height: 180)
                .cardStyle()
                .padding(.horizontal)
            }
        }
    }

    private func chartYDomain(for entries: [WeightEntry]) -> ClosedRange<Double> {
        let weights = entries.map(\.weightKg)
        let minW = (weights.min() ?? 0) - 1
        let maxW = (weights.max() ?? 100) + 1
        return minW...maxW
    }

    // MARK: - Measurement Progress Chart

    private var measurementChartSection: some View {
        let chartData = BodyCalculations.measurementChartData(measurements: measurements)

        return Group {
            if !chartData.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Measurement Trends")
                        .font(.headline)
                        .padding(.horizontal)

                    Chart(chartData) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("cm", point.value)
                        )
                        .foregroundStyle(by: .value("Type", point.type))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", point.date),
                            y: .value("cm", point.value)
                        )
                        .foregroundStyle(by: .value("Type", point.type))
                        .symbolSize(20)
                    }
                    .chartForegroundStyleScale([
                        "Waist": Color.blue,
                        "Chest": Color.green,
                        "L. Bicep": Color.orange,
                        "R. Bicep": Color.purple
                    ])
                    .chartLegend(.visible)
                    .frame(height: 180)
                    .cardStyle()
                    .padding(.horizontal)
                }
            }
        }
    }

    // MARK: - Log Weight (sync button removed)

    private var logWeightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Log Weight")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 16) {
                HStack {
                    Text("Weight")
                        .font(.subheadline)
                    Spacer()
                    BodyStepperInput(
                        value: $weightValue,
                        step: 0.1,
                        range: 20...300,
                        format: "%.1f kg"
                    )
                }

                Button {
                    saveWeight()
                } label: {
                    Label("Save", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.white)
                        .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .cardStyle()
            .padding(.horizontal)
        }
    }

    // MARK: - Log Measurements

    private var logMeasurementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Log Measurements")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 14) {
                measurementToggleRow(label: "Waist", isOn: $logWaist, value: $waistValue)
                measurementToggleRow(label: "Chest", isOn: $logChest, value: $chestValue)
                measurementToggleRow(label: "Left Bicep", isOn: $logLeftBicep, value: $leftBicepValue)
                measurementToggleRow(label: "Right Bicep", isOn: $logRightBicep, value: $rightBicepValue)

                TextField("Notes (optional)", text: $measurementNotes)
                    .font(.subheadline)
                    .padding(10)
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))

                Button {
                    saveMeasurement()
                } label: {
                    Label("Save Measurement", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.white)
                        .background(.orange, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(!logWaist && !logChest && !logLeftBicep && !logRightBicep)
            }
            .cardStyle()
            .padding(.horizontal)
        }
    }

    private func measurementToggleRow(label: String, isOn: Binding<Bool>, value: Binding<Double>) -> some View {
        VStack(spacing: 8) {
            HStack {
                Toggle(label, isOn: isOn)
                    .font(.subheadline)
            }

            if isOn.wrappedValue {
                HStack {
                    Spacer()
                    BodyStepperInput(
                        value: value,
                        step: 0.5,
                        range: 10...200,
                        format: "%.1f cm"
                    )
                }
            }
        }
    }

    // MARK: - Recent Weights (collapsible)

    private var recentWeightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !weightEntries.isEmpty {
                DisclosureGroup(
                    isExpanded: $showRecentWeights
                ) {
                    VStack(spacing: 0) {
                        ForEach(Array(weightEntries.prefix(10).enumerated()), id: \.element.id) { index, entry in
                            weightRow(entry)

                            if index < min(weightEntries.count, 10) - 1 {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                } label: {
                    Text("Recent Weights (\(weightEntries.count))")
                        .font(.headline)
                }
                .cardStyle()
                .padding(.horizontal)
            }
        }
    }

    private func weightRow(_ entry: WeightEntry) -> some View {
        HStack(spacing: 12) {
            Image(systemName: entry.source == "healthkit" ? "heart.fill" : "pencil")
                .font(.caption)
                .foregroundStyle(entry.source == "healthkit" ? .pink : .blue)
                .frame(width: 28, height: 28)
                .background(
                    (entry.source == "healthkit" ? Color.pink : Color.blue).opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 8)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.weightKg.formattedWeight)
                    .font(.subheadline.bold().monospacedDigit())
                Text(entry.date.shortDateTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Recent Measurements (collapsible)

    private var recentMeasurementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !measurements.isEmpty {
                DisclosureGroup(
                    isExpanded: $showRecentMeasurements
                ) {
                    VStack(spacing: 0) {
                        ForEach(Array(measurements.prefix(10).enumerated()), id: \.element.id) { index, measurement in
                            measurementRow(measurement)

                            if index < min(measurements.count, 10) - 1 {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                } label: {
                    Text("Recent Measurements (\(measurements.count))")
                        .font(.headline)
                }
                .cardStyle()
                .padding(.horizontal)
            }
        }
    }

    private func measurementRow(_ m: BodyMeasurement) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "ruler.fill")
                .font(.caption)
                .foregroundStyle(.orange)
                .frame(width: 28, height: 28)
                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    if let w = m.waistCm { Text("W: \(String(format: "%.1f", w))").font(.caption.monospacedDigit()) }
                    if let c = m.chestCm { Text("C: \(String(format: "%.1f", c))").font(.caption.monospacedDigit()) }
                    if let lb = m.leftBicepCm { Text("LB: \(String(format: "%.1f", lb))").font(.caption.monospacedDigit()) }
                    if let rb = m.rightBicepCm { Text("RB: \(String(format: "%.1f", rb))").font(.caption.monospacedDigit()) }
                }
                .font(.subheadline.bold())

                HStack(spacing: 6) {
                    Text(m.date.shortDateTime)
                    if !m.notes.isEmpty {
                        Text("- \(m.notes)")
                            .lineLimit(1)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    // MARK: - Actions

    private func loadDefaults() {
        guard !hasLoadedDefaults else { return }
        hasLoadedDefaults = true

        // Weight default from last entry
        if let lastWeight = weightEntries.first?.weightKg {
            weightValue = (lastWeight * 10).rounded() / 10
        }

        // Measurement defaults from last entries
        let latest = BodyCalculations.latestMeasurementValues(measurements: measurements)
        if let w = latest.waist { waistValue = w }
        if let c = latest.chest { chestValue = c }
        if let lb = latest.leftBicep { leftBicepValue = lb }
        if let rb = latest.rightBicep { rightBicepValue = rb }
    }

    private func saveWeight() {
        let entry = WeightEntry(date: .now, weightKg: weightValue, source: "manual")
        modelContext.insert(entry)
        try? modelContext.save()

        if healthKitManager.isAuthorized {
            Task {
                try? await healthKitManager.saveWeight(weightKg: weightValue)
            }
        }
    }

    private func initialSync() async {
        guard healthKitManager.isAvailable else { return }

        if !healthKitManager.isAuthorized {
            await healthKitManager.requestAuthorization()
        }

        guard healthKitManager.isAuthorized else { return }

        // Incremental sync on appear
        let newSamples = await healthKitManager.fetchNewWeightSamples()
        importSamples(newSamples)

        // Set up observer for real-time updates
        healthKitManager.onNewWeightSamples = { [self] samples in
            self.importSamples(samples)
        }
        healthKitManager.startObservingWeightChanges()
    }

    private func importSamples(_ samples: [WeightSample]) {
        let toImport = BodyCalculations.samplesToImport(
            samples: samples,
            existingEntries: weightEntries
        )
        for sample in toImport {
            let values = BodyCalculations.weightEntryValues(from: sample)
            let entry = WeightEntry(date: values.date, weightKg: values.weightKg, source: values.source)
            modelContext.insert(entry)
        }
        if !toImport.isEmpty {
            try? modelContext.save()
        }
    }

    private func saveMeasurement() {
        let m = BodyMeasurement(date: .now)
        if logWaist { m.waistCm = waistValue }
        if logChest { m.chestCm = chestValue }
        if logLeftBicep { m.leftBicepCm = leftBicepValue }
        if logRightBicep { m.rightBicepCm = rightBicepValue }
        m.notes = measurementNotes
        modelContext.insert(m)
        try? modelContext.save()

        logWaist = false
        logChest = false
        logLeftBicep = false
        logRightBicep = false
        measurementNotes = ""
    }
}

// MARK: - Chart Range

enum ChartRange: String, CaseIterable, Identifiable {
    case sevenDays = "7D"
    case thirtyDays = "30D"
    case ninetyDays = "90D"
    case oneYear = "1Y"

    var id: String { rawValue }
    var label: String { rawValue }

    var days: Int {
        switch self {
        case .sevenDays: 7
        case .thirtyDays: 30
        case .ninetyDays: 90
        case .oneYear: 365
        }
    }
}

// MARK: - Body Stepper Input

private struct BodyStepperInput: View {
    @Binding var value: Double
    let step: Double
    let range: ClosedRange<Double>
    let format: String

    @FocusState private var isEditing: Bool
    @State private var textValue = ""

    var body: some View {
        HStack(spacing: 4) {
            Button {
                value = max(range.lowerBound, value - step)
            } label: {
                Image(systemName: "minus")
                    .font(.caption2.bold())
                    .frame(width: 36, height: 36)
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            if isEditing {
                TextField("", text: $textValue)
                    .keyboardType(.decimalPad)
                    .font(.subheadline.monospacedDigit().bold())
                    .multilineTextAlignment(.center)
                    .frame(minWidth: 70)
                    .focused($isEditing)
                    .onSubmit { commitEdit() }
                    .onChange(of: isEditing) {
                        if !isEditing { commitEdit() }
                    }
            } else {
                Text(String(format: format, value))
                    .font(.subheadline.monospacedDigit().bold())
                    .frame(minWidth: 70)
                    .multilineTextAlignment(.center)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        textValue = String(format: format, value)
                        isEditing = true
                    }
            }

            Button {
                value = min(range.upperBound, value + step)
            } label: {
                Image(systemName: "plus")
                    .font(.caption2.bold())
                    .frame(width: 36, height: 36)
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }

    private func commitEdit() {
        if let parsed = Double(textValue) {
            value = min(range.upperBound, max(range.lowerBound, parsed))
        }
    }
}
