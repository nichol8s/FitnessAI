import SwiftUI
import SwiftData

public struct CreateRoutineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var userNotes = ""
    @State private var isFavorite = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Routine Info")) {
                    TextField("Routine Name (e.g. Push Day)", text: $name)
                        .font(AppTypography.headline)
                    
                    TextField("Notes (optional)", text: $userNotes)
                    
                    Toggle("Mark as Favorite", isOn: $isFavorite)
                        .tint(AppColors.warning)
                }
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createRoutine()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func createRoutine() {
        let routine = Routine(name: name, icon: "figure.strengthtraining.traditional", color: "blue")
        routine.userNotes = userNotes.isEmpty ? nil : userNotes
        routine.isFavorite = isFavorite
        
        modelContext.insert(routine)
        try? modelContext.save()
        Haptics.shared.playNotification(.success)
        dismiss()
    }
}
