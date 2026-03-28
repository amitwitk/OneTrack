import Testing
import Foundation
import SwiftData
@testable import OneTrack

@Suite("Plan Management")
@MainActor
struct PlanManagementTests {

    // MARK: - Flat List Building

    @Test func buildFlatList_emptyExercises() {
        let result = PlanManagement.buildFlatList(exercises: [])
        #expect(result.isEmpty)
    }

    @Test func buildFlatList_singleSectionNoName() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let plan = WorkoutPlan(name: "Test", planDescription: "", sortOrder: 0)
        context.insert(plan)
        let e1 = Exercise(name: "Bench", targetSets: 3, targetReps: 10, sortOrder: 0)
        e1.plan = plan
        context.insert(e1)
        let e2 = Exercise(name: "Fly", targetSets: 3, targetReps: 12, sortOrder: 1)
        e2.plan = plan
        context.insert(e2)
        try context.save()

        let result = PlanManagement.buildFlatList(exercises: [e1, e2])
        #expect(result.count == 3) // header("") + 2 exercises
        if case .sectionHeader(let name) = result[0] {
            #expect(name == "")
        } else {
            Issue.record("Expected section header at index 0")
        }
    }

    @Test func buildFlatList_multipleSections() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let plan = WorkoutPlan(name: "Test", planDescription: "", sortOrder: 0)
        context.insert(plan)

        let e1 = Exercise(name: "Bench", targetSets: 3, targetReps: 10, sortOrder: 0, section: "Chest")
        e1.plan = plan
        context.insert(e1)
        let e2 = Exercise(name: "Fly", targetSets: 3, targetReps: 12, sortOrder: 1, section: "Chest")
        e2.plan = plan
        context.insert(e2)
        let e3 = Exercise(name: "Row", targetSets: 3, targetReps: 10, sortOrder: 2, section: "Back")
        e3.plan = plan
        context.insert(e3)
        try context.save()

        let result = PlanManagement.buildFlatList(exercises: [e1, e2, e3])
        // header("Chest"), Bench, Fly, header("Back"), Row
        #expect(result.count == 5)
        if case .sectionHeader("Chest") = result[0] {} else {
            Issue.record("Expected 'Chest' header at 0")
        }
        if case .sectionHeader("Back") = result[3] {} else {
            Issue.record("Expected 'Back' header at 3")
        }
    }

    @Test func buildFlatList_includesEmptyKnownGroups() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let plan = WorkoutPlan(name: "Test", planDescription: "", sortOrder: 0)
        context.insert(plan)
        let e1 = Exercise(name: "Bench", targetSets: 3, targetReps: 10, sortOrder: 0, section: "Chest")
        e1.plan = plan
        context.insert(e1)
        try context.save()

        let result = PlanManagement.buildFlatList(exercises: [e1], knownGroups: ["Chest", "Legs"])
        // header("Chest"), Bench, header("Legs")
        #expect(result.count == 3)
        if case .sectionHeader("Legs") = result[2] {} else {
            Issue.record("Expected 'Legs' header at 2")
        }
    }

    // MARK: - Cross-Group Move

    @Test func applyMove_exerciseAcrossSections() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let plan = WorkoutPlan(name: "Test", planDescription: "", sortOrder: 0)
        context.insert(plan)

        let e1 = Exercise(name: "Bench", targetSets: 3, targetReps: 10, sortOrder: 0, section: "Chest")
        e1.plan = plan
        context.insert(e1)
        let e2 = Exercise(name: "Fly", targetSets: 3, targetReps: 12, sortOrder: 1, section: "Chest")
        e2.plan = plan
        context.insert(e2)
        let e3 = Exercise(name: "Row", targetSets: 3, targetReps: 10, sortOrder: 2, section: "Back")
        e3.plan = plan
        context.insert(e3)
        try context.save()

        var flatList = PlanManagement.buildFlatList(exercises: [e1, e2, e3])
        // [header("Chest"), Bench, Fly, header("Back"), Row]
        // Move Bench (index 1) to after Row (index 5, which means after last item)
        PlanManagement.applyMove(flatList: &flatList, from: IndexSet(integer: 1), to: 5)

        // After move: [header("Chest"), Fly, header("Back"), Row, Bench]
        #expect(e1.section == "Back") // Bench moved to Back section
        #expect(e2.section == "Chest") // Fly stayed in Chest
        #expect(e3.section == "Back") // Row stayed in Back
    }

    @Test func applyMove_updatessSortOrder() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let plan = WorkoutPlan(name: "Test", planDescription: "", sortOrder: 0)
        context.insert(plan)

        let e1 = Exercise(name: "A", targetSets: 3, targetReps: 10, sortOrder: 0, section: "G1")
        e1.plan = plan
        context.insert(e1)
        let e2 = Exercise(name: "B", targetSets: 3, targetReps: 10, sortOrder: 1, section: "G1")
        e2.plan = plan
        context.insert(e2)
        let e3 = Exercise(name: "C", targetSets: 3, targetReps: 10, sortOrder: 2, section: "G2")
        e3.plan = plan
        context.insert(e3)
        try context.save()

        var flatList = PlanManagement.buildFlatList(exercises: [e1, e2, e3])
        // Move B (index 2) to after C (index 5)
        PlanManagement.applyMove(flatList: &flatList, from: IndexSet(integer: 2), to: 5)

        // New order: A=0, C=1, B=2
        #expect(e1.sortOrder == 0)
        #expect(e3.sortOrder == 1)
        #expect(e2.sortOrder == 2)
    }

    // MARK: - Section Assignment

    @Test func sectionForIndex_findsNearestHeader() {
        let items: [PlanListItem] = [
            .sectionHeader("Chest"),
            .exercise(Exercise(name: "Bench", targetSets: 3, targetReps: 10, sortOrder: 0)),
            .exercise(Exercise(name: "Fly", targetSets: 3, targetReps: 12, sortOrder: 1)),
            .sectionHeader("Back"),
            .exercise(Exercise(name: "Row", targetSets: 3, targetReps: 10, sortOrder: 2)),
        ]
        #expect(PlanManagement.sectionForIndex(1, in: items) == "Chest")
        #expect(PlanManagement.sectionForIndex(2, in: items) == "Chest")
        #expect(PlanManagement.sectionForIndex(4, in: items) == "Back")
    }

    @Test func sectionForIndex_headerReturnsItself() {
        let items: [PlanListItem] = [
            .sectionHeader("Chest"),
            .sectionHeader("Back"),
        ]
        #expect(PlanManagement.sectionForIndex(0, in: items) == "Chest")
        #expect(PlanManagement.sectionForIndex(1, in: items) == "Back")
    }

    @Test func sectionForIndex_noHeader_returnsEmpty() {
        let items: [PlanListItem] = [
            .exercise(Exercise(name: "Bench", targetSets: 3, targetReps: 10, sortOrder: 0)),
        ]
        #expect(PlanManagement.sectionForIndex(0, in: items) == "")
    }

    // MARK: - Delete Set

    @Test func deleteSet_renumbersRemaining() throws {
        let container = try makeTestContainer()
        let context = container.mainContext

        let session = WorkoutSession()
        context.insert(session)
        let log = ExerciseLog(exerciseName: "Bench", sortOrder: 0)
        log.session = session
        context.insert(log)

        let s1 = SetLog(setNumber: 1, reps: 10, weightKg: 50)
        s1.exerciseLog = log
        context.insert(s1)
        let s2 = SetLog(setNumber: 2, reps: 10, weightKg: 50)
        s2.exerciseLog = log
        context.insert(s2)
        let s3 = SetLog(setNumber: 3, reps: 10, weightKg: 50)
        s3.exerciseLog = log
        context.insert(s3)
        try context.save()

        PlanManagement.deleteSet(s2, from: log)

        #expect(s1.setNumber == 1)
        #expect(s3.setNumber == 2) // renumbered from 3 to 2
    }
}
