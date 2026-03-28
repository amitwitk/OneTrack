import Foundation

struct ParsedPlan {
    let name: String
    let rest: Int
    let exercises: [ParsedExercise]
}

struct ParsedExercise {
    let name: String
    let sets: Int
    let reps: Int
    let seconds: Int
    let isIsometric: Bool
    let section: String
}

enum PlanParseError: Error, LocalizedError {
    case emptyInput
    case missingPlanName(lineNumber: Int)
    case invalidExerciseFormat(line: String, lineNumber: Int)
    case noExercisesInPlan(planName: String)

    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Input is empty"
        case .missingPlanName(let line):
            return "Missing plan name at line \(line)"
        case .invalidExerciseFormat(let line, let lineNumber):
            return "Invalid exercise format at line \(lineNumber): \"\(line)\""
        case .noExercisesInPlan(let name):
            return "Plan \"\(name)\" has no exercises"
        }
    }
}

struct WorkoutPlanParser {

    /// Parses a multi-plan text format into structured plan data.
    ///
    /// Format:
    /// ```
    /// ---
    /// name: Push Day
    /// rest: 90
    ///
    /// - Bench Press: 4x10
    /// - Plank: 3x60s
    /// ```
    static func parse(_ text: String) throws -> [ParsedPlan] {
        let lines = text.components(separatedBy: .newlines)
        guard !lines.allSatisfy({ $0.trimmingCharacters(in: .whitespaces).isEmpty }) else {
            throw PlanParseError.emptyInput
        }

        var plans: [ParsedPlan] = []
        var currentName: String?
        var currentRest = 90
        var currentExercises: [ParsedExercise] = []
        var currentSection = ""
        var lineNumber = 0

        func finalizePlan() throws {
            if let name = currentName {
                guard !currentExercises.isEmpty else {
                    throw PlanParseError.noExercisesInPlan(planName: name)
                }
                plans.append(ParsedPlan(name: name, rest: currentRest, exercises: currentExercises))
            }
        }

        for line in lines {
            lineNumber += 1
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed == "---" {
                try finalizePlan()
                currentName = nil
                currentRest = 90
                currentExercises = []
                currentSection = ""
                continue
            }

            if trimmed.isEmpty { continue }

            if trimmed.lowercased().hasPrefix("name:") {
                currentName = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                continue
            }

            if trimmed.lowercased().hasPrefix("rest:") {
                let value = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                currentRest = Int(value) ?? 90
                continue
            }

            // Section header: [Section Name]
            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                currentSection = String(trimmed.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
                continue
            }

            if trimmed.hasPrefix("-") || trimmed.hasPrefix("•") {
                if currentName == nil {
                    currentName = "Imported Plan"
                }

                let exerciseLine = String(trimmed.dropFirst(1)).trimmingCharacters(in: .whitespaces)
                let exercise = try parseExercise(exerciseLine, lineNumber: lineNumber, section: currentSection)
                currentExercises.append(exercise)
                continue
            }

            // If line doesn't match any pattern and there's no current plan, treat as plan name
            if currentName == nil && !trimmed.isEmpty {
                currentName = trimmed
            }
        }

        try finalizePlan()
        return plans
    }

    static func parseExercise(_ line: String, lineNumber: Int, section: String = "") throws -> ParsedExercise {
        // Format: "Exercise Name: SETSxREPS" or "Exercise Name: SETSxSECONDSs"
        guard let colonIndex = line.lastIndex(of: ":") else {
            throw PlanParseError.invalidExerciseFormat(line: line, lineNumber: lineNumber)
        }

        let name = String(line[line.startIndex..<colonIndex]).trimmingCharacters(in: .whitespaces)
        let spec = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)

        guard !name.isEmpty else {
            throw PlanParseError.invalidExerciseFormat(line: line, lineNumber: lineNumber)
        }

        // Parse "4x10" or "3x60s"
        let parts = spec.lowercased().split(separator: "x")
        guard parts.count == 2, let sets = Int(parts[0]) else {
            throw PlanParseError.invalidExerciseFormat(line: line, lineNumber: lineNumber)
        }

        let valuePart = String(parts[1])

        if valuePart.hasSuffix("s") {
            // Isometric: "60s"
            let secondsStr = String(valuePart.dropLast())
            guard let seconds = Int(secondsStr) else {
                throw PlanParseError.invalidExerciseFormat(line: line, lineNumber: lineNumber)
            }
            return ParsedExercise(name: name, sets: sets, reps: 0, seconds: seconds, isIsometric: true, section: section)
        } else {
            // Rep-based: "10"
            guard let reps = Int(valuePart) else {
                throw PlanParseError.invalidExerciseFormat(line: line, lineNumber: lineNumber)
            }
            return ParsedExercise(name: name, sets: sets, reps: reps, seconds: 0, isIsometric: false, section: section)
        }
    }
}
