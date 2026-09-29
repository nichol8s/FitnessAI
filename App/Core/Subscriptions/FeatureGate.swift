import Foundation
import SwiftUI

public enum AppFeature {
    case aiCoach
    case aiWorkoutGenerator
    case aiProgressiveOverload
    case aiWorkoutAnalysis
    case aiNaturalLanguageLogging
    case aiExerciseSubstitution
    case advancedAnalytics
    
    public var requiresPro: Bool {
        switch self {
        case .aiCoach, .aiWorkoutGenerator, .aiProgressiveOverload, .aiWorkoutAnalysis, .aiNaturalLanguageLogging, .aiExerciseSubstitution, .advancedAnalytics:
            return true
        }
    }
}

public struct FeatureGateModifier: ViewModifier {
    let feature: AppFeature
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingPaywall = false
    
    public func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                TapGesture().onEnded {
                    if feature.requiresPro && subscriptionManager.entitlement != .pro {
                        showingPaywall = true
                    }
                }
            )
            .disabled(feature.requiresPro && subscriptionManager.entitlement != .pro) // Optionally dim it, but we handle tap
            .sheet(isPresented: $showingPaywall) {
                SubscriptionView()
            }
    }
}

public extension View {
    func requiresProEntitlement(for feature: AppFeature, isPresented: Binding<Bool>) -> some View {
        self.modifier(ProEntitlementModifier(feature: feature, isPresented: isPresented))
    }
    
    func requiresProEntitlement<Item>(for feature: AppFeature, item: Binding<Item?>) -> some View {
        self.modifier(ProEntitlementItemModifier(feature: feature, item: item))
    }
}

// Safer alternative modifier that intercepts presentation of a view/sheet entirely
public struct ProEntitlementModifier: ViewModifier {
    let feature: AppFeature
    @Binding var isPresented: Bool
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingPaywall = false
    
    public func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { oldValue, newValue in
                if newValue == true && feature.requiresPro && subscriptionManager.entitlement != .pro {
                    isPresented = false // block the actual view from appearing
                    showingPaywall = true
                }
            }
            .sheet(isPresented: $showingPaywall) {
                SubscriptionView()
            }
    }
}

public struct ProEntitlementItemModifier<Item>: ViewModifier {
    let feature: AppFeature
    @Binding var item: Item?
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingPaywall = false
    
    public func body(content: Content) -> some View {
        content
            .onChange(of: item != nil) { oldValue, newValue in
                if newValue == true && feature.requiresPro && subscriptionManager.entitlement != .pro {
                    item = nil // block the actual view from appearing
                    showingPaywall = true
                }
            }
            .sheet(isPresented: $showingPaywall) {
                SubscriptionView()
            }
    }
}
