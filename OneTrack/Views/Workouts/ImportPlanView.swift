import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ImportPlanView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var inputText = ""
    @State private var parsedPlans: [ParsedPlan] = []
    @State private var parseError: String?
    @State private var showFileImporter = false
    @State private var imported = false

    var body: some View {
        List {
            Section {
                TextEditor(text: $inputText)
                    .font(.system(.caption, design: .monospaced))
                    .frame(minHeight: 200)
                    .overlay(alignment: .topLeading) {
                        if inputText.isEmpty {
                            Text(placeholderText)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }
            } header: {
                HStack {
                    Text("Paste your workout plan")
                    Spacer()
                    Button("From File") {
                        showFileImporter = true
                    }
                    .font(.caption)
                }
            } footer: {
                Text("Format: `- Exercise Name: SETSxREPS` or `- Exercise Name: SETSxSECONDSs` for isometric")
                    .font(.caption2)
            }

            if let parseError {
                Section {
                    Label(parseError, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

            if !parsedPlans.isEmpty {
                ForEach(Array(parsedPlans.enumerated()), id: \.offset) { _, plan in
                    Section(plan.name) {
                        ForEach(Array(plan.exercises.enumerated()), id: \.offset) { _, exercise in
                            HStack {
                                Text(exercise.name)
                                    .font(.subheadline)
                                Spacer()
                                if exercise.isIsometric {
                                    Text("\(exercise.sets)x\(exercise.seconds)s")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.orange)
                                } else {
                                    Text("\(exercise.sets)x\(exercise.reps)")
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        if plan.rest != 90 {
                            HStack {
                                Text("Rest timer")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(plan.rest)s")
                                    .font(.caption.monospacedDigit())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Import Workout")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                if parsedPlans.isEmpty {
                    Button("Preview") { preview() }
                        .bold()
                        .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } else {
                    Button("Import (\(parsedPlans.count))") { importPlans() }
                        .bold()
                }
            }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.plainText]) { result in
            if case .success(let url) = result {
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let text = try? String(contentsOf: url, encoding: .utf8) {
                        inputText = text
                    }
                }
            }
        }
    }

    private func preview() {
        parseError = nil
        parsedPlans = []
        do {
            parsedPlans = try WorkoutPlanParser.parse(inputText)
        } catch {
            parseError = error.localizedDescription
        }
    }

    private func importPlans() {
        let descriptor = FetchDescriptor<WorkoutPlan>(sortBy: [SortDescriptor(\.sortOrder, order: .reverse)])
        var nextOrder = ((try? modelContext.fetch(descriptor).first?.sortOrder) ?? -1) + 1

        for parsed in parsedPlans {
            let plan = WorkoutPlan(
                name: parsed.name,
                planDescription: "",
                sortOrder: nextOrder,
                defaultRestSeconds: parsed.rest
            )
            modelContext.insert(plan)

            for (index, ex) in parsed.exercises.enumerated() {
                let exercise = Exercise(
                    name: ex.name,
                    targetSets: ex.sets,
                    targetReps: ex.reps,
                    sortOrder: index,
                    isIsometric: ex.isIsometric,
                    targetSeconds: ex.seconds
                )
                exercise.plan = plan
                modelContext.insert(exercise)
            }
            nextOrder += 1
        }

        try? modelContext.save()
        dismiss()
    }

    private var placeholderText: String {
        """
        ---
        name: Push Day
        rest: 90

        - Bench Press: 4x10
        - Overhead Press: 3x10
        - Lateral Raises: 3x15

        ---
        name: Pull Day

        - Deadlift: 4x6
        - Barbell Rows: 4x10
        - Plank: 3x60s
        """
    }
}
