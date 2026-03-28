import Testing
import Foundation
@testable import OneTrack

@Suite("HealthKit Info.plist Configuration")
struct InfoPlistHealthKitTests {

    @Test func healthKitUpdateUsageDescriptionExists() {
        // Regression test for #39: app crashed on Body tab because
        // NSHealthUpdateUsageDescription was missing from Info.plist.
        // HealthKit requires this key when requesting write authorization.
        let description = Bundle.main.object(forInfoDictionaryKey: "NSHealthUpdateUsageDescription") as? String
        #expect(description != nil, "NSHealthUpdateUsageDescription must be set in Info.plist for HealthKit write access")
        #expect(description?.isEmpty == false, "NSHealthUpdateUsageDescription must not be empty")
    }

    @Test func healthKitShareUsageDescriptionExists() {
        let description = Bundle.main.object(forInfoDictionaryKey: "NSHealthShareUsageDescription") as? String
        #expect(description != nil, "NSHealthShareUsageDescription must be set in Info.plist for HealthKit read access")
        #expect(description?.isEmpty == false, "NSHealthShareUsageDescription must not be empty")
    }
}
