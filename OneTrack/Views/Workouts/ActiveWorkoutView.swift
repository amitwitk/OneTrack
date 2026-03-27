import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Bindable var session: WorkoutSession
    var previousSession: WorkoutSession?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var elapsedSeconds: Int = 0
    @State private var isTimerRunning = true
    @State private var showFinishConfirmation = false
    @State private var showCancelConfirmation = false

    // Rest timer
    @State private var restTimeRemaining: Int = 0
    @State private var isResting = false
    @State private var restDuration: Int = 90

    private var sortedLogs: [ExerciseLog] {
        session.exerciseLogs.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var completedCount: Int {
        sortedLogs.flatMap(\.sets).filter(\.isCompleted).count
    }

    private var totalCount: Int {
        sortedLogs.flatMap(\.sets).count
    }

    private var progress: Double {
        totalCount > 0 ? Double(completedCount) / Double(totalCount) : 0
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    ForEach(sortedLogs) { log in
                        ExerciseSectionView(
                            log: log,
                            previousSession: previousSession,
                            onSetCompleted: { startRestTimer() }
                        )
                    }
                    Color.clear.frame(height: isResting ? 80 : 0)
                }
                .padding()
            }

            if isResting {
                restTimerOverlay
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(session.plan?.name ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showCancelConfirmation = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.hierarchical)
                        .font(.title3)
                        .foregroundStyle(.red)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFinishConfirmation = true
                } label: {
                    Text("Finish")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(.green, in: Capsule())
                }
            }
        }
        .confirmationDialog("Finish Workout?", isPresented: $showFinishConfirmation) {
            Button("Finish Workout") { finishWorkout() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("\(completedCount)/\(totalCount) sets completed - \(elapsedSeconds.durationString)")
        }
        .confirmationDialog("Cancel Workout?", isPresented: $showCancelConfirmation) {
            Button("Discard Workout", role: .destructive) { cancelWorkout() }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("All logged sets will be lost.")
        }
        .onAppear {
            restDuration = session.plan?.defaultRestSeconds ?? 90
        }
        .task(id: "workout-timer") {
            while isTimerRunning && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard isTimerRunning else { break }
                elapsedSeconds = Int(Date.now.timeIntervalSince(session.startedAt))
            }
        }
        .task(id: isResting) {
            guard isResting else { return }
            while isResting && restTimeRemaining > 0 && !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                restTimeRemaining -= 1
            }
            if restTimeRemaining <= 0 {
                isResting = false
            }
        }
        .sensoryFeedback(.success, trigger: completedCount)
    }

    // MARK: - Header Card

    private var headerCard: some View {
        VStack(spacing: 14) {
            // Progress ring + timer
            HStack(spacing: 20) {
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(.tertiary.opacity(0.3), lineWidth: 6)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                    VStack(spacing: 0) {
                        Text("\(completedCount)")
                            .font(.title3.bold().monospacedDigit())
                        Text("/\(totalCount)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 4) {
                    Text(session.plan?.name ?? "Workout")
                        .font(.title3.bold())
                    Text("\(sortedLogs.count) exercises")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Timer
                VStack(alignment: .trailing, spacing: 2) {
                    Image(systemName: "timer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(elapsedSeconds.durationString)
                        .font(.title3.monospacedDigit().bold())
                        .foregroundStyle(.blue)
                }
            }
        }
        .cardStyle()
    }

    // MARK: - Rest Timer Overlay

    private var restTimerOverlay: some View {
        let restProgress = restDuration > 0 ? Double(restTimeRemaining) / Double(restDuration) : 0

        return HStack(spacing: 16) {
            // Mini progress ring
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: restProgress)
                    .stroke(.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: restProgress)
                Text("\(restTimeRemaining)")
                    .font(.body.monospacedDigit().bold())
                    .foregroundStyle(.white)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text("Rest Timer")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text("Next set when ready")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Button {
                withAnimation { isResting = false }
                restTimeRemaining = 0
            } label: {
                Text("Skip")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(.white.opacity(0.2), in: Capsule())
            }
        }
        .padding()
        .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(duration: 0.3), value: isResting)
    }

    // MARK: - Actions

    private func startRestTimer() {
        restTimeRemaining = restDuration
        withAnimation { isResting = true }
    }

    private func finishWorkout() {
        session.isCompleted = true
        session.durationSeconds = elapsedSeconds
        isTimerRunning = false
        isResting = false
        try? modelContext.save()
        dismiss()
    }

    private func cancelWorkout() {
        isTimerRunning = false
        isResting = false
        modelContext.delete(session)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Exercise Section

private struct ExerciseSectionView: View {
    let log: ExerciseLog
    let previousSession: WorkoutSession?
    let onSetCompleted: () -> Void

    private var sortedSets: [SetLog] {
        log.sets.sorted { $0.setNumber < $1.setNumber }
    }

    private var previousSets: [SetLog] {
        guard let previousSession else { return [] }
        return previousSession.exerciseLogs
            .first { $0.exerciseName == log.exerciseName }?
            .sets.sorted { $0.setNumber < $1.setNumber } ?? []
    }

    private var allCompleted: Bool {
        sortedSets.allSatisfy(\.isCompleted)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Exercise header
            HStack {
                Text(log.exerciseName)
                    .font(.headline)
                Spacer()
                if allCompleted {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                        .symbolEffect(.bounce, value: allCompleted)
                }
            }
            .padding(.horizontal)
            .padding(.top, 14)
            .padding(.bottom, 8)

            Divider()
                .padding(.horizontal)

            // Set header row
            HStack(spacing: 0) {
                Text("SET")
                    .frame(width: 36)
                Text("PREVIOUS")
                    .frame(maxWidth: .infinity)
                Text(log.isIsometric ? "SEC" : "REPS")
                    .frame(width: 100)
                Text("KG")
                    .frame(width: 110)
                Text("")
                    .frame(width: 44)
            }
            .font(.caption2.bold())
            .foregroundStyle(.secondary)
            .padding(.horizontal)
            .padding(.vertical, 6)

            // Set rows
            ForEach(sortedSets) { setLog in
                let prevSet = setLog.setNumber <= previousSets.count ? previousSets[setLog.setNumber - 1] : nil
                SetRowView(setLog: setLog, previousSet: prevSet, isIsometric: log.isIsometric, onCompleted: onSetCompleted)

                if setLog.setNumber < sortedSets.count {
                    Divider()
                        .padding(.horizontal)
                }
            }
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}

// MARK: - Set Row

private struct SetRowView: View {
    @Bindable var setLog: SetLog
    let previousSet: SetLog?
    let isIsometric: Bool
    let onCompleted: () -> Void

    private var isImproved: Bool {
        guard let prev = previousSet else { return false }
        if isIsometric {
            return setLog.weightKg > prev.weightKg ||
                (setLog.weightKg == prev.weightKg && setLog.seconds > prev.seconds)
        }
        return setLog.weightKg > prev.weightKg ||
            (setLog.weightKg == prev.weightKg && setLog.reps > prev.reps)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Set number badge
            Text("\(setLog.setNumber)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(setLog.isCompleted ? .green : .gray.opacity(0.4), in: Circle())
                .frame(width: 36)

            // Previous
            Group {
                if let prev = previousSet {
                    if isIsometric {
                        Text("\(prev.seconds)s x \(prev.weightKg.compactWeight)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.tertiary)
                    } else {
                        Text("\(prev.reps) x \(prev.weightKg.compactWeight)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }
                } else {
                    Text("--")
                        .font(.caption)
                        .foregroundStyle(.quaternary)
                }
            }
            .frame(maxWidth: .infinity)

            // Reps or Seconds stepper
            if isIsometric {
                StepperInput(
                    value: Binding(
                        get: { Double(setLog.seconds) },
                        set: { setLog.seconds = Int($0) }
                    ),
                    label: "",
                    step: 5,
                    range: 0...600
                )
                .frame(width: 100)
            } else {
                StepperInput(
                    value: Binding(
                        get: { Double(setLog.reps) },
                        set: { setLog.reps = Int($0) }
                    ),
                    label: "",
                    step: 1,
                    range: 0...99
                )
                .frame(width: 100)
            }

            // Weight stepper
            StepperInput(
                value: Binding(
                    get: { setLog.weightKg },
                    set: { setLog.weightKg = $0 }
                ),
                label: "",
                step: 2.5,
                range: 0...500,
                decimals: true
            )
            .frame(width: 110)

            // Complete button
            Button {
                if !setLog.isCompleted {
                    setLog.isCompleted = true
                    onCompleted()
                } else {
                    setLog.isCompleted = false
                }
            } label: {
                ZStack {
                    if isImproved && setLog.isCompleted {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: setLog.isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundStyle(setLog.isCompleted ? .green : .gray.opacity(0.35))
                    }
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(setLog.isCompleted ? .green.opacity(0.04) : .clear)
    }
}

// MARK: - Stepper Input Component

private struct StepperInput<V: BinaryFloatingPoint>: View {
    @Binding var value: V
    let label: String
    let step: V
    let range: ClosedRange<V>
    var decimals: Bool = false

    var body: some View {
        HStack(spacing: 2) {
            Button {
                value = max(range.lowerBound, value - step)
            } label: {
                Image(systemName: "minus")
                    .font(.caption2.bold())
                    .frame(width: 28, height: 32)
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            Text(decimals ? String(format: "%.1f", Double(value)) : "\(Int(value))")
                .font(.subheadline.monospacedDigit().bold())
                .frame(minWidth: 32)
                .multilineTextAlignment(.center)

            Button {
                value = min(range.upperBound, value + step)
            } label: {
                Image(systemName: "plus")
                    .font(.caption2.bold())
                    .frame(width: 28, height: 32)
                    .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
    }
}
