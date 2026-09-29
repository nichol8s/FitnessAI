import SwiftUI
import SwiftData

public struct CreateCustomExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var primaryMuscle = "Chest"
    @State private var equipment = "Barbell"
    
    let muscles = ["Chest", "Back", "Shoulders", "Biceps", "Triceps", "Legs", "Core", "Full Body"]
    let equipments = ["Barbell", "Dumbbell", "Cable", "Machine", "Bodyweight", "Kettlebell", "Other"]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Details")) {
                    TextField("Exercise Name", text: $name)
                    
                    Picker("Primary Muscle", selection: $primaryMuscle) {
                        ForEach(muscles, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    Picker("Equipment", selection: $equipment) {
                        ForEach(equipments, id: \.self) {
                            Text($0)
                        }
                    }
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExercise()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func saveExercise() {
        let exercise = Exercise(
            name: name,
            primaryMuscle: primaryMuscle,
            equipment: equipment,
            movementType: "Custom",
            isCustom: true
        )
        modelContext.insert(exercise)
        try? modelContext.save()
        Haptics.shared.playNotification(.success)
        dismiss()
    }
}
