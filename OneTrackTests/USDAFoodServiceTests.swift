import Testing
import Foundation
@testable import OneTrack

@Suite("USDA Food Service")
struct USDAFoodServiceTests {
    let service: USDAFoodService

    init() {
        let testBundle = Bundle(for: BundleToken.self)
        service = USDAFoodService(bundle: testBundle)
    }

    @Test func searchEmptyQuery() {
        let results = service.search(query: "")
        #expect(results.isEmpty)
    }

    @Test func searchSingleTerm() {
        let results = service.search(query: "chicken")
        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.description.lowercased().contains("chicken") })
    }

    @Test func searchMultiTerm() {
        let results = service.search(query: "chicken breast")
        #expect(results.count == 1)
        #expect(results.first?.description.contains("breast") == true)
    }

    @Test func searchCaseInsensitive() {
        let upper = service.search(query: "CHICKEN")
        let lower = service.search(query: "chicken")
        #expect(upper.count == lower.count)
    }

    @Test func searchNoResults() {
        let results = service.search(query: "xyznotfood")
        #expect(results.isEmpty)
    }

    @Test func loadIfNeeded_idempotent() {
        service.loadIfNeeded()
        service.loadIfNeeded()
        let results = service.search(query: "egg")
        #expect(!results.isEmpty)
    }
}

// Helper class for Bundle resolution in test target
private class BundleToken {}
