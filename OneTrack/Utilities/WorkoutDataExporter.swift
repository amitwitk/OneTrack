import Foundation
import SwiftData

// MARK: - Export/Import Data Model

struct WorkoutBackup: Codable, Sendable {
    let exportDate: Date
    let appVersion: String
    let plans: [PlanExport]
    let sessions: [SessionExport]
    let customExercises: [CustomExerciseExport]

    struct PlanExport: Codable, Sendable {
        let name: String
        let description: String
        let sortOrder: Int
        let defaultRestSeconds: Int
        let knownGroups: [String]
        let exercises: [ExerciseExport]
    }

    struct ExerciseExport: Codable, Sendable {
        let name: String
        let targetSets: Int
        let targetReps: Int
        let isIsometric: Bool
        let targetSeconds: Int
        let section: String
        let sortOrder: Int
        let restSeconds: Int?
    }

    struct SessionExport: Codable, Sendable {
        let planName: String
        let date: Date
        let durationSeconds: Int?
        let isCompleted: Bool
        let notes: String
        let rpe: Int?
        let exercises: [ExerciseLogExport]
    }

    struct ExerciseLogExport: Codable, Sendable {
        let exerciseName: String
        let isIsometric: Bool
        let section: String
        let sortOrder: Int
        let notes: String
        let sets: [SetLogExport]
    }

    struct SetLogExport: Codable, Sendable {
        let setNumber: Int
        let reps: Int
        let seconds: Int
        let weightKg: Double
        let isCompleted: Bool
        let isPersonalRecord: Bool
        let setType: String
    }

    struct CustomExerciseExport: Codable, Sendable {
        let name: String
        let category: String
        let defaultSets: Int
        let defaultReps: Int
        let isIsometric: Bool
        let defaultSeconds: Int
    }
}

// MARK: - Exporter

struct WorkoutDataExporter {

    static func export(
        plans: [WorkoutPlan],
        sessions: [WorkoutSession],
        customExercises: [CustomExercise]
    ) -> WorkoutBackup {
        let planExports = plans
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { plan in
                WorkoutBackup.PlanExport(
                    name: plan.name,
                    description: plan.planDescription,
                    sortOrder: plan.sortOrder,
                    defaultRestSeconds: plan.defaultRestSeconds,
                    knownGroups: plan.knownGroups,
                    exercises: plan.exercises
                        .sorted { $0.sortOrder < $1.sortOrder }
                        .map { ex in
                            WorkoutBackup.ExerciseExport(
                                name: ex.name,
                                targetSets: ex.targetSets,
                                targetReps: ex.targetReps,
                                isIsometric: ex.isIsometric,
                                targetSeconds: ex.targetSeconds,
                                section: ex.section,
                                sortOrder: ex.sortOrder,
                                restSeconds: ex.restSeconds
                            )
                        }
                )
            }

        let sessionExports = sessions
            .filter { $0.isCompleted }
            .sorted { $0.date < $1.date }
            .map { session in
                WorkoutBackup.SessionExport(
                    planName: session.plan?.name ?? "Unknown",
                    date: session.date,
                    durationSeconds: session.durationSeconds,
                    isCompleted: session.isCompleted,
                    notes: session.notes,
                    rpe: session.rpe,
                    exercises: session.exerciseLogs
                        .sorted { $0.sortOrder < $1.sortOrder }
                        .map { log in
                            WorkoutBackup.ExerciseLogExport(
                                exerciseName: log.exerciseName,
                                isIsometric: log.isIsometric,
                                section: log.section,
                                sortOrder: log.sortOrder,
                                notes: log.notes,
                                sets: log.sets
                                    .sorted { $0.setNumber < $1.setNumber }
                                    .map { s in
                                        WorkoutBackup.SetLogExport(
                                            setNumber: s.setNumber,
                                            reps: s.reps,
                                            seconds: s.seconds,
                                            weightKg: s.weightKg,
                                            isCompleted: s.isCompleted,
                                            isPersonalRecord: s.isPersonalRecord,
                                            setType: s.setTypeRaw
                                        )
                                    }
                            )
                        }
                )
            }

        let customExerciseExports = customExercises.map { ce in
            WorkoutBackup.CustomExerciseExport(
                name: ce.name,
                category: ce.category,
                defaultSets: ce.defaultSets,
                defaultReps: ce.defaultReps,
                isIsometric: ce.isIsometric,
                defaultSeconds: ce.defaultSeconds
            )
        }

        return WorkoutBackup(
            exportDate: .now,
            appVersion: "1.0",
            plans: planExports,
            sessions: sessionExports,
            customExercises: customExerciseExports
        )
    }

