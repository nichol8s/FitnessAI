import SwiftUI
import SwiftData

public struct ProgressStrengthView: View {
    @Environment(\.modelContext) private var modelContext
    let timeRange: ClosedRange<Date>?
    
    @State private var personalRecords: [PersonalRecord] = []
    
    public init(timeRange: ClosedRange<Date>?) {
        self.timeRange = timeRange
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.l) {
            if personalRecords.isEmpty {
                Text("No PRs recorded in this range.")
                    .font(AppTypography.subheadline)
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, AppSpacing.xxl)
            } else {
                Text("PERSONAL RECORDS")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .kerning(1.2)
                
                ForEach(personalRecords) { pr in
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text(pr.exercise?.name ?? "Unknown")
                                .font(AppTypography.headline)
                                .foregroundColor(AppColors.textPrimary)
                            
                            let label = pr.recordType == "1rm" ? "Est. 1RM" : (pr.recordType == "volume" ? "Volume" : "Weight")
                            Text(label)
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textSecondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                            Text("\(String(format: "%.1f", pr.value)) kg")
                                .font(AppTypography.title3)
                                .foregroundColor(AppColors.warning)
                            
                            let formatter = DateFormatter()
                            formatter.dateStyle = .short
                            Text(formatter.string(from: pr.date))
                                .font(AppTypography.caption)
                                .foregroundColor(AppColors.textTertiary)
                        }
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
        let descriptor = FetchDescriptor<PersonalRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        guard let allPRs = try? modelContext.fetch(descriptor) else { return }
        
        if let range = timeRange {
            personalRecords = allPRs.filter { range.contains($0.date) }
        } else {
            personalRecords = allPRs
        }
    }
}
