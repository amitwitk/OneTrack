import Testing
import Foundation
import SwiftData
@testable import OneTrack

@Suite("Dashboard Chart Calculations")
@MainActor
struct DashboardChartTests {

    // MARK: - Daily Volume

    @Test func dailyVolume_returns7Days() {
        let result = DashboardCalculations.dailyVolume(sessions: [])
        #expect(result.count == 7)
    }

    @Test func dailyVolume_emptySessionsAllZero() {
        let result = DashboardCalculations.dailyVolume(sessions: [])
        #expect(result.allSatisfy { $0.volume == 0 })
    }

    @Test func dailyVolume_calculatesCorrectly() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let now = Date.now
        let today = Calendar.current.startOfDay(for: now)

        let session = WorkoutSession(date: today)
        session.isCompleted = true
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Bench", sortOrder: 0)
        log.session = session
        context.insert(log)

        // 10 reps x 50kg = 500 volume
        let set1 = SetLog(setNumber: 1, reps: 10, weightKg: 50)
        set1.isCompleted = true
        set1.exerciseLog = log
        context.insert(set1)

        // 8 reps x 60kg = 480 volume
        let set2 = SetLog(setNumber: 2, reps: 8, weightKg: 60)
        set2.isCompleted = true
        set2.exerciseLog = log
        context.insert(set2)

        try context.save()

        let result = DashboardCalculations.dailyVolume(sessions: [session], now: now)
        let todayEntry = result.last!
        #expect(todayEntry.volume == 980)
    }

    @Test func dailyVolume_excludesWarmUpSets() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let now = Date.now
        let today = Calendar.current.startOfDay(for: now)

        let session = WorkoutSession(date: today)
        session.isCompleted = true
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Squat", sortOrder: 0)
        log.session = session
        context.insert(log)

        let workingSet = SetLog(setNumber: 1, reps: 10, weightKg: 100)
        workingSet.isCompleted = true
        workingSet.exerciseLog = log
        context.insert(workingSet)

        let warmUpSet = SetLog(setNumber: 2, reps: 10, weightKg: 50, setType: .warmUp)
        warmUpSet.isCompleted = true
        warmUpSet.exerciseLog = log
        context.insert(warmUpSet)

        try context.save()

        let result = DashboardCalculations.dailyVolume(sessions: [session], now: now)
        let todayEntry = result.last!
        #expect(todayEntry.volume == 1000) // only working set
    }

    @Test func dailyVolume_excludesOldSessions() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let now = Date.now

        let oldDate = Calendar.current.date(byAdding: .day, value: -10, to: now)!
        let session = WorkoutSession(date: oldDate)
        session.isCompleted = true
        context.insert(session)

        let log = ExerciseLog(exerciseName: "Bench", sortOrder: 0)
        log.session = session
        context.insert(log)

        let set1 = SetLog(setNumber: 1, reps: 10, weightKg: 100)
        set1.isCompleted = true
        set1.exerciseLog = log
        context.insert(set1)

        try context.save()

        let result = DashboardCalculations.dailyVolume(sessions: [session], now: now)
        #expect(result.allSatisfy { $0.volume == 0 })
    }

    // MARK: - Weekly Frequency

    @Test func weeklyFrequency_returns4Weeks() {
        let result = DashboardCalculations.weeklyFrequency(sessions: [])
        #expect(result.count == 4)
    }

    @Test func weeklyFrequency_emptySessionsAllZero() {
        let result = DashboardCalculations.weeklyFrequency(sessions: [])
        #expect(result.allSatisfy { $0.count == 0 })
    }

    @Test func weeklyFrequency_countsCorrectly() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let now = Date.now

        // 2 sessions this week
        let s1 = WorkoutSession(date: now)
        s1.isCompleted = true
        context.insert(s1)

        let s2 = WorkoutSession(date: Calendar.current.date(byAdding: .day, value: -1, to: now)!)
        s2.isCompleted = true
        context.insert(s2)

        // 1 session last week
        let s3 = WorkoutSession(date: Calendar.current.date(byAdding: .day, value: -8, to: now)!)
        s3.isCompleted = true
        context.insert(s3)

        try context.save()

        let result = DashboardCalculations.weeklyFrequency(sessions: [s1, s2, s3], now: now)
        let lastWeek = result.last!
        #expect(lastWeek.count == 2)
    }

    // MARK: - Weight Trend

    @Test func weightTrend_emptyReturnsEmpty() {
        let result = DashboardCalculations.weightTrend(entries: [])
        #expect(result.isEmpty)
    }

    @Test func weightTrend_filtersByDays() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let now = Date.now

        let recent = WeightEntry(date: Calendar.current.date(byAdding: .day, value: -5, to: now)!, weightKg: 80)
        context.insert(recent)

        let old = WeightEntry(date: Calendar.current.date(byAdding: .day, value: -60, to: now)!, weightKg: 85)
        context.insert(old)

        try context.save()

        let result = DashboardCalculations.weightTrend(entries: [recent, old], days: 30, now: now)
        #expect(result.count == 1)
        #expect(result[0].weightKg == 80)
    }

    @Test func weightTrend_sortedByDate() throws {
        let container = try makeTestContainer()
        let context = container.mainContext
        let now = Date.now

        let e1 = WeightEntry(date: Calendar.current.date(byAdding: .day, value: -10, to: now)!, weightKg: 82)
        let e2 = WeightEntry(date: Calendar.current.date(byAdding: .day, value: -5, to: now)!, weightKg: 80)
        let e3 = WeightEntry(date: Calendar.current.date(byAdding: .day, value: -1, to: now)!, weightKg: 79)
        context.insert(e1)
        context.insert(e2)
        context.insert(e3)
        try context.save()

        let result = DashboardCalculations.weightTrend(entries: [e3, e1, e2], days: 30, now: now)
        #expect(result.count == 3)
        #expect(result[0].weightKg == 82)
        #expect(result[1].weightKg == 80)
        #expect(result[2].weightKg == 79)
    }
}
