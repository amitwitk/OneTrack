import SwiftUI
import SwiftData

struct WorkoutsTabView: View {
    @State private var showingHistory = false
    @State private var showingCreatePlan = false

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
                        Button("New", systemImage: "plus") {
                            showingCreatePlan = true
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
        }
    }
}
