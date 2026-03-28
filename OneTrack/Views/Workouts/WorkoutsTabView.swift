import SwiftUI
import SwiftData

struct WorkoutsTabView: View {
    @State private var showingHistory = false
    @State private var showingCreatePlan = false
    @State private var showingImport = false
    @State private var showingExportImport = false

    var body: some View {
        NavigationStack {
            WorkoutPlanListView(showCreatePlan: $showingCreatePlan)
                .navigationTitle("Workouts")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("History", systemImage: "clock.arrow.circlepath") {
                            showingHistory = true
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                showingCreatePlan = true
                            } label: {
                                Label("New Workout", systemImage: "plus")
                            }
                            Button {
                                showingImport = true
                            } label: {
                                Label("Import from Text", systemImage: "doc.text")
                            }

                            Divider()

                            Button {
                                showingExportImport = true
                            } label: {
                                Label("Export / Import Data", systemImage: "arrow.up.arrow.down.circle")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingHistory) {
                    NavigationStack {
                        WorkoutHistoryView()
                            .navigationTitle("History")
                            .toolbar {
                                ToolbarItem(placement: .topBarLeading) {
                                    Button("Done") { showingHistory = false }
                                }
                            }
                    }
                }
                .sheet(isPresented: $showingCreatePlan) {
                    NavigationStack {
                        CreatePlanView()
                    }
                }
                .sheet(isPresented: $showingImport) {
                    NavigationStack {
                        ImportPlanView()
                    }
                }
                .sheet(isPresented: $showingExportImport) {
                    NavigationStack {
                        ExportImportView()
                    }
                }
        }
    }
}
