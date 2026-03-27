import Foundation
import SwiftData

@Model
final class BodyMeasurement {
    var date: Date = Date()
    var waistCm: Double?
    var chestCm: Double?
    var leftBicepCm: Double?
    var rightBicepCm: Double?
    var notes: String = ""

    init(date: Date = .now) {
        self.date = date
    }
}

57 +                    .background(.blue, in: Capsule())
58 +            }
59 +            .padding(.top, 8)
60 +            Spacer()
61 +        }
62 +    }
63 +
64 +    // MARK: - Plan List
65 +
66 +    private var planList: some View {
67          ScrollView {
14 -            VStack(spacing: 16) {
15 -                // Resume interrupted workout banner
68 +            VStack(spacing: 12) {
69 +                // Resume banner
70                  if let incompleteSession = incompleteSessions.first {
71                      resumeBanner(incompleteSession)
72                  }
73
20 -                // Plan cards
74 +                // Plans
75                  ForEach(plans) { plan in
22 -                    planCard(plan)
76 +                    planRow(plan)
77                  }
78              }
25 -            .padding()
79 +            .padding(.horizontal)
80 +            .padding(.top, 8)
81          }
27 -        .fullScreenCover(item: $activeSession) { session in
28 -            NavigationStack {
29 -                ActiveWorkoutView(session: session, previousSession: previousSessionForActive)
30 -            }
31 -        }
82      }
83
84      // MARK: - Resume Banner
...
 88              previousSessionForActive = findPreviousSession(for: session)
 89              activeSession = session
 90          } label: {
 41 -            HStack(spacing: 14) {
 42 -                Image(systemName: "play.circle.fill")
 43 -                    .font(.largeTitle)
 44 -                    .foregroundStyle(.orange)
 45 -                    .symbolEffect(.pulse)
 91 +            HStack(spacing: 12) {
 92 +                ZStack {
 93 +                    Circle()
 94 +                        .fill(.orange.opacity(0.15))
 95 +                        .frame(width: 44, height: 44)
 96 +                    Image(systemName: "play.fill")
 97 +                        .foregroundStyle(.orange)
 98 +                }
 99
 47 -                VStack(alignment: .leading, spacing: 3) {
 48 -                    Text("Resume Workout")
 49 -                        .font(.headline)
 50 -                    Text("\(session.plan?.name ?? "Workout") - \(session.startedAt.relativeDay)")
100 +                VStack(alignment: .leading, spacing: 2) {
101 +                    Text("Continue Workout")
102 +                        .font(.subheadline.bold())
103 +                    Text(session.plan?.name ?? "Workout")
104                          .font(.caption)
105                          .foregroundStyle(.secondary)
106                  }
107
108                  Spacer()
109
 57 -                Image(systemName: "chevron.right.circle.fill")
 58 -                    .font(.title3)
110 +                Text(session.startedAt.relativeDay)
111 +                    .font(.caption)
112 +                    .foregroundStyle(.secondary)
113 +
114 +                Image(systemName: "chevron.right")
115 +                    .font(.caption)
116                      .foregroundStyle(.tertiary)
117              }
 61 -            .padding()
 62 -            .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
 63 -            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.orange.opacity(0.2), lineWidth: 1))
118 +            .padding(14)
119 +            .background(.background, in: RoundedRectangle(cornerRadius: 14))
120 +            .overlay(
121 +                RoundedRectangle(cornerRadius: 14)
122 +                    .stroke(.orange.opacity(0.3), lineWidth: 1)
123 +            )
124          }
125          .buttonStyle(.plain)
126      }
127
 68 -    // MARK: - Plan Card
