import SwiftUI
import SwiftData

public struct ProgressVolumeView: View {
    @Environment(\.modelContext) private var modelContext
    let timeRange: ClosedRange<Date>?
    
    @State private var muscleData: [(muscle: String, volume: Double, sets: Int)] = []
    
    public init(timeRange: ClosedRange<Date>?) {
        self.timeRange = timeRange
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
            if muscleData.isEmpty {
                Text("No volume data in this range.")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, AppSpacing.xxl)
            } else {
                Text("VOLUME BY MUSCLE GROUP")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .kerning(1.2)
                
                ForEach(muscleData, id: \.muscle) { data in
                    VStack(alignment: .leading, spacing: AppSpacing.s) {
                        HStack {
                            Text(data.muscle)
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(String(format: "%.0f", data.volume)) kg")
                                    .font(AppTypography.subheadline)
                                    .foregroundColor(AppColors.textPrimary)
                                Text("\(data.sets) sets")
                                    .font(AppTypography.caption)
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        
                        // Fake progress bar for visualization without SwiftCharts dependency issues
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(AppColors.tertiaryBackground)
                                    .frame(height: 8)
                                
                                let maxVol = muscleData.first?.volume ?? 1
                                let ratio = CGFloat(data.volume / (maxVol == 0 ? 1 : maxVol))
                                Capsule()
                                    .fill(AppColors.primary)
                                    .frame(width: max(10, geo.size.width * ratio), height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding()
                    .background(AppColors.secondaryBackground)
                    .cornerRadius(AppRadius.large)
                }
            }
        }
        .padding()
        .onAppear(perform: loadData)
        .onChange(of: timeRange) { _, _ in loadData() }
    }
    
    private func loadData() {
        let service = AnalyticsService(context: modelContext)
        let workouts = service.getCompletedWorkouts(in: timeRange)
        muscleData = service.getVolumeByMuscleGroup(for: workouts)
    }
}
