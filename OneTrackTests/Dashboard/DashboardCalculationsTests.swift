import Testing
import Foundation
import SwiftData
@testable import OneTrack

@Suite("Dashboard Calculations")
@MainActor
struct DashboardCalculationsTests {

    @Test func thisWeekCount_filtersToLast7Days() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let now = Date.now

        // 3 days ago — within week
        let s1 = WorkoutSession(date: Calendar.current.date(byAdding: .day, value: -3, to: now)!)
        s1.isCompleted = true
        context.insert(s1)

        // 5 days ago — within week
        let s2 = WorkoutSession(date: Calendar.current.date(byAdding: .day, value: -5, to: now)!)
        s2.isCompleted = true
        context.insert(s2)

        // 10 days ago — outside week
        let s3 = WorkoutSession(date: Calendar.current.date(byAdding: .day, value: -10, to: now)!)
        s3.isCompleted = true
        context.insert(s3)

        try context.save()

        let count = DashboardCalculations.thisWeekCount(sessions: [s1, s2, s3], now: now)
        #expect(count == 2)
    }

    @Test func streakDays_consecutive() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let now = Date.now

        var sessions: [WorkoutSession] = []
        for dayOffset in 0..<3 {
            let s = WorkoutSession(date: Calendar.current.date(byAdding: .day, value: -dayOffset, to: now)!)
            s.isCompleted = true
            context.insert(s)
            sessions.append(s)
        }
        try context.save()

        #expect(DashboardCalculations.streakDays(sessions: sessions, now: now) == 3)
    }

    @Test func streakDays_gapBreaksStreak() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let now = Date.now

        let s1 = WorkoutSession(date: now)
        s1.isCompleted = true
        context.insert(s1)

        let s2 = WorkoutSession(date: Calendar.current.date(byAdding: .day, value: -3, to: now)!)
        s2.isCompleted = true
        context.insert(s2)

        try context.save()

        #expect(DashboardCalculations.streakDays(sessions: [s1, s2], now: now) == 1)
    }

    @Test func streakDays_empty() {
        #expect(DashboardCalculations.streakDays(sessions: []) == 0)
    }

    @Test func totalVolume_formatsThousands() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let session = WorkoutSession()
        session.isCompleted = true
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Bench", sortOrder: 0)
        log.session = session
        context.insert(log)

        // 10 reps x 150kg = 1500 volume
        let setLog = SetLog(setNumber: 1, reps: 10, weightKg: 150)
        setLog.isCompleted = true
        setLog.exerciseLog = log
        context.insert(setLog)
        try context.save()

        let result = DashboardCalculations.totalVolume(sessions: [session])
        #expect(result == "1.5k")
    }

    @Test func totalVolume_formatsBelowThousand() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let session = WorkoutSession()
        session.isCompleted = true
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Curl", sortOrder: 0)
        log.session = session
        context.insert(log)

        let setLog = SetLog(setNumber: 1, reps: 10, weightKg: 20)
        setLog.isCompleted = true
        setLog.exerciseLog = log
        context.insert(setLog)
        try context.save()

        let result = DashboardCalculations.totalVolume(sessions: [session])
        #expect(result == "200")
    }

    @Test func totalVolume_excludesWarmUpSets() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let session = WorkoutSession()
        session.isCompleted = true
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Bench", sortOrder: 0)
        log.session = session
        context.insert(log)

        // Working set: 10 reps x 100kg = 1000
        let workingSet = SetLog(setNumber: 1, reps: 10, weightKg: 100)
        workingSet.isCompleted = true
        workingSet.exerciseLog = log
        context.insert(workingSet)

        // Warm-up set: 10 reps x 50kg = 500 (should be excluded)
        let warmUpSet = SetLog(setNumber: 2, reps: 10, weightKg: 50, setType: .warmUp)
        warmUpSet.isCompleted = true
        warmUpSet.exerciseLog = log
        context.insert(warmUpSet)

        try context.save()

        let result = DashboardCalculations.totalVolume(sessions: [session])
        #expect(result == "1.0k")
    }

    @Test func greeting_morning() {
        var components = Calendar.current.dateComponents(in: .current, from: .now)
        components.hour = 8
        let morning = Calendar.current.date(from: components)!
        #expect(DashboardCalculations.greeting(for: morning) == "Good Morning")
    }

    @Test func greeting_afternoon() {
        var components = Calendar.current.dateComponents(in: .current, from: .now)
        components.hour = 14
        let afternoon = Calendar.current.date(from: components)!
        #expect(DashboardCalculations.greeting(for: afternoon) == "Good Afternoon")
    }

    @Test func greeting_evening() {
        var components = Calendar.current.dateComponents(in: .current, from: .now)
        components.hour = 20
        let evening = Calendar.current.date(from: components)!
        #expect(DashboardCalculations.greeting(for: evening) == "Good Evening")
    }
}
