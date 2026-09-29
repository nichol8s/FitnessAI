import Foundation
import SwiftData
#if canImport(HealthKit)
import HealthKit
#endif

@Observable
public final class HealthKitManager {
    public static let shared = HealthKitManager()
    
    #if canImport(HealthKit)
    private let healthStore = HKHealthStore()
    #endif
    
    public var isConnected: Bool = false
    public var errorMessage: String? = nil
    
    private init() {}
    
    public var isAvailable: Bool {
        #if canImport(HealthKit)
        return HKHealthStore.isHealthDataAvailable()
        #else
        return false
        #endif
    }
    
    public func requestAuthorization() async {
        #if canImport(HealthKit)
        guard isAvailable else {
            errorMessage = "Apple Health is not available on this device."
            return
        }
        
        guard let workoutType = HKObjectType.workoutType(),
              let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass),
              let heightType = HKObjectType.quantityType(forIdentifier: .height),
              let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return
        }
        
        let writeTypes: Set<HKSampleType> = [workoutType, bodyMassType]
        let readTypes: Set<HKObjectType> = [workoutType, bodyMassType, heightType, activeEnergyType]
        
        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            await MainActor.run {
                self.isConnected = true
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to connect to Apple Health: \(error.localizedDescription)"
                self.isConnected = false
            }
        }
        #endif
    }
    
    public func syncWorkout(_ workout: Workout, context: ModelContext) async {
        #if canImport(HealthKit)
        guard isConnected else {
            workout.hkSyncStatus = "failed"
            try? context.save()
            return
        }
        
        // Prevent duplicate write
        guard workout.hkWorkoutID == nil else {
            workout.hkSyncStatus = "synced"
            try? context.save()
            return
        }
        
        let endTime = workout.endTime ?? Date()
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        
        // Include energy burned if available, otherwise just duration
        let hkWorkout = HKWorkout(
            activityType: .traditionalStrengthTraining,
            start: workout.startTime,
            end: endTime,
            workoutEvents: nil,
            totalEnergyBurned: nil,
            totalDistance: nil,
            metadata: [
                HKMetadataKeyWorkoutBrandName: "Fitness App",
                "Routine": workout.routine?.name ?? "Custom"
            ]
        )
        
        do {
            try await healthStore.save(hkWorkout)
            await MainActor.run {
                workout.hkWorkoutID = hkWorkout.uuid.uuidString
                workout.hkSyncStatus = "synced"
                try? context.save()
            }
        } catch {
            await MainActor.run {
                workout.hkSyncStatus = "failed"
                try? context.save()
            }
        }
        #else
        await MainActor.run {
            workout.hkSyncStatus = "failed"
            try? context.save()
        }
        #endif
    }
    
    public func syncBodyWeight(_ measurement: BodyMeasurement, context: ModelContext) async {
        #if canImport(HealthKit)
        guard isConnected, let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        
        let unit = measurement.unit == "kg" ? HKUnit.gramUnit(with: .kilo) : HKUnit.pound()
        let quantity = HKQuantity(unit: unit, doubleValue: measurement.value)
        
        let sample = HKQuantitySample(
            type: bodyMassType,
            quantity: quantity,
            start: measurement.date,
            end: measurement.date,
            metadata: ["Source": "Fitness App"]
        )
        
        do {
            try await healthStore.save(sample)
            await MainActor.run {
                measurement.hkMeasurementID = sample.uuid.uuidString
                try? context.save()
            }
        } catch {
            print("Failed to sync weight to HealthKit: \(error)")
        }
        #endif
    }
}
