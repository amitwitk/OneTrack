import Foundation
import SwiftData

/// Codable payload for cross-device workout sync (watchOS ↔ iPhone).
struct WorkoutSyncPayload: Codable, Sendable {
    let planName: String
    let startDate: Date
    let endDate: Date
    let durationSeconds: Int
    let rpe: Int?
    let exercises: [ExercisePayload]

    struct ExercisePayload: Codable, Sendable {
        let name: String
        let section: String
        let isIsometric: Bool
        let notes: String
        let sets: [SetPayload]
    }

    struct SetPayload: Codable, Sendable {
        let setNumber: Int
        let reps: Int
        let seconds: Int
        let weightKg: Double
        let isCompleted: Bool
        let isPersonalRecord: Bool
        let setType: String
    }

    // MARK: - Serialize from WorkoutSession

    static func from(session: WorkoutSession) -> WorkoutSyncPayload {
        let exercises = session.exerciseLogs
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { log in
                ExercisePayload(
                    name: log.exerciseName,
                    section: log.section,
                    isIsometric: log.isIsometric,
                    notes: log.notes,
                    sets: log.sets
                        .sorted { $0.setNumber < $1.setNumber }
                        .map { set in
                            SetPayload(
                                setNumber: set.setNumber,
                                reps: set.reps,
                                seconds: set.seconds,
                                weightKg: set.weightKg,
                                isCompleted: set.isCompleted,
                                isPersonalRecord: set.isPersonalRecord,
                                setType: set.setTypeRaw
                            )
                        }
                )
            }

        return WorkoutSyncPayload(
            planName: session.plan?.name ?? "Workout",
            startDate: session.startedAt,
            endDate: session.date,
            durationSeconds: session.durationSeconds ?? 0,
            rpe: session.rpe,
            exercises: exercises
        )
    }

    // MARK: - Deserialize into SwiftData models

    @MainActor
    func toSession(modelContext: ModelContext) -> WorkoutSession {
        let session = WorkoutSession(date: endDate)
        session.startedAt = startDate
        session.durationSeconds = durationSeconds
        session.isCompleted = true
        session.rpe = rpe
        modelContext.insert(session)

        for (index, exPayload) in exercises.enumerated() {
            let log = ExerciseLog(
                exerciseName: exPayload.name,
                sortOrder: index,
                isIsometric: exPayload.isIsometric,
                section: exPayload.section
            )
            log.notes = exPayload.notes
            log.session = session
            modelContext.insert(log)

            for setPayload in exPayload.sets {
                let setLog = SetLog(
                    setNumber: setPayload.setNumber,
                    reps: setPayload.reps,
                    seconds: setPayload.seconds,
                    weightKg: setPayload.weightKg
                )
                setLog.isCompleted = setPayload.isCompleted
                setLog.isPersonalRecord = setPayload.isPersonalRecord
                setLog.setTypeRaw = setPayload.setType
                setLog.exerciseLog = log
                modelContext.insert(setLog)
            }
        }

        return session
    }
}
