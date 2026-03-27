import Testing
import Foundation
@testable import OneTrack

@Suite("Weight Formatting")
struct WeightFormattingTests {

    @Test func formattedWeight_wholeNumber() {
        #expect(80.0.formattedWeight == "80 kg")
    }

    @Test func formattedWeight_decimal() {
        #expect(80.5.formattedWeight == "80.5 kg")
    }

    @Test func compactWeight_wholeNumber() {
        #expect(80.0.compactWeight == "80kg")
    }

    @Test func compactWeight_decimal() {
        #expect(80.5.compactWeight == "80.5kg")
    }

    @Test func formattedWeight_zero() {
        #expect(0.0.formattedWeight == "0 kg")
    }
}
