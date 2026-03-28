import Testing
import Foundation
@testable import OneTrack

@Suite("Ingredient Parser")
struct IngredientParserTests {

    @Test func parse_emptyString() {
        #expect(IngredientParser.parse("").isEmpty)
    }

    @Test func parse_whitespaceOnly() {
        #expect(IngredientParser.parse("   ").isEmpty)
    }

    @Test func parseSingle_countAndName() {
        let result = IngredientParser.parseSingle("3 eggs")
        #expect(result == ParsedIngredient(quantity: 3, unit: "unit", foodName: "eggs"))
    }

    @Test func parseSingle_gramsAndName() {
        let result = IngredientParser.parseSingle("200g chicken breast")
        #expect(result == ParsedIngredient(quantity: 200, unit: "g", foodName: "chicken breast"))
    }

    @Test func parseSingle_gramsWithSpace() {
        let result = IngredientParser.parseSingle("200 g chicken")
        #expect(result == ParsedIngredient(quantity: 200, unit: "g", foodName: "chicken"))
    }

    @Test func parseSingle_decimalQuantity() {
        let result = IngredientParser.parseSingle("1.5 cups rice")
        #expect(result == ParsedIngredient(quantity: 1.5, unit: "cups", foodName: "rice"))
    }

    @Test func parseSingle_noQuantityDefaults100g() {
        let result = IngredientParser.parseSingle("chicken breast")
        #expect(result == ParsedIngredient(quantity: 100, unit: "g", foodName: "chicken breast"))
    }

    @Test func parseSingle_singleWord() {
        let result = IngredientParser.parseSingle("banana")
        #expect(result == ParsedIngredient(quantity: 100, unit: "g", foodName: "banana"))
    }

    @Test func parse_multipleIngredients() {
        let results = IngredientParser.parse("3 eggs, 200g chicken breast, 1 banana")
        #expect(results.count == 3)
        #expect(results[0].foodName == "eggs")
        #expect(results[1].foodName == "chicken breast")
        #expect(results[2].foodName == "banana")
    }

    @Test func parse_trailingComma() {
        let results = IngredientParser.parse("3 eggs,")
        #expect(results.count == 1)
        #expect(results[0].foodName == "eggs")
    }

    @Test func parseSingle_nil() {
        let result = IngredientParser.parseSingle("")
        #expect(result == nil)
    }
}
