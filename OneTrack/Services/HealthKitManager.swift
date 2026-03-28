import Foundation
import HealthKit

@MainActor
@Observable
final class HealthKitManager {
    var isAuthorized = false
    var todaySteps: Int = 0
    var todayActiveCalories: Double = 0
    var latestWeight: Double?

    private let healthStore = HKHealthStore()
    private var observerQuery: HKObserverQuery?

    /// Callback invoked on the main actor when new weight samples arrive via observer.
    var onNewWeightSamples: (([WeightSample]) -> Void)?

    private nonisolated static let anchorKey = "com.onetrack.healthkit.weightAnchor"

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        guard isAvailable else { return }

        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.bodyMass),
            HKObjectType.workoutType()
        ]

        let writeTypes: Set<HKSampleType> = [
            HKQuantityType(.bodyMass)
        ]

        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            isAuthorized = true
            await fetchAll()
        } catch {
            isAuthorized = false
        }
    }

    // MARK: - Fetch All (existing)

    func fetchAll() async {
        todaySteps = await fetchTodaySteps()
        todayActiveCalories = await fetchTodayActiveCalories()
        latestWeight = await fetchLatestWeight()
    }

    // MARK: - Historical Weight Import

    /// Fetches ALL historical weight entries from HealthKit.
    func fetchAllWeightHistory() async -> [WeightSample] {
        guard isAvailable else { return [] }
        let type = HKQuantityType(.bodyMass)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        do {
            return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[WeightSample], Error>) in
                let query = HKSampleQuery(
                    sampleType: type,
                    predicate: nil,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [sortDescriptor]
                ) { _, samples, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        let weightSamples = (samples as? [HKQuantitySample] ?? []).map { sample in
                            let source = sample.sourceRevision.source.bundleIdentifier
                                .contains("onetrack") ? "onetrack" : "healthkit"
                            return WeightSample(
                                date: sample.startDate,
                                weightKg: sample.quantity.doubleValue(for: .gramUnit(with: .kilo)),
                                source: source
                            )
                        }
                        continuation.resume(returning: weightSamples)
                    }
                }
                healthStore.execute(query)
            }
        } catch {
            return []
        }
    }

    // MARK: - Anchored Object Query (incremental sync)

    /// Fetches only new weight samples since the last sync using an anchored query.
    func fetchNewWeightSamples() async -> [WeightSample] {
        guard isAvailable else { return [] }
        let type = HKQuantityType(.bodyMass)
        let anchor = loadAnchor()

        do {
            return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[WeightSample], Error>) in
                let query = HKAnchoredObjectQuery(
                    type: type,
                    predicate: nil,
                    anchor: anchor,
                    limit: HKObjectQueryNoLimit
                ) { [weak self] _, addedSamples, _, newAnchor, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        if let newAnchor {
                            self?.saveAnchor(newAnchor)
                        }
                        let weightSamples = (addedSamples as? [HKQuantitySample] ?? []).map { sample in
                            let source = sample.sourceRevision.source.bundleIdentifier
                                .contains("onetrack") ? "onetrack" : "healthkit"
                            return WeightSample(
                                date: sample.startDate,
                                weightKg: sample.quantity.doubleValue(for: .gramUnit(with: .kilo)),
                                source: source
                            )
                        }
                        continuation.resume(returning: weightSamples)
                    }
                }
                healthStore.execute(query)
            }
        } catch {
            return []
        }
    }

    // MARK: - Observer Query (background monitoring)

    /// Sets up an HKObserverQuery for bodyMass. When new data arrives,
    /// fetches new samples via anchored query and calls onNewWeightSamples on the main actor.
    func startObservingWeightChanges() {
        guard isAvailable, observerQuery == nil else { return }
        let type = HKQuantityType(.bodyMass)

        let query = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completionHandler, error in
            guard error == nil else {
                completionHandler()
                return
            }

            Task { @MainActor [weak self] in
                guard let self else { return }
                let newSamples = await self.fetchNewWeightSamples()
                if !newSamples.isEmpty {
                    self.onNewWeightSamples?(newSamples)
                }
            }
            completionHandler()
        }

        observerQuery = query
        healthStore.execute(query)
    }

    /// Stops observing weight changes.
    func stopObservingWeightChanges() {
        if let query = observerQuery {
            healthStore.stop(query)
            observerQuery = nil
        }
    }

    // MARK: - Write to HealthKit

    /// Saves a weight entry to HealthKit.
    func saveWeight(weightKg: Double, date: Date = .now) async throws {
        guard isAvailable else { return }
        let type = HKQuantityType(.bodyMass)
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightKg)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: date, end: date)
        try await healthStore.save(sample)
    }

    // MARK: - Anchor Persistence

    private func loadAnchor() -> HKQueryAnchor? {
        guard let data = UserDefaults.standard.data(forKey: Self.anchorKey) else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: HKQueryAnchor.self, from: data)
    }

    private nonisolated func saveAnchor(_ anchor: HKQueryAnchor) {
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true) {
            UserDefaults.standard.set(data, forKey: HealthKitManager.anchorKey)
        }
    }

    // MARK: - Existing Fetches

    private func fetchTodaySteps() async -> Int {
        guard isAvailable else { return 0 }
        let type = HKQuantityType(.stepCount)
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: .now), end: .now)
        do {
            let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        let sum = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                        continuation.resume(returning: sum)
                    }
                }
                healthStore.execute(query)
            }
            return Int(result)
        } catch {
            return 0
        }
    }

    private func fetchTodayActiveCalories() async -> Double {
        guard isAvailable else { return 0 }
        let type = HKQuantityType(.activeEnergyBurned)
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.startOfDay(for: .now), end: .now)
        do {
            return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
                let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        let sum = statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                        continuation.resume(returning: sum)
                    }
                }
                healthStore.execute(query)
            }
        } catch {
            return 0
        }
    }

    private func fetchLatestWeight() async -> Double? {
        guard isAvailable else { return nil }
        let type = HKQuantityType(.bodyMass)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        do {
            return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double?, Error>) in
                let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        let weight = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: .gramUnit(with: .kilo))
                        continuation.resume(returning: weight)
                    }
                }
                healthStore.execute(query)
            }
        } catch {
            return nil
        }
    }
}
