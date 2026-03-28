import Testing
import Foundation
import SwiftData
@testable import OneTrack

@Suite("Workout Data Exporter")
@MainActor
struct WorkoutDataExporterTests {

    // MARK: - Export

    @Test func exportPlansWithExercises() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let plan = WorkoutPlan(name: "Push Day", planDescription: "Chest focus", sortOrder: 0, defaultRestSeconds: 120)
        plan.knownGroups = ["Main", "Accessories"]
        context.insert(plan)

        let ex1 = Exercise(name: "Bench Press", targetSets: 4, targetReps: 10, sortOrder: 0, section: "Main")
        ex1.plan = plan
        context.insert(ex1)

        let ex2 = Exercise(name: "Plank", targetSets: 3, targetReps: 0, sortOrder: 1, isIsometric: true, targetSeconds: 60, section: "Accessories")
        ex2.plan = plan
        context.insert(ex2)
        try context.save()

        let backup = WorkoutDataExporter.export(plans: [plan], sessions: [], customExercises: [])

        #expect(backup.plans.count == 1)
        #expect(backup.plans[0].name == "Push Day")
        #expect(backup.plans[0].defaultRestSeconds == 120)
        #expect(backup.plans[0].knownGroups == ["Main", "Accessories"])
        #expect(backup.plans[0].exercises.count == 2)
        #expect(backup.plans[0].exercises[0].name == "Bench Press")
        #expect(backup.plans[0].exercises[1].isIsometric)
        #expect(backup.plans[0].exercises[1].targetSeconds == 60)
    }

    @Test func exportSessionsWithSets() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let plan = WorkoutPlan(name: "Legs", planDescription: "", sortOrder: 0)
        context.insert(plan)

        let session = WorkoutSession(date: .now, plan: plan)
        session.isCompleted = true
        session.durationSeconds = 3600
        session.rpe = 8
        session.notes = "Felt strong"
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Squat", sortOrder: 0)
        log.session = session
        log.notes = "Go deeper"
        context.insert(log)

        let set1 = SetLog(setNumber: 1, reps: 5, weightKg: 100)
        set1.isCompleted = true
        set1.isPersonalRecord = true
        set1.exerciseLog = log
        context.insert(set1)

        let set2 = SetLog(setNumber: 2, reps: 5, weightKg: 100, setType: .dropSet)
        set2.isCompleted = true
        set2.exerciseLog = log
        context.insert(set2)
        try context.save()

        let backup = WorkoutDataExporter.export(plans: [plan], sessions: [session], customExercises: [])

        #expect(backup.sessions.count == 1)
        #expect(backup.sessions[0].planName == "Legs")
        #expect(backup.sessions[0].rpe == 8)
        #expect(backup.sessions[0].notes == "Felt strong")
        #expect(backup.sessions[0].exercises[0].notes == "Go deeper")
        #expect(backup.sessions[0].exercises[0].sets.count == 2)
        #expect(backup.sessions[0].exercises[0].sets[0].isPersonalRecord)
        #expect(backup.sessions[0].exercises[0].sets[1].setType == "dropSet")
    }

    @Test func exportCustomExercises() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let ce = CustomExercise(name: "Hip Thrust", category: "Legs", defaultSets: 4, defaultReps: 12)
        context.insert(ce)
        try context.save()

        let backup = WorkoutDataExporter.export(plans: [], sessions: [], customExercises: [ce])

        #expect(backup.customExercises.count == 1)
        #expect(backup.customExercises[0].name == "Hip Thrust")
        #expect(backup.customExercises[0].category == "Legs")
    }

    // MARK: - JSON Round-Trip

    @Test func roundTrip_preservesAllData() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let plan = WorkoutPlan(name: "Test Plan", planDescription: "A plan", sortOrder: 0, defaultRestSeconds: 90)
        plan.knownGroups = ["Group A"]
        context.insert(plan)

        let ex = Exercise(name: "Bench", targetSets: 3, targetReps: 10, sortOrder: 0, section: "Group A")
        ex.plan = plan
        context.insert(ex)

        let session = WorkoutSession(date: .now, plan: plan)
        session.isCompleted = true
        session.durationSeconds = 1800
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Bench", sortOrder: 0)
        log.session = session
        context.insert(log)

        let setLog = SetLog(setNumber: 1, reps: 10, weightKg: 80)
        setLog.isCompleted = true
        setLog.exerciseLog = log
        context.insert(setLog)

        let ce = CustomExercise(name: "Custom Ex", category: "Other")
        context.insert(ce)
        try context.save()

        // Export
        let backup = WorkoutDataExporter.export(plans: [plan], sessions: [session], customExercises: [ce])
        let json = try WorkoutDataExporter.exportJSON(backup: backup)

        // Import
        let restored = try WorkoutDataExporter.importJSON(data: json)

        #expect(restored.plans.count == 1)
        #expect(restored.plans[0].name == "Test Plan")
        #expect(restored.plans[0].knownGroups == ["Group A"])
        #expect(restored.plans[0].exercises.count == 1)
        #expect(restored.sessions.count == 1)
        #expect(restored.sessions[0].exercises[0].sets.count == 1)
        #expect(restored.sessions[0].exercises[0].sets[0].weightKg == 80)
        #expect(restored.customExercises.count == 1)
        #expect(restored.customExercises[0].name == "Custom Ex")
    }

    // MARK: - Import

    @Test func importEmptyBackup() throws {
        let backup = WorkoutBackup(
            exportDate: .now,
            appVersion: "1.0",
            plans: [],
            sessions: [],
            customExercises: []
        )
        let json = try WorkoutDataExporter.exportJSON(backup: backup)
        let restored = try WorkoutDataExporter.importJSON(data: json)

        #expect(restored.plans.isEmpty)
        #expect(restored.sessions.isEmpty)
        #expect(restored.customExercises.isEmpty)
    }

    @Test func importMalformedJSON() {
        let badJSON = Data("{ invalid json }".utf8)
        #expect(throws: DecodingError.self) {
            try WorkoutDataExporter.importJSON(data: badJSON)
        }
    }

    @Test func restoreReplace() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        // Pre-existing data
        let existingPlan = WorkoutPlan(name: "Old Plan", planDescription: "", sortOrder: 0)
        context.insert(existingPlan)
        try context.save()

        // Backup to import
        let backup = WorkoutBackup(
            exportDate: .now,
            appVersion: "1.0",
            plans: [
                WorkoutBackup.PlanExport(
                    name: "New Plan",
                    description: "",
                    sortOrder: 0,
                    defaultRestSeconds: 90,
                    knownGroups: [],
                    exercises: []
                )
            ],
            sessions: [],
            customExercises: []
        )

        try WorkoutDataExporter.restore(backup: backup, modelContext: context, mode: .replace)

        let plans = try context.fetch(FetchDescriptor<WorkoutPlan>())
        #expect(plans.count == 1)
        #expect(plans[0].name == "New Plan")
    }

    @Test func restoreMergeSkipsDuplicates() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let existingPlan = WorkoutPlan(name: "Keep Me", planDescription: "original", sortOrder: 0)
        context.insert(existingPlan)
        try context.save()

        let backup = WorkoutBackup(
            exportDate: .now,
            appVersion: "1.0",
            plans: [
                WorkoutBackup.PlanExport(
                    name: "Keep Me",
                    description: "imported",
                    sortOrder: 0,
                    defaultRestSeconds: 90,
                    knownGroups: [],
                    exercises: []
                ),
                WorkoutBackup.PlanExport(
                    name: "New Plan",
                    description: "",
                    sortOrder: 1,
                    defaultRestSeconds: 90,
                    knownGroups: [],
                    exercises: []
                )
            ],
            sessions: [],
            customExercises: []
        )

        try WorkoutDataExporter.restore(backup: backup, modelContext: context, mode: .merge)

        let plans = try context.fetch(FetchDescriptor<WorkoutPlan>())
        #expect(plans.count == 2) // original + new, not duplicate
        let keepMe = plans.first(where: { $0.name == "Keep Me" })
        #expect(keepMe?.planDescription == "original") // not overwritten
    }
}
