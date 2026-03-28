import Testing
import Foundation
import SwiftData
@testable import OneTrack

@Suite("Workout Sync Payload")
@MainActor
struct WorkoutSyncPayloadTests {

    @Test func roundTrip_preservesAllData() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        // Create a session with exercises and sets
        let plan = WorkoutPlan(name: "Push Day", planDescription: "", sortOrder: 0)
        context.insert(plan)

        let session = WorkoutSession(date: .now, plan: plan)
        session.startedAt = Date.now.addingTimeInterval(-3600)
        session.durationSeconds = 3600
        session.isCompleted = true
        session.rpe = 8
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Bench Press", sortOrder: 0, section: "Chest")
        log.notes = "Felt strong"
        log.session = session
        context.insert(log)

        let set1 = SetLog(setNumber: 1, reps: 10, weightKg: 80)
        set1.isCompleted = true
        set1.isPersonalRecord = true
        set1.exerciseLog = log
        context.insert(set1)

        let set2 = SetLog(setNumber: 2, reps: 8, weightKg: 85, setType: .toFailure)
        set2.isCompleted = true
        set2.exerciseLog = log
        context.insert(set2)

        try context.save()

        // Serialize
        let payload = WorkoutSyncPayload.from(session: session)

        // Encode to JSON and back
        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WorkoutSyncPayload.self, from: data)

        // Verify
        #expect(decoded.planName == "Push Day")
        #expect(decoded.durationSeconds == 3600)
        #expect(decoded.rpe == 8)
        #expect(decoded.exercises.count == 1)

        let ex = decoded.exercises[0]
        #expect(ex.name == "Bench Press")
        #expect(ex.section == "Chest")
        #expect(ex.notes == "Felt strong")
        #expect(ex.sets.count == 2)
        #expect(ex.sets[0].isPersonalRecord == true)
        #expect(ex.sets[0].weightKg == 80)
        #expect(ex.sets[1].setType == "toFailure")
        #expect(ex.sets[1].reps == 8)
    }

    @Test func roundTrip_toSession_createsModels() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let payload = WorkoutSyncPayload(
            planName: "Test",
            startDate: .now.addingTimeInterval(-1800),
            endDate: .now,
            durationSeconds: 1800,
            rpe: 6,
            exercises: [
                .init(
                    name: "Squat",
                    section: "Legs",
                    isIsometric: false,
                    notes: "Deep squats",
                    sets: [
                        .init(setNumber: 1, reps: 5, seconds: 0, weightKg: 100, isCompleted: true, isPersonalRecord: false, setType: "normal"),
                        .init(setNumber: 2, reps: 5, seconds: 0, weightKg: 100, isCompleted: true, isPersonalRecord: true, setType: "normal")
                    ]
                )
            ]
        )

        let session = payload.toSession(modelContext: context)
        #expect(session.isCompleted)
        #expect(session.durationSeconds == 1800)
        #expect(session.rpe == 6)
        #expect(session.exerciseLogs.count == 1)

        let log = session.exerciseLogs[0]
        #expect(log.exerciseName == "Squat")
        #expect(log.section == "Legs")
        #expect(log.notes == "Deep squats")
        #expect(log.sets.count == 2)

        let sets = log.sets.sorted { $0.setNumber < $1.setNumber }
        #expect(sets[1].isPersonalRecord)
        #expect(sets[0].weightKg == 100)
    }

    @Test func emptyExercises() throws {
        let payload = WorkoutSyncPayload(
            planName: "Empty",
            startDate: .now,
            endDate: .now,
            durationSeconds: 0,
            rpe: nil,
            exercises: []
        )

        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(WorkoutSyncPayload.self, from: data)
        #expect(decoded.exercises.isEmpty)
        #expect(decoded.rpe == nil)
    }

    @Test func emptySet_exerciseWithNoSets() throws {
        let payload = WorkoutSyncPayload(
            planName: "Test",
            startDate: .now,
            endDate: .now,
            durationSeconds: 0,
            rpe: nil,
            exercises: [
                .init(name: "Plank", section: "", isIsometric: true, notes: "", sets: [])
            ]
        )

        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(WorkoutSyncPayload.self, from: data)
        #expect(decoded.exercises[0].sets.isEmpty)
        #expect(decoded.exercises[0].isIsometric)
    }
}
