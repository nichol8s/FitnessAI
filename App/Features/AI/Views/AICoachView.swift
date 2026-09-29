import SwiftUI
import SwiftData

public struct AICoachView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    // Inject MockAIProvider for Windows dev, production uses AIAPIClient
    private var provider: AIProvider = AIProviderFactory.shared
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isTyping: Bool = false
    @State private var errorMessage: String?
    @State private var showGenerator: Bool = false
    @State private var showingPaywall: Bool = false
    
    struct ChatMessage: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
        let suggestedActions: [String]?
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if subscriptionManager.entitlement != .pro {
                        paywallOverlay
                    } else {
                        ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: AppSpacing.m) {
                                // Welcome message
                                if messages.isEmpty {
                                    VStack(spacing: AppSpacing.l) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 64))
                                            .foregroundColor(AppColors.primary)
                                            .padding(.top, AppSpacing.xxl)
                                        
                                        Text("AI Personal Coach")
                                            .font(AppTypography.title2)
                                            .foregroundColor(AppColors.textPrimary)
                                        
                                        Text("Ask me about your progress, plan your next workout, or get exercise substitutions.")
                                            .font(AppTypography.body)
                                            .foregroundColor(AppColors.textSecondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, AppSpacing.xl)
                                        
                                        // Quick Actions
                                        VStack(spacing: AppSpacing.s) {
                                            QuickActionButton(title: "Analyze today's workout") {
                                                sendMessage("Analyze today's workout")
                                            }
                                            QuickActionButton(title: "Plan my next workout") {
                                                sendMessage("Plan my next workout")
                                            }
                                            QuickActionButton(title: "Generate structured workout") {
                                                showGenerator = true
                                            }
                                            QuickActionButton(title: "How can I increase my squat?") {
                                                sendMessage("How can I increase my squat?")
                                            }
                                        }
                                        .padding(.top, AppSpacing.m)
                                    }
                                }
                                
                                // Chat History
                                ForEach(messages) { message in
                                    ChatBubble(message: message)
                                        .id(message.id)
                                    
                                    if let actions = message.suggestedActions, !actions.isEmpty, message.id == messages.last?.id {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: AppSpacing.s) {
                                                ForEach(actions, id: \.self) { action in
                                                    Button(action: { sendMessage(action) }) {
                                                        Text(action)
                                                            .font(AppTypography.caption)
                                                            .padding(.horizontal, AppSpacing.m)
                                                            .padding(.vertical, 8)
                                                            .background(AppColors.tertiaryBackground)
                                                            .foregroundColor(AppColors.textPrimary)
                                                            .clipShape(Capsule())
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, AppSpacing.m)
                                        }
                                    }
                                }
                                
                                if isTyping {
                                    HStack {
                                        ProgressView()
                                            .tint(AppColors.primary)
                                            .padding(AppSpacing.m)
                                            .background(AppColors.secondaryBackground)
                                            .cornerRadius(AppRadius.medium)
                                        Spacer()
                                    }
                                    .padding(.horizontal, AppSpacing.m)
                                    .id("typing")
                                }
                            }
                            .padding(.vertical, AppSpacing.m)
                        }
                        .onChange(of: messages.count) { _, _ in
                            withAnimation {
                                proxy.scrollTo(messages.last?.id, anchor: .bottom)
                            }
                        }
                        .onChange(of: isTyping) { _, isTyping in
                            if isTyping {
                                withAnimation {
                                    proxy.scrollTo("typing", anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .font(AppTypography.caption)
                            .foregroundColor(AppColors.error)
                            .padding(.bottom, AppSpacing.s)
                    }
                    
                    // Input Bar
                    HStack(spacing: AppSpacing.m) {
                        TextField("Ask Coach...", text: $inputText)
                            .padding(AppSpacing.m)
                            .background(AppColors.secondaryBackground)
                            .cornerRadius(AppRadius.large)
                            .foregroundColor(AppColors.textPrimary)
                            .onSubmit {
                                guard !inputText.isEmpty else { return }
                                let txt = inputText
                                inputText = ""
                                sendMessage(txt)
                            }
                        
                        Button(action: {
                            guard !inputText.isEmpty else { return }
                            let txt = inputText
                            inputText = ""
                            sendMessage(txt)
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(inputText.isEmpty ? AppColors.textTertiary : AppColors.primary)
                        }
                        .disabled(inputText.isEmpty || isTyping)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Coach")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showGenerator) {
                AIWorkoutGeneratorView()
            }
        }
    }
    
    private func sendMessage(_ text: String) {
        let userMsg = ChatMessage(text: text, isUser: true, suggestedActions: nil)
        messages.append(userMsg)
        
        isTyping = true
        errorMessage = nil
        Haptics.shared.playSelection()
        
        Task {
            let contextBuilder = AIContextBuilder(context: modelContext)
            let context = await contextBuilder.buildFitnessContext()
            let request = AIChatRequest(message: text, context: context)
            
            do {
                let response = try await provider.sendChat(request: request)
                await MainActor.run {
                    self.isTyping = false
                    self.messages.append(ChatMessage(text: response.reply, isUser: false, suggestedActions: response.suggestedActions))
                    Haptics.shared.success()
                }
            } catch {
                await MainActor.run {
                    self.isTyping = false
                    self.errorMessage = (error as? LocalizedError)?.errorDescription ?? "An unknown error occurred."
                }
            }
        }
    }
    
    @ViewBuilder
    private var paywallOverlay: some View {
        VStack(spacing: AppSpacing.l) {
            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 48))
                .foregroundColor(AppColors.primary)
            
            Text("Fitness Pro Required")
                .font(AppTypography.title)
                .foregroundColor(AppColors.textPrimary)
            
            Text("Subscribe to Fitness Pro to unlock the AI Coach and advanced analysis.")
                .font(AppTypography.body)
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showingPaywall = true
            }) {
                Text("View Plans")
                    .font(AppTypography.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primaryGradient)
                    .cornerRadius(AppRadius.large)
            }
            .padding(.horizontal, AppSpacing.xl)
            
            Spacer()
        }
        .sheet(isPresented: $showingPaywall) {
            SubscriptionView()
        }
    }
}

struct ChatBubble: View {
    let message: AICoachView.ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            Text(message.text)
                .font(AppTypography.body)
                .padding(AppSpacing.m)
                .background(message.isUser ? AppColors.primary : AppColors.secondaryBackground)
                .foregroundColor(message.isUser ? .white : AppColors.textPrimary)
                .cornerRadius(AppRadius.medium)
                .customCorner(message.isUser ? .bottomRight : .bottomLeft)
            
            if !message.isUser { Spacer() }
        }
        .padding(.horizontal, AppSpacing.m)
    }
}

extension View {
    func customCorner(_ corner: UIRectCorner) -> some View {
        // Fallback for simple styling. In a real app, use UIBezierPath to sharpen the specific tail corner.
        self
    }
}

struct QuickActionButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTypography.body)
                .foregroundColor(AppColors.primary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppColors.primary.opacity(0.1))
                .cornerRadius(AppRadius.large)
        }
        .padding(.horizontal, AppSpacing.xl)
    }
}
