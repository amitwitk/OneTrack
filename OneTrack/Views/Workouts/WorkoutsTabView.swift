import SwiftUI
import SwiftData

struct WorkoutsTabView: View {
    @State private var showingHistory = false
    @State private var showingCreatePlan = false
    @State private var showingImport = false

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
        }
    }
}
