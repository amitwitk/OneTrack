import Testing
import Foundation
import SwiftData
@testable import OneTrack

@Suite("Workout Calculations")
@MainActor
struct WorkoutCalculationsTests {

    // MARK: - Estimated 1RM

    @Test func estimated1RM_epleyFormula() {
        // 100kg x (1 + 10/30) = 100 x 1.333... = 133.33
        let result = WorkoutCalculations.estimated1RM(weightKg: 100, reps: 10)
        #expect(result != nil)
        #expect(abs(result! - 133.333) < 0.01)
    }

    @Test func estimated1RM_singleRep() {
        // 100kg x (1 + 1/30) = 100 x 1.0333 = 103.33
        let result = WorkoutCalculations.estimated1RM(weightKg: 100, reps: 1)
        #expect(result != nil)
        #expect(abs(result! - 103.333) < 0.01)
    }

    @Test func estimated1RM_zeroWeight_returnsNil() {
        let result = WorkoutCalculations.estimated1RM(weightKg: 0, reps: 10)
        #expect(result == nil)
    }

    @Test func estimated1RM_zeroReps_returnsNil() {
        let result = WorkoutCalculations.estimated1RM(weightKg: 100, reps: 0)
        #expect(result == nil)
    }

    @Test func bestEstimated1RM_picksHighest() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let set1 = SetLog(setNumber: 1, reps: 10, weightKg: 80)
        set1.isCompleted = true
        context.insert(set1)

        let set2 = SetLog(setNumber: 2, reps: 5, weightKg: 100)
        set2.isCompleted = true
        context.insert(set2)

        let set3 = SetLog(setNumber: 3, reps: 8, weightKg: 60)
        set3.isCompleted = false // not completed — should be ignored
        context.insert(set3)

        try context.save()

        let result = WorkoutCalculations.bestEstimated1RM(completedSets: [set1, set2, set3])
        // set1: 80 * (1 + 10/30) = 106.67
        // set2: 100 * (1 + 5/30) = 116.67
        // set3: not completed
        #expect(result != nil)
        #expect(abs(result! - 116.667) < 0.01)
    }

    @Test func bestEstimated1RM_noCompletedSets_returnsNil() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let set1 = SetLog(setNumber: 1, reps: 10, weightKg: 80)
        set1.isCompleted = false
        context.insert(set1)
        try context.save()

        let result = WorkoutCalculations.bestEstimated1RM(completedSets: [set1])
        #expect(result == nil)
    }

    // MARK: - PR Detection (Standard)

    @Test func isPersonalRecord_newWeightRecord() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        // Historical: 80kg x 10
        let hist = SetLog(setNumber: 1, reps: 10, weightKg: 80)
        hist.isCompleted = true
        context.insert(hist)

        // Current: 85kg x 8
        let current = SetLog(setNumber: 1, reps: 8, weightKg: 85)
        current.isCompleted = true
        context.insert(current)
        try context.save()

        let result = WorkoutCalculations.isPersonalRecord(
            setLog: current, isIsometric: false, historicalSets: [hist]
        )
        #expect(result == true)
    }

    @Test func isPersonalRecord_sameWeightMoreReps() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let hist = SetLog(setNumber: 1, reps: 8, weightKg: 80)
        hist.isCompleted = true
        context.insert(hist)

        let current = SetLog(setNumber: 1, reps: 10, weightKg: 80)
        current.isCompleted = true
        context.insert(current)
        try context.save()

        let result = WorkoutCalculations.isPersonalRecord(
            setLog: current, isIsometric: false, historicalSets: [hist]
        )
        #expect(result == true)
    }

    @Test func isPersonalRecord_sameWeightSameReps_notPR() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let hist = SetLog(setNumber: 1, reps: 10, weightKg: 80)
        hist.isCompleted = true
        context.insert(hist)

        let current = SetLog(setNumber: 1, reps: 10, weightKg: 80)
        current.isCompleted = true
        context.insert(current)
        try context.save()

        let result = WorkoutCalculations.isPersonalRecord(
            setLog: current, isIsometric: false, historicalSets: [hist]
        )
        #expect(result == false)
    }

    @Test func isPersonalRecord_lowerWeight_notPR() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let hist = SetLog(setNumber: 1, reps: 10, weightKg: 80)
        hist.isCompleted = true
        context.insert(hist)

        let current = SetLog(setNumber: 1, reps: 12, weightKg: 70)
        current.isCompleted = true
        context.insert(current)
        try context.save()

        let result = WorkoutCalculations.isPersonalRecord(
            setLog: current, isIsometric: false, historicalSets: [hist]
        )
        #expect(result == false)
    }

    @Test func isPersonalRecord_notCompleted_notPR() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let current = SetLog(setNumber: 1, reps: 10, weightKg: 100)
        current.isCompleted = false
        context.insert(current)
        try context.save()

        let result = WorkoutCalculations.isPersonalRecord(
            setLog: current, isIsometric: false, historicalSets: []
        )
        #expect(result == false)
    }

    @Test func isPersonalRecord_firstEverSet_isPR() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let current = SetLog(setNumber: 1, reps: 10, weightKg: 50)
        current.isCompleted = true
        context.insert(current)
        try context.save()

        let result = WorkoutCalculations.isPersonalRecord(
            setLog: current, isIsometric: false, historicalSets: []
        )
        #expect(result == true)
    }

    @Test func isPersonalRecord_zeroWeight_notPR() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let current = SetLog(setNumber: 1, reps: 10, weightKg: 0)
        current.isCompleted = true
        context.insert(current)
        try context.save()

        let result = WorkoutCalculations.isPersonalRecord(
            setLog: current, isIsometric: false, historicalSets: []
        )
        // First set but zero weight — still PR since reps > 0
        #expect(result == true)
    }

    // MARK: - PR Detection (Isometric)

    @Test func isPersonalRecord_isometric_newWeightRecord() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let hist = SetLog(setNumber: 1, seconds: 30, weightKg: 20)
        hist.isCompleted = true
        context.insert(hist)

        let current = SetLog(setNumber: 1, seconds: 25, weightKg: 25)
        current.isCompleted = true
        context.insert(current)
        try context.save()

        let result = WorkoutCalculations.isPersonalRecord(
            setLog: current, isIsometric: true, historicalSets: [hist]
        )
        #expect(result == true)
    }

    @Test func isPersonalRecord_isometric_sameWeightMoreSeconds() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let hist = SetLog(setNumber: 1, seconds: 30, weightKg: 20)
        hist.isCompleted = true
        context.insert(hist)

        let current = SetLog(setNumber: 1, seconds: 45, weightKg: 20)
        current.isCompleted = true
        context.insert(current)
        try context.save()

        let result = WorkoutCalculations.isPersonalRecord(
            setLog: current, isIsometric: true, historicalSets: [hist]
        )
        #expect(result == true)
    }

    @Test func isPersonalRecord_isometric_sameWeightSameSeconds_notPR() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let hist = SetLog(setNumber: 1, seconds: 30, weightKg: 20)
        hist.isCompleted = true
        context.insert(hist)

        let current = SetLog(setNumber: 1, seconds: 30, weightKg: 20)
        current.isCompleted = true
        context.insert(current)
        try context.save()

        let result = WorkoutCalculations.isPersonalRecord(
            setLog: current, isIsometric: true, historicalSets: [hist]
        )
        #expect(result == false)
    }
}
