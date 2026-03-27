import Foundation

@Observable
final class USDAFoodService {
    private var foods: [FoodItem] = []
    private var isLoaded = false
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func loadIfNeeded() {
        guard !isLoaded else { return }
        guard let url = bundle.url(forResource: "foundation_foods", withExtension: "json") else { return }
        do {
            let data = try Data(contentsOf: url)
            foods = try JSONDecoder().decode([FoodItem].self, from: data)
            isLoaded = true
        } catch {
            print("Failed to load USDA foods: \(error)")
        }
    }

    func search(query: String) -> [FoodItem] {
        loadIfNeeded()
        guard !query.isEmpty else { return [] }
        let terms = query.lowercased().split(separator: " ")
        return foods.filter { food in
            let desc = food.description.lowercased()
            return terms.allSatisfy { desc.contains($0) }
        }
    }

    func searchAPI(query: String, apiKey: String) async throws -> [FoodItem] {
        var components = URLComponents(string: "https://api.nal.usda.gov/fdc/v1/foods/search")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "dataType", value: "Foundation"),
            URLQueryItem(name: "pageSize", value: "25")
        ]
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        let response = try JSONDecoder().decode(USDASearchResponse.self, from: data)
        return response.foods.compactMap { food in
            let nutrients = Dictionary(uniqueKeysWithValues: food.foodNutrients.map { ($0.nutrientId, $0.value) })
            return FoodItem(
                fdcId: food.fdcId,
                description: food.description,
                calories: nutrients[1008] ?? 0,
                protein: nutrients[1003] ?? 0,
                carbs: nutrients[1005] ?? 0,
                fat: nutrients[1004] ?? 0
            )
        }
    }
}

private struct USDASearchResponse: Codable {
    let foods: [USDAFood]
}

private struct USDAFood: Codable {
    let fdcId: Int
    let description: String
    let foodNutrients: [USDANutrient]
}

private struct USDANutrient: Codable {
    let nutrientId: Int
    let value: Double
}