    static func exportJSON(backup: WorkoutBackup) throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(backup)
    }

    static func importJSON(data: Data) throws -> WorkoutBackup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(WorkoutBackup.self, from: data)
    }

    enum ImportMode {
        case replace
        case merge
    }

    static func restore(backup: WorkoutBackup, modelContext: ModelContext, mode: ImportMode) throws {
        if mode == .replace {
            try deleteAllData(modelContext: modelContext)
        }

        let existingPlanNames = mode == .merge ? Set(fetchExistingPlanNames(modelContext: modelContext)) : []
        let existingCustomNames = mode == .merge ? Set(fetchExistingCustomExerciseNames(modelContext: modelContext)) : []

        // Restore plans
        for (index, planExport) in backup.plans.enumerated() {
            if mode == .merge && existingPlanNames.contains(planExport.name) {
                continue
            }

            let plan = WorkoutPlan(
                name: planExport.name,
                planDescription: planExport.description,
                sortOrder: mode == .merge ? 1000 + index : planExport.sortOrder,
                defaultRestSeconds: planExport.defaultRestSeconds
            )
            plan.knownGroups = planExport.knownGroups
            modelContext.insert(plan)

            for exExport in planExport.exercises {
                let exercise = Exercise(
                    name: exExport.name,
                    targetSets: exExport.targetSets,
                    targetReps: exExport.targetReps,
                    sortOrder: exExport.sortOrder,
                    isIsometric: exExport.isIsometric,
                    targetSeconds: exExport.targetSeconds,
                    restSeconds: exExport.restSeconds,
                    section: exExport.section
                )
                exercise.plan = plan
                modelContext.insert(exercise)
            }

            // Restore sessions linked to this plan
            let planSessions = backup.sessions.filter { $0.planName == planExport.name }
            for sessionExport in planSessions {
                let session = WorkoutSession(date: sessionExport.date, plan: plan)
                session.durationSeconds = sessionExport.durationSeconds
                session.isCompleted = sessionExport.isCompleted
                session.notes = sessionExport.notes
                session.rpe = sessionExport.rpe
                modelContext.insert(session)

                for logExport in sessionExport.exercises {
                    let log = ExerciseLog(
                        exerciseName: logExport.exerciseName,
                        sortOrder: logExport.sortOrder,
                        isIsometric: logExport.isIsometric,
                        section: logExport.section
                    )
                    log.notes = logExport.notes
                    log.session = session
                    modelContext.insert(log)

                    for setExport in logExport.sets {
                        let setLog = SetLog(
                            setNumber: setExport.setNumber,
                            reps: setExport.reps,
                            seconds: setExport.seconds,
                            weightKg: setExport.weightKg,
                            setType: SetType(rawValue: setExport.setType) ?? .normal
                        )
                        setLog.isCompleted = setExport.isCompleted
                        setLog.isPersonalRecord = setExport.isPersonalRecord
                        setLog.exerciseLog = log
                        modelContext.insert(setLog)
                    }
                }
            }
        }

        // Restore custom exercises
        for ceExport in backup.customExercises {
            if mode == .merge && existingCustomNames.contains(ceExport.name) {
                continue
            }
            let ce = CustomExercise(
                name: ceExport.name,
                category: ceExport.category,
                defaultSets: ceExport.defaultSets,
                defaultReps: ceExport.defaultReps,
                isIsometric: ceExport.isIsometric,
                defaultSeconds: ceExport.defaultSeconds
            )
            modelContext.insert(ce)
        }

        try modelContext.save()
    }

    // MARK: - Helpers

    private static func deleteAllData(modelContext: ModelContext) throws {
        try modelContext.delete(model: WorkoutSession.self)
        try modelContext.delete(model: ExerciseLog.self)
        try modelContext.delete(model: SetLog.self)
        try modelContext.delete(model: Exercise.self)
        try modelContext.delete(model: WorkoutPlan.self)
        try modelContext.delete(model: CustomExercise.self)
    }

    private static func fetchExistingPlanNames(modelContext: ModelContext) -> [String] {
        let descriptor = FetchDescriptor<WorkoutPlan>()
        return (try? modelContext.fetch(descriptor).map(\.name)) ?? []
    }

    private static func fetchExistingCustomExerciseNames(modelContext: ModelContext) -> [String] {
        let descriptor = FetchDescriptor<CustomExercise>()
        return (try? modelContext.fetch(descriptor).map(\.name)) ?? []
    }
}
