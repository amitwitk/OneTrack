import SwiftUI
import SwiftData

struct WorkoutPlanListView: View {
    @Query(sort: \WorkoutPlan.sortOrder) private var plans: [WorkoutPlan]
    @Query(filter: #Predicate<WorkoutSession> { !$0.isCompleted })
    private var incompleteSessions: [WorkoutSession]
    @Environment(\.modelContext) private var modelContext
    @Binding var showCreatePlan: Bool

    @State private var activeSession: WorkoutSession?
    @State private var previousSessionForActive: WorkoutSession?
    @State private var planToEdit: WorkoutPlan?

    var body: some View {
        Group {
            if plans.isEmpty && incompleteSessions.isEmpty {
                emptyState
            } else {
                planList
            }
        }
        .fullScreenCover(item: $activeSession) { session in
            NavigationStack {
                ActiveWorkoutView(session: session, previousSession: previousSessionForActive)
            }
        }
        .sheet(item: $planToEdit) { plan in
            NavigationStack {
                CreatePlanView(editingPlan: plan)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "dumbbell")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)
            Text("No Workouts Yet")
                .font(.title3.bold())
            Text("Create your first workout routine\nto start tracking your progress")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showCreatePlan = true
            } label: {
                Label("Create Workout", systemImage: "plus")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue, in: Capsule())
            }
            .padding(.top, 8)
            Spacer()
        }
    }

    // MARK: - Plan List

    private var planList: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Resume banner
                if let incompleteSession = incompleteSessions.first {
                    resumeBanner(incompleteSession)
                }

                // Plans
                ForEach(plans) { plan in
                    planRow(plan)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
    }

    // MARK: - Resume Banner

    private func resumeBanner(_ session: WorkoutSession) -> some View {
        Button {
            previousSessionForActive = findPreviousSession(for: session)
            activeSession = session
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(.orange.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "play.fill")
                        .foregroundStyle(.orange)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Continue Workout")
                        .font(.subheadline.bold())
                    Text(session.plan?.name ?? "Workout")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(session.startedAt.relativeDay)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(.background, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(.orange.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Plan Row

    private func planRow(_ plan: WorkoutPlan) -> some View {
        let exerciseNames = plan.exercises
            .sorted { $0.sortOrder < $1.sortOrder }
            .map(\.name)
        let lastSession = plan.sessions
            .filter { $0.isCompleted }
            .sorted { $0.date > $1.date }
            .first

        return HStack(spacing: 14) {
            // Plan info (tappable for detail)
            NavigationLink {
                WorkoutPlanDetailView(plan: plan)
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(plan.name)
                        .font(.headline)

                    Text(exerciseNames.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 12) {
                        Label("\(plan.exercises.count)", systemImage: "figure.strengthtraining.traditional")
                        if let lastSession {
                            Label(lastSession.date.relativeDay, systemImage: "clock")
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                }
            }

            // Start button
            Button {
                startWorkout(plan: plan)
            } label: {
                Text("Start")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.blue, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
        .contextMenu {
            Button {
                planToEdit = plan
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                modelContext.delete(plan)
                try? modelContext.save()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Actions

    private func startWorkout(plan: WorkoutPlan) {
        let session = WorkoutSession(plan: plan)
        modelContext.insert(session)

        let previous = findPreviousSession(for: session)

        for exercise in plan.exercises.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            let log = ExerciseLog(exerciseName: exercise.name, sortOrder: exercise.sortOrder, isIsometric: exercise.isIsometric, section: exercise.section)
            log.session = session
            modelContext.insert(log)

            let previousLog = previous?.exerciseLogs.first { $0.exerciseName == exercise.name }
            let previousSets = previousLog?.sets.sorted { $0.setNumber < $1.setNumber } ?? []

            for setIndex in 0..<exercise.targetSets {
                let prevSet = setIndex < previousSets.count ? previousSets[setIndex] : nil
                let setLog = SetLog(
                    setNumber: setIndex + 1,
                    reps: prevSet?.reps ?? exercise.targetReps,
                    seconds: prevSet?.seconds ?? exercise.targetSeconds,
                    weightKg: prevSet?.weightKg ?? 0
                )
                setLog.exerciseLog = log
                modelContext.insert(setLog)
            }
        }

        try? modelContext.save()
        previousSessionForActive = previous
        activeSession = session
    }

    private func findPreviousSession(for session: WorkoutSession) -> WorkoutSession? {
        session.plan?.sessions
            .filter { $0.isCompleted && $0.id != session.id }
            .sorted { $0.date > $1.date }
            .first
    }
}