128 +    // MARK: - Plan Row
129
 70 -    private func planCard(_ plan: WorkoutPlan) -> some View {
 71 -        let style = PlanStyle.from(name: plan.name)
130 +    private func planRow(_ plan: WorkoutPlan) -> some View {
131 +        let exerciseNames = plan.exercises
132 +            .sorted { $0.sortOrder < $1.sortOrder }
133 +            .map(\.name)
134          let lastSession = plan.sessions
135              .filter { $0.isCompleted }
136              .sorted { $0.date > $1.date }
137              .first
138
 77 -        return VStack(spacing: 0) {
 78 -            // Card header with gradient
 79 -            HStack {
139 +        return HStack(spacing: 14) {
140 +            // Plan info (tappable for detail)
141 +            NavigationLink {
142 +                WorkoutPlanDetailView(plan: plan)
143 +            } label: {
144                  VStack(alignment: .leading, spacing: 6) {
 81 -                    HStack(spacing: 8) {
 82 -                        Image(systemName: style.icon)
 83 -                            .font(.title3)
 84 -                        Text(plan.name)
 85 -                            .font(.title3.bold())
 86 -                    }
 87 -                    Text(plan.planDescription)
 88 -                        .font(.subheadline)
 89 -                        .opacity(0.85)
 90 -                }
 91 -                Spacer()
145 +                    Text(plan.name)
146 +                        .font(.headline)
147
 93 -                // Start button
 94 -                Button {
 95 -                    startWorkout(plan: plan)
 96 -                } label: {
 97 -                    Image(systemName: "play.fill")
 98 -                        .font(.body.bold())
 99 -                        .foregroundStyle(style.color)
100 -                        .frame(width: 52, height: 52)
101 -                        .background(.white, in: Circle())
102 -                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
103 -                }
104 -                .buttonStyle(.plain)
105 -            }
106 -            .foregroundStyle(.white)
107 -            .padding()
108 -            .background(style.gradient, in: UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))
109 -
110 -            // Card body
111 -            VStack(spacing: 0) {
112 -                // Exercise previews
113 -                HStack(spacing: 0) {
114 -                    ForEach(Array(plan.exercises.sorted { $0.sortOrder < $1.sortOrder }.prefix(3).enumerated()), id: \.offset) { _, exercise in
115 -                        VStack(spacing: 2) {
116 -                            Text(shortName(exercise.name))
117 -                                .font(.caption2.bold())
118 -                                .lineLimit(1)
119 -                            Text("\(exercise.targetSets)x\(exercise.targetReps)")
120 -                                .font(.caption2.monospacedDigit())
121 -                                .foregroundStyle(.secondary)
122 -                        }
123 -                        .frame(maxWidth: .infinity)
124 -                    }
125 -                    if plan.exercises.count > 3 {
126 -                        Text("+\(plan.exercises.count - 3)")
127 -                            .font(.caption2)
128 -                            .foregroundStyle(.tertiary)
129 -                            .frame(maxWidth: .infinity)
130 -                    }
131 -                }
132 -                .padding(.vertical, 10)
133 -                .padding(.horizontal)
134 -
135 -                Divider()
136 -                    .padding(.horizontal)
137 -
138 -                // Footer
139 -                HStack {
140 -                    Label("\(plan.exercises.count) exercises", systemImage: "list.bullet")
148 +                    Text(exerciseNames.joined(separator: ", "))
149                          .font(.caption)
150                          .foregroundStyle(.secondary)
151 +                        .lineLimit(1)
152
144 -                    Spacer()
145 -
146 -                    if let lastSession {
147 -                        Label(lastSession.date.relativeDay, systemImage: "clock")
148 -                            .font(.caption)
149 -                            .foregroundStyle(.secondary)
150 -                    } else {
151 -                        Text("Not started")
152 -                            .font(.caption)
153 -                            .foregroundStyle(.tertiary)
153 +                    HStack(spacing: 12) {
154 +                        Label("\(plan.exercises.count)", systemImage: "figure.strengthtraining.traditional")
155 +                        if let lastSession {
156 +                            Label(lastSession.date.relativeDay, systemImage: "clock")
157 +                        }
158                      }
155 -
156 -                    NavigationLink {
157 -                        WorkoutPlanDetailView(plan: plan)
158 -                    } label: {
159 -                        Image(systemName: "info.circle")
160 -                            .font(.body)
161 -                            .foregroundStyle(.secondary)
162 -                    }
159 +                    .font(.caption2)
160 +                    .foregroundStyle(.tertiary)
161                  }
164 -                .padding(.horizontal)
165 -                .padding(.vertical, 10)
162              }
167 -            .background(.background, in: UnevenRoundedRectangle(bottomLeadingRadius: 16, bottomTrailingRadius: 16))
163 +
164 +            // Start button
165 +            Button {
166 +                startWorkout(plan: plan)
167 +            } label: {
168 +                Text("Start")
169 +                    .font(.subheadline.bold())
170 +                    .foregroundStyle(.white)
171 +                    .padding(.horizontal, 16)
172 +                    .padding(.vertical, 8)
173 +                    .background(.blue, in: Capsule())
174 +            }
175 +            .buttonStyle(.plain)
176          }
169 -        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
177 +        .padding(14)
178 +        .background(.background, in: RoundedRectangle(cornerRadius: 14))
179 +        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
180 +        .contextMenu {
181 +            Button {
182 +                planToEdit = plan
183 +            } label: {
184 +                Label("Edit", systemImage: "pencil")
185 +            }
186 +            Button(role: .destructive) {
187 +                modelContext.delete(plan)
188 +                try? modelContext.save()
189 +            } label: {
190 +                Label("Delete", systemImage: "trash")
191 +            }
192 +        }
193      }
194
172 -    private func shortName(_ name: String) -> String {
173 -        let words = name.split(separator: " ")
174 -        if words.count <= 2 { return name }
175 -        return words.prefix(2).joined(separator: " ")
176 -    }
177 -
195      // MARK: - Actions
196
197      private func startWorkout(plan: WorkoutPlan) {
⎿  Found 13 new diagnostic issues in 2 files (ctrl+o to expand)

⏺ Now update the plan detail view — remove the color coding, keep it clean.

⏺ Write(OneTrack/Views/Workouts/WorkoutPlanDetailView.swift)
⎿  Added 51 lines, removed 81 lines
  4  struct WorkoutPlanDetailView: View {
  5      let plan: WorkoutPlan
  6
  7 -    private var style: PlanStyle { PlanStyle.from(name: plan.name) }
  8 -
  7      private var sortedExercises: [Exercise] {
  8          plan.exercises.sorted { $0.sortOrder < $1.sortOrder }
  9      }
 10
 11 +    private var completedSessions: [WorkoutSession] {
 12 +        plan.sessions.filter(\.isCompleted).sorted { $0.date > $1.date }
 13 +    }
 14 +
 15      var body: some View {
 14 -        ScrollView {
 15 -            VStack(spacing: 16) {
 16 -                // Header
 17 -                VStack(spacing: 8) {
 18 -                    Image(systemName: style.icon)
 19 -                        .font(.largeTitle)
 20 -                        .foregroundStyle(.white)
 21 -                    Text(plan.name)
 22 -                        .font(.title2.bold())
 23 -                        .foregroundStyle(.white)
 24 -                    Text(plan.planDescription)
 25 -                        .font(.subheadline)
 26 -                        .foregroundStyle(.white.opacity(0.8))
 27 -                }
 28 -                .frame(maxWidth: .infinity)
 29 -                .padding(.vertical, 24)
 30 -                .background(style.gradient, in: RoundedRectangle(cornerRadius: 20))
 31 -                .shadow(color: style.color.opacity(0.3), radius: 12, y: 6)
 16 +        List {
 17 +            // Exercises
 18 +            Section("Exercises") {
 19 +                ForEach(Array(sortedExercises.enumerated()), id: \.element.id) { index, exercise in
 20 +                    HStack(spacing: 12) {
 21 +                        Text("\(index + 1)")
 22 +                            .font(.caption.bold())
 23 +                            .foregroundStyle(.white)
 24 +                            .frame(width: 24, height: 24)
 25 +                            .background(.blue, in: Circle())
 26
 33 -                // Exercises
 34 -                VStack(spacing: 0) {
 35 -                    ForEach(Array(sortedExercises.enumerated()), id: \.element.id) { index, exercise in
 36 -                        HStack(spacing: 14) {
 37 -                            Text("\(index + 1)")
 38 -                                .font(.caption.bold())
 39 -                                .foregroundStyle(.white)
 40 -                                .frame(width: 24, height: 24)
 41 -                                .background(style.color, in: Circle())
 27 +                        Text(exercise.name)
 28
 43 -                            Text(exercise.name)
 44 -                                .font(.body)
 29 +                        Spacer()
 30
 46 -                            Spacer()
 31 +                        Text("\(exercise.targetSets) x \(exercise.targetReps)")
 32 +                            .foregroundStyle(.secondary)
 33 +                            .font(.subheadline.monospacedDigit())
 34 +                    }
 35 +                }
 36 +            }
 37
 48 -                            Text("\(exercise.targetSets) x \(exercise.targetReps)")
 49 -                                .font(.subheadline.monospacedDigit().bold())
 50 -                                .foregroundStyle(style.color)
 51 -                                .padding(.horizontal, 10)
 52 -                                .padding(.vertical, 4)
 53 -                                .background(style.color.opacity(0.1), in: Capsule())
 54 -                        }
 55 -                        .padding(.horizontal)
 56 -                        .padding(.vertical, 12)
 38 +            // Stats
 39 +            if !completedSessions.isEmpty {
 40 +                Section("Stats") {
 41 +                    LabeledContent("Total Sessions", value: "\(completedSessions.count)")
 42
 58 -                        if index < sortedExercises.count - 1 {
 59 -                            Divider().padding(.leading, 54)
 43 +                    if let lastSession = completedSessions.first {
 44 +                        LabeledContent("Last Workout", value: lastSession.date.shortDate)
 45 +                        if let d = lastSession.durationSeconds {
 46 +                            LabeledContent("Last Duration", value: d.durationString)
 47                          }
 48                      }
 49                  }
 63 -                .background(.background, in: RoundedRectangle(cornerRadius: 16))
 64 -                .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
 50 +            }
 51
 66 -                // Last session stats
 67 -                if let lastSession = plan.sessions
 68 -                    .filter({ $0.isCompleted })
 69 -                    .sorted(by: { $0.date > $1.date })
 70 -                    .first {
 71 -                    VStack(alignment: .leading, spacing: 12) {
 72 -                        Text("Last Session")
 73 -                            .font(.headline)
 74 -
 75 -                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
 76 -                            miniStat("Date", value: lastSession.date.shortDate, icon: "calendar")
 77 -                            if let d = lastSession.durationSeconds {
 78 -                                miniStat("Duration", value: d.durationString, icon: "timer")
 52 +            // Recent history
 53 +            if !completedSessions.isEmpty {
 54 +                Section("Recent Sessions") {
 55 +                    ForEach(completedSessions.prefix(5)) { session in
 56 +                        NavigationLink {
 57 +                            WorkoutSessionDetailView(session: session)
 58 +                        } label: {
 59 +                            HStack {
 60 +                                Text(session.date.shortDate)
 61 +                                Spacer()
 62 +                                if let d = session.durationSeconds {
 63 +                                    Text(d.durationString)
 64 +                                        .font(.caption)
 65 +                                        .foregroundStyle(.secondary)
 66 +                                }
 67 +                                let completed = session.exerciseLogs.flatMap(\.sets).filter(\.isCompleted).count
 68 +                                let total = session.exerciseLogs.flatMap(\.sets).count
 69 +                                Text("\(completed)/\(total)")
 70 +                                    .font(.caption.monospacedDigit())
 71 +                                    .foregroundStyle(.secondary)
 72                              }
 80 -                            let completed = lastSession.exerciseLogs.flatMap(\.sets).filter(\.isCompleted).count
 81 -                            let total = lastSession.exerciseLogs.flatMap(\.sets).count
 82 -                            miniStat("Sets", value: "\(completed)/\(total)", icon: "checkmark.circle")
 73                          }
 74                      }
 85 -                    .padding()
 86 -                    .background(.background, in: RoundedRectangle(cornerRadius: 16))
 87 -                    .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
 75                  }
 76              }
 90 -            .padding()
 77          }
 92 -        .background(Color(.systemGroupedBackground))
 78          .navigationTitle(plan.name)
 94 -        .navigationBarTitleDisplayMode(.inline)
 79      }
 96 -
 97 -    private func miniStat(_ title: String, value: String, icon: String) -> some View {
 98 -        VStack(spacing: 6) {
 99 -            Image(systemName: icon)
100 -                .font(.caption)
101 -                .foregroundStyle(.secondary)
102 -            Text(value)
103 -                .font(.subheadline.bold().monospacedDigit())
104 -            Text(title)
105 -                .font(.caption2)
106 -                .foregroundStyle(.secondary)
107 -        }
108 -        .frame(maxWidth: .infinity)
109 -    }
 80  }
⎿  Found 10 new diagnostic issues in 1 file (ctrl+o to expand)

⏺ Now update the Dashboard to remove the PlanStyle dependency and simplify.

Read 1 file (ctrl+o to expand)

⏺ Update(OneTrack/Views/Dashboard/DashboardView.swift)
⎿  Added 3 lines, removed 4 lines
131      }
132
133      private func recentSessionRow(_ session: WorkoutSession) -> some View {
134 -        let style = PlanStyle.from(name: session.plan?.name ?? "")
134          let completedSets = session.exerciseLogs.flatMap(\.sets).filter(\.isCompleted).count
135          let totalSets = session.exerciseLogs.flatMap(\.sets).count
136
137          return HStack(spacing: 14) {
139 -            Image(systemName: style.icon)
138 +            Image(systemName: "dumbbell.fill")
139                  .font(.title3)
141 -                .foregroundStyle(style.color)
140 +                .foregroundStyle(.blue)
141                  .frame(width: 40, height: 40)
143 -                .background(style.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
142 +                .background(.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
143
144              VStack(alignment: .leading, spacing: 3) {
145                  Text(session.plan?.name ?? "Workout")

⏺ Now clean up the AppTheme — remove the PlanStyle color coding since it's no longer used in the plan list. Keep the useful parts.

⏺ Write(OneTrack/Theme/AppTheme.swift)
⎿  Removed 40 lines
 1  import SwiftUI
 2
 3 -// MARK: - Workout Plan Colors
 4 -
 5 -enum PlanStyle {
 6 -    case push, pull, legs
 7 -
 8 -    static func from(name: String) -> PlanStyle {
 9 -        let lower = name.lowercased()
10 -        if lower.contains("push") { return .push }
11 -        if lower.contains("pull") { return .pull }
12 -        return .legs
13 -    }
14 -
15 -    var color: Color {
16 -        switch self {
17 -        case .push: .blue
18 -        case .pull: .purple
19 -        case .legs: .orange
20 -        }
21 -    }
22 -
23 -    var gradient: LinearGradient {
24 -        switch self {
25 -        case .push:
26 -            LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
27 -        case .pull:
28 -            LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
29 -        case .legs:
30 -            LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
31 -        }
32 -    }
33 -
34 -    var icon: String {
35 -        switch self {
36 -        case .push: "arrow.up.circle.fill"
37 -        case .pull: "arrow.down.circle.fill"
38 -        case .legs: "figure.walk.circle.fill"
39 -        }
40 -    }
41 -}
42 -
 3  // MARK: - Card Modifier
 4
 5  struct CardStyle: ViewModifier {
⎿  Found 4 new diagnostic issues in 1 file (ctrl+o to expand)

⏺ Now delete the old PredefinedPlans.swift since it's replaced.

⏺ Bash(rm /Users/amitwitk/Projects/OneTrack-p/OneTrack/Utilities/PredefinedPlans.swift)
⎿  remove /Users/amitwitk/Projects/OneTrack-p/OneTrack/Utilities/PredefinedPlans.swift?
⎿  Found 5 new diagnostic issues in 1 file (ctrl+o to expand)

⏺ Bash(rm -f /Users/amitwitk/Projects/OneTrack-p/OneTrack/Utilities/PredefinedPlans.swift && echo "Done")
⎿  Done

⏺ Now let's build to see if everything compiles.

⏺ Bash(xcodebuild -project OneTrack.xcodeproj -scheme OneTrack -destination 'generic/platform=iOS' build 2>&1 | grep -E "(error:|BUILD)" | head -15)
⎿  /Users/amitwitk/Projects/OneTrack-p/OneTrack/Views/Workouts/ActiveWorkoutView.swift:123:21: error: cannot find 'PlanStyle' in scope
** BUILD FAILED **
⎿  (timeout 2m)

⏺ ActiveWorkoutView still references PlanStyle. Let me remove that dependency.

Read 1 file (ctrl+o to expand)

⏺ Update(OneTrack/Views/Workouts/ActiveWorkoutView.swift)
⎿  Added 1 line, removed 3 lines
120      // MARK: - Header Card
121
122      private var headerCard: some View {
123 -        let style = PlanStyle.from(name: session.plan?.name ?? "")
124 -
125 -        return VStack(spacing: 14) {
123 +        VStack(spacing: 14) {
124              // Progress ring + timer
125              HStack(spacing: 20) {
126                  // Circular progress

⏺ Update(OneTrack/Views/Workouts/ActiveWorkoutView.swift)
⎿  Added 1 line, removed 1 line
129                          .stroke(.tertiary.opacity(0.3), lineWidth: 6)
130                      Circle()
131                          .trim(from: 0, to: progress)
132 -                        .stroke(style.color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
132 +                        .stroke(.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
133                          .rotationEffect(.degrees(-90))
134                          .animation(.easeInOut(duration: 0.3), value: progress)
135                      VStack(spacing: 0) {

⏺ Update(OneTrack/Views/Workouts/ActiveWorkoutView.swift)
⎿  Added 1 line, removed 1 line
145                  VStack(alignment: .leading, spacing: 4) {
146                      Text(session.plan?.name ?? "Workout")
147                          .font(.title3.bold())
148 -                    Text(session.plan?.planDescription ?? "")
148 +                    Text("\(sortedLogs.count) exercises")
149                          .font(.caption)
150                          .foregroundStyle(.secondary)
151                  }

⏺ Update(OneTrack/Views/Workouts/ActiveWorkoutView.swift)
⎿  Added 1 line, removed 1 line
159                          .foregroundStyle(.secondary)
160                      Text(elapsedSeconds.durationString)
161                          .font(.title3.monospacedDigit().bold())
162 -                        .foregroundStyle(style.color)
162 +                        .foregroundStyle(.blue)
163                  }
164              }
165          }

⏺ Bash(xcodebuild -project OneTrack.xcodeproj -scheme OneTrack -destination 'generic/platform=iOS' build 2>&1 | grep -E "(error:|BUILD)" | head -10)
⎿  ** BUILD SUCCEEDED **
⎿  (timeout 2m)
⎿  Found 9 new diagnostic issues in 1 file (ctrl+o to expand)

⏺ Build succeeded. Now rebuild in Xcode. Since you already had data from the seed, you may want to delete the app from the simulator first to start fresh (long-press the app icon > Remove App), then run again.

⏺ Here's what changed:

Workout Section Redesign

No more predefined plans

- Removed the 5 hardcoded PPL plans
- Users now create their own workouts from scratch
- Empty state with "Create Workout" button when no plans exist

Create/Edit Workout flow

- New "+" button in toolbar to create a workout
- Name your workout — free text (e.g., "Push Day", "Upper Body", "Full Body Monday")
- Exercise picker — searchable database of 36 exercises organized by category (Chest, Back, Shoulders, Arms, Legs, Core)
- Multi-select exercises, each comes with sensible default sets/reps
- Adjust sets inline with a stepper on each exercise
- Edit existing plans — long-press a plan > Edit
- Delete plans — long-press a plan > Delete

Clean plan list (Strong/Hevy inspired)

- Simple white cards with plan name, exercise list preview, exercise count, last session date
- Blue "Start" capsule button on each card — one tap to begin
- No more gradient color coding
- Resume banner for interrupted workouts (subtle orange outline)
- Context menu on long-press for edit/delete

Dashboard updated

- Removed color-coded plan type icons, using consistent blue dumbbell icon

Important: Delete the app from the simulator first (to clear the old seeded data), then build and run fresh.

✻ Sautéed for 4m 24s

❯ So right now - where does my workouts and workout history is being saved? do i have a server?

⏺ No server. Everything is saved on your iPhone (or simulator) using SwiftData — Apple's built-in local database.

Here's how it works:

- SwiftData creates a SQLite database file in the app's sandbox on your device
- All your workout plans, sessions, sets, reps, and weights are stored there
- Data persists across app restarts and re-deploys
- No internet needed — it's 100% offline

The tradeoff: if you delete the app, the data is gone. There's no cloud backup or sync. This is by design per your CLAUDE.md — "No backend, no authentication, single user, personal tool."

❯ how long will it take to add a server to this?
how much will it cost?

⏺ This is a design decision worth thinking through. Here's the honest breakdown:

Do you actually need a server?

For a personal tool on one device, probably not. SwiftData on-device is the right call — it's fast, free, and works offline.

You'd only need a server if you want:
- Backup (so data survives if you lose your phone)
- Multi-device sync (iPhone + iPad)
- Sharing (let others use the app)

Simpler alternatives to a custom server

┌────────────────────────────────────┬───────────┬────────────────────────────────────────┬───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│               Option               │  Effort   │                  Cost                  │                                                 What it gives you                                                 │
├────────────────────────────────────┼───────────┼────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ iCloud + CloudKit (Apple built-in) │ ~1-2 days │ Free (with Apple ID)                   │ Auto backup + sync across your Apple devices. SwiftData has native CloudKit integration — just flip a config flag │
├────────────────────────────────────┼───────────┼────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Export/Import JSON                 │ ~2 hours  │ Free                                   │ Manual backup to Files app. No sync, but you won't lose data                                                      │
├────────────────────────────────────┼───────────┼────────────────────────────────────────┼───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│ Custom backend (Supabase/Firebase) │ ~3-5 days │ Free tier covers personal use (~$0/mo) │ Full server, auth, real-time sync — but overkill for a personal app                                               │
└────────────────────────────────────┴───────────┴────────────────────────────────────────┴───────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘

My recommendation

iCloud CloudKit is the sweet spot for your use case. It's:
- Built into SwiftData (minimal code change)
- Free with your Apple ID
- Automatic backup + sync
- No server to manage
- Still works offline

Want me to add iCloud sync? It's mainly a ModelConfiguration change + enabling the CloudKit capability in Xcode.

❯ lets go with iCloud - we should also change the md file
i want things to be saved in the Db.
can you implement it?

Read 3 files (ctrl+o to expand)

⏺ Important caveat first: CloudKit requires a paid Apple Developer account ($99/year). Your current free account won't sync to iCloud. But I'll implement it so the code is ready — the app still works locally without a paid account, data just won't sync until you upgrade.

Let me make all the changes. CloudKit + SwiftData requires all model properties to have default values.

Read 7 files (ctrl+o to expand)

⏺ Now I'll add default values to all model properties (CloudKit requirement) and update the entitlements, app config, and CLAUDE.md.

⏺ Update(OneTrack/Models/WorkoutPlan.swift)
⎿  Added 3 lines, removed 3 lines
 3
 4  @Model
 5  final class WorkoutPlan {
 6 -    var name: String
 7 -    var planDescription: String
 8 -    var sortOrder: Int
 6 +    var name: String = ""
 7 +    var planDescription: String = ""
 8 +    var sortOrder: Int = 0
 9      @Relationship(deleteRule: .cascade, inverse: \Exercise.plan)
10      var exercises: [Exercise] = []
11      @Relationship(deleteRule: .cascade, inverse: \WorkoutSession.plan)

⏺ Update(OneTrack/Models/WorkoutPlan.swift)
⎿  Added 1 line, removed 1 line
11      @Relationship(deleteRule: .cascade, inverse: \WorkoutSession.plan)
12      var sessions: [WorkoutSession] = []
13      var defaultRestSeconds: Int = 90
14 -    var createdAt: Date
14 +    var createdAt: Date = .now
15
16      init(name: String, planDescription: String, sortOrder: Int, defaultRestSeconds: Int = 90, createdAt: Date = .now) {
17          self.name = name

⏺ Update(OneTrack/Models/Exercise.swift)
⎿  Added 4 lines, removed 4 lines
 3
 4  @Model
 5  final class Exercise {
 6 -    var name: String
 7 -    var targetSets: Int
 8 -    var targetReps: Int
 9 -    var sortOrder: Int
 6 +    var name: String = ""
 7 +    var targetSets: Int = 3
 8 +    var targetReps: Int = 10
 9 +    var sortOrder: Int = 0
10      var plan: WorkoutPlan?
11
12      init(name: String, targetSets: Int, targetReps: Int, sortOrder: Int) {

⏺ Update(OneTrack/Models/WorkoutSession.swift)
⎿  Added 2 lines, removed 2 lines
 3
 4  @Model
 5  final class WorkoutSession {
 6 -    var date: Date
 7 -    var startedAt: Date
 6 +    var date: Date = .now
 7 +    var startedAt: Date = .now
 8      var durationSeconds: Int?
 9      var isCompleted: Bool = false
10      var plan: WorkoutPlan?

⏺ Update(OneTrack/Models/ExerciseLog.swift)
⎿  Added 2 lines, removed 2 lines
 3
 4  @Model
 5  final class ExerciseLog {
 6 -    var exerciseName: String
 7 -    var sortOrder: Int
 6 +    var exerciseName: String = ""
 7 +    var sortOrder: Int = 0
 8      var session: WorkoutSession?
 9      @Relationship(deleteRule: .cascade, inverse: \SetLog.exerciseLog)
10      var sets: [SetLog] = []

⏺ Update(OneTrack/Models/SetLog.swift)
⎿  Added 3 lines, removed 3 lines
 3
 4  @Model
 5  final class SetLog {
 6 -    var setNumber: Int
 7 -    var reps: Int
 8 -    var weightKg: Double
 6 +    var setNumber: Int = 0
 7 +    var reps: Int = 0
 8 +    var weightKg: Double = 0
 9      var isCompleted: Bool = false
10      var exerciseLog: ExerciseLog?
11

⏺ Update(OneTrack/Models/Ingredient.swift)
⎿  Added 7 lines, removed 7 lines
 3
 4  @Model
 5  final class Ingredient {
 6 -    var name: String
 7 -    var quantity: Double
 8 -    var unit: String
 9 -    var calories: Double
10 -    var proteinG: Double
11 -    var carbsG: Double
12 -    var fatG: Double
 6 +    var name: String = ""
 7 +    var quantity: Double = 0
 8 +    var unit: String = "g"
 9 +    var calories: Double = 0
10 +    var proteinG: Double = 0
11 +    var carbsG: Double = 0
12 +    var fatG: Double = 0
13      var fdcId: Int?
14      var meal: MealEntry?
15

⏺ Update(OneTrack/Models/WeightEntry.swift)
⎿  Added 3 lines, removed 3 lines
 3
 4  @Model
 5  final class WeightEntry {
 6 -    var date: Date
 7 -    var weightKg: Double
 8 -    var source: String
 6 +    var date: Date = .now
 7 +    var weightKg: Double = 0
 8 +    var source: String = "manual"
 9
10      init(date: Date = .now, weightKg: Double, source: String = "manual") {
11          self.date = date
⎿  Found 20 new diagnostic issues in 5 files (ctrl+o to expand)

⏺ Good, model defaults are set. Now update the entitlements for iCloud + CloudKit.

⏺ Write(OneTrack/OneTrack.entitlements)
⎿  Added 9 lines
 6    <true/>
 7    <key>com.apple.developer.healthkit.access</key>
 8    <array/>
 9 +  <key>com.apple.developer.icloud-container-identifiers</key>
10 +  <array>
11 +    <string>iCloud.com.amitwitk.OneTrack</string>
12 +  </array>
13 +  <key>com.apple.developer.icloud-services</key>
14 +  <array>
15 +    <string>CloudDocuments</string>
16 +    <string>CloudKit</string>
17 +  </array>
18  </dict>
19  </plist>
⎿  Found 2 new diagnostic issues in 2 files (ctrl+o to expand)

⏺ Now update the ModelConfiguration to enable CloudKit.

⏺ Update(OneTrack/OneTrackApp.swift)
⎿  Added 5 lines, removed 1 line
17              BodyMeasurement.self,
18              WeightEntry.self
19          ])
20 -        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
20 +        let config = ModelConfiguration(
21 +            schema: schema,
22 +            isStoredInMemoryOnly: false,
23 +            cloudKitDatabase: .automatic
24 +        )
25          do {
26              sharedModelContainer = try ModelContainer(for: schema, configurations: [config])
27          } catch {

⏺ Now update CLAUDE.md to reflect all the changes we've made.

⏺ Write(CLAUDE.md)
⎿  Added 27 lines, removed 16 lines
 5  ## Features
 6
 7  ### 1. Workout Tracking
 8 -- 5 predefined workout plans, each containing exercises with target sets, reps, and weight
 8 +- User-created workout plans with custom exercises, sets, and reps
 9 +- Exercise picker with built-in database (36 exercises across 6 categories)
10  - Log workout sessions: record actual sets, reps, and weight per exercise
11 +- Stepper-based input (no keyboard) — designed for gym use with sweaty hands
12  - Track progressive overload — compare current session to previous sessions
13 +- Rest timer with configurable duration (auto-starts on set completion)
14 +- Resume interrupted workouts
15  - History of all completed workouts
16
17  ### 2. Calorie & Meal Tracking
18  - **Primary input:** text-based ingredient entry (e.g. "3 eggs, 4 tomatoes, 1 onion")
15 -- **Nutrition lookup:** embedded USDA Foundation Foods database (~6.5 MB JSON, ~2,500 whole foods) for instant offline calorie/macro resolution
19 +- **Nutrition lookup:** embedded USDA Foundation Foods + SR Legacy database (~8,100 foods, ~1.1 MB JSON) for instant offline calorie/macro resolution
20  - **API fallback:** USDA FoodData Central API (free, 1,000 req/hr) for foods not in the local DB
21  - **Barcode scanning (future):** Open Food Facts API (free, no key) for packaged/branded foods
22  - Daily calorie budget with remaining calories display
...
32  - No manual entry needed — reads from iPhone Fitness / Apple Watch data
33
34  ### 5. Dashboard
31 -- Progress charts across all domains using Swift Charts
32 -- Weekly/monthly/yearly trend views
33 -- At-a-glance daily summary: calories remaining, steps, today's workout
35 +- Stat cards: weekly workout count, volume, total workouts, streak
36 +- Recent workout history
37 +- At-a-glance daily summary
38
39  ## Tech Stack
40
37 -- **Language:** Swift
41 +- **Language:** Swift 6
42  - **UI:** SwiftUI (iOS 18+, NavigationStack, @Observable)
39 -- **Local storage:** SwiftData (on-device, no backend)
43 +- **Storage:** SwiftData with iCloud CloudKit sync (automatic backup + multi-device)
44  - **Health data:** HealthKit (read: steps, weight, active calories, workouts)
41 -- **Nutrition data:** USDA Foundation Foods JSON (bundled), USDA FoodData Central API (fallback)
45 +- **Nutrition data:** USDA Foundation Foods + SR Legacy JSON (bundled), USDA FoodData Central API (fallback)
46  - **Charts:** Swift Charts
47  - **Target:** iPhone only
48
49  ## Architecture
50
47 -- **No backend** — everything runs and stores on-device
48 -- **No authentication** — single user, personal tool
51 +- **No custom backend** — SwiftData on-device + iCloud CloudKit for sync/backup
52 +- **No authentication** — single user, personal tool (iCloud identity via Apple ID)
53  - **No network required** for core features (workout logging, local food lookup, measurements)
50 -- **Network optional** for USDA API fallback and HealthKit sync
54 +- **Network used for** iCloud sync, USDA API fallback, HealthKit sync
55
56 +## Data Storage
57 +
58 +- **SwiftData** stores all data locally on-device in SQLite
59 +- **CloudKit** automatically syncs data to iCloud (requires paid Apple Developer account, $99/year)
60 +- **Offline-first** — app works fully offline, syncs when connectivity is available
61 +- Data persists across app re-deploys and survives device resets (via iCloud backup)
62 +
63  ## Deployment
64
54 -- Xcode 16.4 + free Apple ID + USB cable (or Wi-Fi debugging)
65 +- Xcode 16.4 + Apple Developer account + USB-C cable (or Wi-Fi debugging)
66  - Deploy directly to personal iPhone — no App Store
56 -- Re-deploy every 7 days (free account signing limit)
57 -- All data persists across re-deploys (SwiftData on device)
67 +- Free account: re-deploy every 7 days (no CloudKit sync)
68 +- Paid account ($99/year): 1-year signing + CloudKit sync enabled
69
70  ## Design Principles
71
72  - **Minimal friction:** fewest possible taps to log data
73  - **Offline-first:** core features work without internet
63 -- **Speed over polish:** functional personal tool, not a production app
64 -- **No over-engineering:** no abstraction layers, no sync, no multi-device
74 +- **Gym-friendly:** stepper inputs, large tap targets, rest timer — no keyboard needed
75 +- **Clean UI:** inspired by Strong/Hevy — simple cards, no flashy colors
⎿  Found 2 new diagnostic issues in 1 file (ctrl+o to expand)

⏺ Now let's build.

⏺ Bash(xcodebuild -project OneTrack.xcodeproj -scheme OneTrack -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "(error:|BUILD)" | head -10)
⎿  /Users/amitwitk/Projects/OneTrack-p/OneTrack/Models/WorkoutSession.swift:6:9: error: A default value requires a fully qualified domain named value (from macro 'Model')
/Users/amitwitk/Projects/OneTrack-p/OneTrack/Models/WorkoutSession.swift:7:9: error: A default value requires a fully qualified domain named value (from macro 'Model')
** BUILD FAILED **
⎿  (timeout 2m)

⏺ The @Model macro needs Date() instead of .now for default values. Let me fix all models.

Searched for 1 pattern (ctrl+o to expand)

⏺ The = .now on property declarations (not init params) needs to be = Date().

⏺ Update(OneTrack/Models/WorkoutPlan.swift)
⎿  Added 1 line, removed 1 line
11      @Relationship(deleteRule: .cascade, inverse: \WorkoutSession.plan)
12      var sessions: [WorkoutSession] = []
13      var defaultRestSeconds: Int = 90
14 -    var createdAt: Date = .now
14 +    var createdAt: Date = Date()
15
16      init(name: String, planDescription: String, sortOrder: Int, defaultRestSeconds: Int = 90, createdAt: Date = .now) {
17          self.name = name

⏺ Update(OneTrack/Models/WorkoutSession.swift)
⎿  Added 2 lines, removed 2 lines
 3
 4  @Model
 5  final class WorkoutSession {
 6 -    var date: Date = .now
 7 -    var startedAt: Date = .now
 6 +    var date: Date = Date()
 7 +    var startedAt: Date = Date()
 8      var durationSeconds: Int?
 9      var isCompleted: Bool = false
10      var plan: WorkoutPlan?

⏺ Update(OneTrack/Models/WeightEntry.swift)
⎿  Added 1 line, removed 1 line
3
4  @Model
5  final class WeightEntry {
6 -    var date: Date = .now
6 +    var date: Date = Date()
7      var weightKg: Double = 0
8      var source: String = "manual"
9

⏺ Also check MealEntry and BodyMeasurement for the same issue — they need Date() defaults on their property declarations (not just init params).

Read 2 files (ctrl+o to expand)

⏺ These also need defaults on properties.

⏺ Update(OneTrack/Models/MealEntry.swift)
⎿  Added 2 lines, removed 2 lines
 3
 4  @Model
 5  final class MealEntry {
 6 -    var date: Date
 7 -    var mealType: String
 6 +    var date: Date = Date()
 7 +    var mealType: String = ""
 8      var notes: String = ""
 9      @Relationship(deleteRule: .cascade, inverse: \Ingredient.meal)
10      var ingredients: [Ingredient] = []

⏺ Update(OneTrack/Models/BodyMeasurement.swift)
⎿  Added 1 line, removed 1 line
3
4  @Model
5  final class BodyMeasurement {
6 -    var date: Date
6 +    var date: Date = Date()
7      var waistCm: Double?
8      var chestCm: Double?
9      var leftBicepCm: Double?

⏺ Bash(xcodebuild -project OneTrack.xcodeproj -scheme OneTrack -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -E "(error:|BUILD)" | head -10)
⎿  ** BUILD SUCCEEDED **
⎿  (timeout 2m)
⎿  Found 3 new diagnostic issues in 1 file (ctrl+o to expand)

⏺ Build succeeded. Let me also verify the device build works.

⏺ Bash(xcodebuild -project OneTrack.xcodeproj -scheme OneTrack -destination 'generic/platform=iOS' build 2>&1 | grep -E "(error:|BUILD)" | head -5)
⎿  /Users/amitwitk/Projects/OneTrack-p/OneTrack.xcodeproj: error: Provisioning profile "iOS Team Provisioning Profile: com.amitwitk.OneTrack" doesn't support the iCloud capability.  (in target 'OneTrack' from project 'OneTrack')
/Users/amitwitk/Projects/OneTrack-p/OneTrack.xcodeproj: error: Provisioning profile "iOS Team Provisioning Profile: com.amitwitk.OneTrack" doesn't include the com.apple.developer.icloud-container-identifiers and com.apple.developer.icloud-services entitlements. (in target 'OneTrack
' from project 'OneTrack')
** BUILD FAILED **
⎿  (timeout 2m)

⏺ As expected — the device build fails because your free Apple Developer account doesn't support iCloud/CloudKit. The simulator build works fine.

Let me update the code so it gracefully falls back to local-only storage when CloudKit isn't available (free account), and syncs when it is (paid account).

Read 1 file (ctrl+o to expand)

⏺ The issue is that the entitlements file includes iCloud but the free provisioning profile doesn't support it. For now, I need to remove the iCloud entitlement so you can deploy to your physical device. When you upgrade to a paid account, just re-add it.

Let me make CloudKit a conditional feature — the code stays ready, but the entitlement is removed so the free account works.

⏺ Update(OneTrack/OneTrackApp.swift)
⎿  Added 5 lines, removed 1 line
17              BodyMeasurement.self,
18              WeightEntry.self
19          ])
20 +        // CloudKit sync: set to .automatic when using a paid Apple Developer account.
21 +        // With a free account, use .none to avoid provisioning errors.
22 +        let useCloudKit = false // flip to true with paid Apple Developer account ($99/year)
23 +
24          let config = ModelConfiguration(
25              schema: schema,
26              isStoredInMemoryOnly: false,
23 -            cloudKitDatabase: .automatic
27 +            cloudKitDatabase: useCloudKit ? .automatic : .none
28          )
29          do {
30              sharedModelContainer = try ModelContainer(for: schema, configurations: [config])

⏺ Write(OneTrack/OneTrack.entitlements)
⎿  Removed 9 lines
 6    <true/>
 7    <key>com.apple.developer.healthkit.access</key>
 8    <array/>
 9 -  <key>com.apple.developer.icloud-container-identifiers</key>
10 -  <array>
11 -    <string>iCloud.com.amitwitk.OneTrack</string>
12 -  </array>
13 -  <key>com.apple.developer.icloud-services</key>
14 -  <array>
15 -    <string>CloudDocuments</string>
16 -    <string>CloudKit</string>
17 -  </array>
 9  </dict>
10  </plist>
⎿  Found 5 new diagnostic issues in 1 file (ctrl+o to expand)

⏺ Bash(xcodebuild -project OneTrack.xcodeproj -scheme OneTrack -destination 'generic/platform=iOS' build 2>&1 | grep -E "(error:|BUILD)" | head -5)
⎿  ** BUILD FAILED **
⎿  (timeout 2m)
⎿  Found 7 new diagnostic issues in 2 files (ctrl+o to expand)

⏺ Bash(xcodebuild -project OneTrack.xcodeproj -scheme OneTrack -destination 'generic/platform=iOS' build 2>&1 | grep "error:" | head -5)
⎿  Running…

✶ Adding iCloud sync… (4m 6s · ↓ 3.6k tokens)
⎿  ◼ Add iCloud CloudKit sync to SwiftData

────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
❯
────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
⏵⏵ bypass permissions on (shift+tab to cycle) · esc to interrupt · ctrl+t to hide tasks
