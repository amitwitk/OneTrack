import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExportImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \WorkoutPlan.sortOrder) private var plans: [WorkoutPlan]
    @Query(filter: #Predicate<WorkoutSession> { $0.isCompleted },
           sort: \WorkoutSession.date, order: .reverse)
    private var sessions: [WorkoutSession]
    @Query(sort: \CustomExercise.name) private var customExercises: [CustomExercise]

    @State private var showShareSheet = false
    @State private var exportData: Data?
    @State private var showFileImporter = false
    @State private var importPreview: WorkoutBackup?
    @State private var showImportConfirmation = false
    @State private var importMode: WorkoutDataExporter.ImportMode = .merge
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSuccess = false
    @State private var successMessage = ""

    var body: some View {
        List {
            // Export section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Export Workout Data", systemImage: "square.and.arrow.up")
                        .font(.headline)
                    Text("\(plans.count) plans, \(sessions.count) sessions, \(customExercises.count) custom exercises")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    exportJSON()
                } label: {
                    Label("Export as JSON", systemImage: "doc.text")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
            } footer: {
                Text("Creates a JSON file you can save to Files, email, or AirDrop.")
            }

            // Import section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Import Workout Data", systemImage: "square.and.arrow.down")
                        .font(.headline)
                    Text("Restore from a previously exported JSON file.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    showFileImporter = true
                } label: {
                    Label("Import from File", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.bordered)
            }

            // Import preview
            if let preview = importPreview {
                Section("Import Preview") {
                    LabeledContent("Plans", value: "\(preview.plans.count)")
                    LabeledContent("Sessions", value: "\(preview.sessions.count)")
                    LabeledContent("Custom Exercises", value: "\(preview.customExercises.count)")
                    LabeledContent("Exported", value: preview.exportDate.shortDateTime)

                    Picker("Import Mode", selection: $importMode) {
                        Text("Merge (skip duplicates)").tag(WorkoutDataExporter.ImportMode.merge)
                        Text("Replace all data").tag(WorkoutDataExporter.ImportMode.replace)
                    }
                    .pickerStyle(.menu)

                    Button {
                        showImportConfirmation = true
                    } label: {
                        Label("Import", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }
        }
        .navigationTitle("Export / Import")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.json]) { result in
            handleFileImport(result)
        }
        .sheet(isPresented: $showShareSheet) {
            if let data = exportData {
                ShareSheet(data: data, filename: "OneTrack-Backup-\(Date.now.formatted(.dateTime.year().month().day())).json")
            }
        }
        .confirmationDialog(
            importMode == .replace ? "Replace All Data?" : "Merge Data?",
            isPresented: $showImportConfirmation
        ) {
            Button(importMode == .replace ? "Replace All" : "Merge", role: importMode == .replace ? .destructive : nil) {
                performImport()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if importMode == .replace {
                Text("This will delete ALL existing workout data and replace it with the imported data. This cannot be undone.")
            } else {
                Text("Plans with the same name will be skipped. New plans and sessions will be added.")
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
        .alert("Import Complete", isPresented: $showSuccess) {
            Button("OK", role: .cancel) { dismiss() }
        } message: {
            Text(successMessage)
        }
    }

    // MARK: - Export

    private func exportJSON() {
        let backup = WorkoutDataExporter.export(
            plans: plans,
            sessions: sessions,
            customExercises: customExercises
        )
        do {
            exportData = try WorkoutDataExporter.exportJSON(backup: backup)
            showShareSheet = true
        } catch {
            errorMessage = "Failed to export: \(error.localizedDescription)"
            showError = true
        }
    }

    // MARK: - Import

    private func handleFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Cannot access the selected file."
                showError = true
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                importPreview = try WorkoutDataExporter.importJSON(data: data)
            } catch {
                errorMessage = "Invalid backup file: \(error.localizedDescription)"
                showError = true
            }
        case .failure(let error):
            errorMessage = "File selection failed: \(error.localizedDescription)"
            showError = true
        }
    }

    private func performImport() {
        guard let backup = importPreview else { return }
        do {
            try WorkoutDataExporter.restore(backup: backup, modelContext: modelContext, mode: importMode)
            successMessage = "Imported \(backup.plans.count) plans and \(backup.sessions.count) sessions."
            importPreview = nil
            showSuccess = true
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let data: Data
    let filename: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? data.write(to: tempURL)
        return UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
