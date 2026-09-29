import SwiftUI
import SwiftData
import Charts

public struct ProgressDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedTab: AnalyticsTab = .overview
    @State private var timeRange: TimeRange = .thirtyDays
    
    enum AnalyticsTab: String, CaseIterable {
        case overview = "Overview"
        case strength = "Strength"
        case volume = "Volume"
        case body = "Body"
    }
    
    enum TimeRange: String, CaseIterable {
        case sevenDays = "7D"
        case thirtyDays = "30D"
        case threeMonths = "3M"
        case sixMonths = "6M"
        case oneYear = "1Y"
        case all = "ALL"
        
        var dateRange: ClosedRange<Date>? {
            let calendar = Calendar.current
            let now = Date()
            switch self {
            case .sevenDays:
                guard let past = calendar.date(byAdding: .day, value: -7, to: now) else { return nil }
                return past...now
            case .thirtyDays:
                guard let past = calendar.date(byAdding: .day, value: -30, to: now) else { return nil }
                return past...now
            case .threeMonths:
                guard let past = calendar.date(byAdding: .month, value: -3, to: now) else { return nil }
                return past...now
            case .sixMonths:
                guard let past = calendar.date(byAdding: .month, value: -6, to: now) else { return nil }
                return past...now
            case .oneYear:
                guard let past = calendar.date(byAdding: .year, value: -1, to: now) else { return nil }
                return past...now
            case .all:
                return nil
            }
        }
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: AppSpacing.m) {
                    // Date Range Picker
                    Picker("Time Range", selection: $timeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Tab Picker
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.s) {
                            ForEach(AnalyticsTab.allCases, id: \.self) { tab in
                                let isSelected = selectedTab == tab
                                Text(tab.rawValue)
                                    .font(AppTypography.caption)
                                    .fontWeight(isSelected ? .bold : .medium)
                                    .padding(.horizontal, AppSpacing.m)
                                    .padding(.vertical, AppSpacing.s)
                                    .background(isSelected ? AppColors.primary : AppColors.secondaryBackground)
                                    .foregroundColor(isSelected ? .white : AppColors.textSecondary)
                                    .clipShape(Capsule())
                                    .onTapGesture {
                                        withAnimation(AppAnimations.snap) {
                                            selectedTab = tab
                                            Haptics.shared.playSelection()
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Content
                    ScrollView {
                        switch selectedTab {
                        case .overview:
                            ProgressOverviewView(timeRange: timeRange.dateRange)
                        case .strength:
                            ProgressStrengthView(timeRange: timeRange.dateRange)
                        case .volume:
                            ProgressVolumeView(timeRange: timeRange.dateRange)
                        case .body:
                            ProgressBodyView()
                        }
                    }
                }
            }
            .navigationTitle("Progress")
        }
    }
}
