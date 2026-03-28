import Foundation

struct ParsedIngredient: Equatable, Sendable {
    let quantity: Double
    let unit: String
    let foodName: String
}

struct IngredientParser {

    /// Parses a comma-separated ingredient string like "3 eggs, 200g chicken breast, 1 banana"
    /// into individual parsed ingredients.
    static func parse(_ input: String) -> [ParsedIngredient] {
        guard !input.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        return input
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .compactMap { parseSingle($0) }
    }

    /// Parses a single ingredient string.
    /// Supported formats:
    ///   "3 eggs"           → (3, "unit", "eggs")
    ///   "200g chicken"     → (200, "g", "chicken")
    ///   "200 g chicken"    → (200, "g", "chicken")
    ///   "1.5 cups rice"    → (1.5, "cups", "rice")
    ///   "chicken breast"   → (100, "g", "chicken breast") — no quantity defaults to 100g
    static func parseSingle(_ input: String) -> ParsedIngredient? {
        let trimmed = input.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        // Try: number + optional unit + food name
        let pattern = #"^(\d+(?:\.\d+)?)\s*(cups|cup|tbsp|tsp|kg|ml|oz|g|unit|)(?:\s+(.+))?$"#
        if let match = trimmed.range(of: pattern, options: .regularExpression, range: trimmed.startIndex..<trimmed.endIndex) {
            let matchStr = String(trimmed[match])
            return parseWithRegex(matchStr)
        }

        // Fallback: no number at start → default 100g
        return ParsedIngredient(quantity: 100, unit: "g", foodName: trimmed)
    }

    private static func parseWithRegex(_ input: String) -> ParsedIngredient? {
        let pattern = #"^(\d+(?:\.\d+)?)\s*(cups|cup|tbsp|tsp|kg|ml|oz|g|unit|)\s*(.*)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let range = NSRange(input.startIndex..<input.endIndex, in: input)
        guard let match = regex.firstMatch(in: input, range: range) else { return nil }

        guard let qtyRange = Range(match.range(at: 1), in: input),
              let quantity = Double(input[qtyRange]) else { return nil }

        let unitRange = Range(match.range(at: 2), in: input)
        let unit = unitRange.map { String(input[$0]).lowercased() } ?? ""

        let nameRange = Range(match.range(at: 3), in: input)
        let foodName = nameRange.map { String(input[$0]).trimmingCharacters(in: .whitespaces) } ?? ""

        // If no unit and no food name, the number itself might be the food name part
        if unit.isEmpty && foodName.isEmpty {
            return ParsedIngredient(quantity: 100, unit: "g", foodName: input)
        }

        // If no unit, treat as count (e.g., "3 eggs")
        let finalUnit = unit.isEmpty ? "unit" : unit

        // If food name is empty after number+unit, probably malformed
        if foodName.isEmpty {
            return ParsedIngredient(quantity: quantity, unit: finalUnit, foodName: "")
        }

        return ParsedIngredient(quantity: quantity, unit: finalUnit, foodName: foodName)
    }
}
