import SwiftUI
import SwiftData

public struct AIInsightCard: View {
    @Environment(\.modelContext) private var modelContext
    private var provider: AIProvider = AIProviderFactory.shared
    
    @State private var insight: String?
    @State private var isLoading: Bool = true
    @State private var fetchFailed: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.s) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(AppColors.primary)
                Text("AI INSIGHT")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.primary)
                    .kerning(1.2)
                Spacer()
            }
            
            if isLoading {
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 4).fill(AppColors.tertiaryBackground).frame(height: 12)
                    RoundedRectangle(cornerRadius: 4).fill(AppColors.tertiaryBackground).frame(height: 12).padding(.trailing, 40)
                    RoundedRectangle(cornerRadius: 4).fill(AppColors.tertiaryBackground).frame(height: 12).padding(.trailing, 80)
                }
                .padding(.vertical, AppSpacing.xs)
            } else if fetchFailed {
                Text("Insights are currently unavailable while offline.")
                    .font(AppTypography.caption)
                    .foregroundColor(AppColors.textSecondary)
            } else if let insight = insight {
                Text(insight)
                    .font(AppTypography.body)
                    .foregroundColor(AppColors.textPrimary)
                    .lineSpacing(4)
            }
        }
        .padding(AppSpacing.l)
        .background(AppColors.secondaryBackground)
        .cornerRadius(AppRadius.large)
        .appShadow(AppShadows.subtle)
        .onAppear {
            loadInsight()
        }
    }
    
    private func loadInsight() {
        // In production, check cache/timestamp first. For demo, we simulate the fetch immediately.
        guard insight == nil else { return }
        
        Task {
            let builder = AIContextBuilder(context: modelContext)
            let context = await builder.buildFitnessContext()
            
            do {
                let response = try await provider.getInsight(request: AIInsightRequest(context: context))
                await MainActor.run {
                    self.insight = response.insightText
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.fetchFailed = true
                    self.isLoading = false
                }
            }
        }
    }
}
