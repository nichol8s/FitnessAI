import SwiftUI
import SwiftData

public struct ProgressBodyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<BodyMeasurement> { $0.type == "weight" }, sort: \BodyMeasurement.date, order: .reverse) private var weightMeasurements: [BodyMeasurement]
    
    @State private var showingAddWeight = false
    @State private var newWeightString = ""
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
            
            HStack {
                Text("BODY WEIGHT")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .kerning(1.2)
                Spacer()
                Button(action: { showingAddWeight = true }) {
                    Image(systemName: "plus")
                        .foregroundColor(AppColors.primary)
                }
            }
            
            if weightMeasurements.isEmpty {
                Text("No body weight data.")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, AppSpacing.l)
            } else {
                // Latest Weight
                if let latest = weightMeasurements.first {
                    HStack(alignment: .bottom, spacing: AppSpacing.s) {
                        Text(String(format: "%.1f", latest.value))
                            .font(AppTypography.numericLarge)
                            .foregroundColor(AppColors.textPrimary)
                        Text(latest.unit)
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.bottom, AppSpacing.xs)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(AppRadius.large)
                }
                
                // History List
                Text("HISTORY")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .kerning(1.2)
                    .padding(.top, AppSpacing.m)
                
                ForEach(weightMeasurements) { measurement in
                    HStack {
                        let formatter = DateFormatter()
                        formatter.dateStyle = .medium
                        Text(formatter.string(from: measurement.date))
                            .font(AppTypography.body)
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Text("\(String(format: "%.1f", measurement.value)) \(measurement.unit)")
                            .font(AppTypography.headline)
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .padding()
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(AppRadius.large)
                }
            }
        }
        .padding()
        .alert("Add Weight", isPresented: $showingAddWeight) {
            TextField("Weight (kg)", text: $newWeightString)
                .keyboardType(.decimalPad)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if let w = Double(newWeightString.replacingOccurrences(of: ",", with: ".")) {
                    let measurement = BodyMeasurement(date: Date(), type: "weight", value: w, unit: "kg")
                    modelContext.insert(measurement)
                    try? modelContext.save()
                    newWeightString = ""
                    
                    Task {
                        await HealthKitManager.shared.syncBodyWeight(measurement, context: modelContext)
                    }
                }
            }
        }
    }
}
