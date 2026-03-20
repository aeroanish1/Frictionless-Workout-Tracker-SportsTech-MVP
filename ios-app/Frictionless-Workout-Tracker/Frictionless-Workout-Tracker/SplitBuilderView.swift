import SwiftUI
import SwiftData

struct SplitBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var splitName: String = ""
    @State private var tempWorkouts: [TempWorkout] = []
    
    struct TempWorkout: Identifiable {
        let id = UUID()
        var name: String
        var exercises: [TempExercise]
    }
    
    struct TempExercise: Identifiable {
        let id = UUID()
        var name: String
        var targetSets: Int
        var targetReps: Int
    }
    
    @State private var addingWorkout = false
    @State private var newWorkoutName = ""
    
    @State private var addingExForWorkoutId: UUID? = nil
    @State private var newExName = ""
    @State private var newExSets = 3
    @State private var newExReps = 10
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Split Details")) {
                    TextField("Split Name (e.g., Arnold Split)", text: $splitName)
                }
                
                ForEach($tempWorkouts) { $workout in
                    Section(header: Text(workout.name).bold()) {
                        ForEach(workout.exercises) { ex in
                            HStack {
                                Text(ex.name)
                                Spacer()
                                Text("\(ex.targetSets)x\(ex.targetReps)")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onDelete { offsets in
                            workout.exercises.remove(atOffsets: offsets)
                        }
                        
                        Button("+ Add Exercise to \(workout.name)") {
                            addingExForWorkoutId = workout.id
                            newExName = ""
                            newExSets = 3
                            newExReps = 10
                        }
                    }
                }
                
                Section {
                    Button(action: { addingWorkout = true }) {
                        Label("Add Workout Day (e.g. Chest & Back)", systemImage: "plus.circle.fill")
                            .bold()
                    }
                }
            }
            .navigationTitle("New Split")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Split") {
                        saveSplit()
                    }
                    .disabled(splitName.isEmpty || tempWorkouts.isEmpty)
                }
            }
            // Add Workout Alert
            .alert("Add Workout Day", isPresented: $addingWorkout) {
                TextField("Workout Name", text: $newWorkoutName)
                Button("Cancel", role: .cancel) { }
                Button("Add") {
                    if !newWorkoutName.isEmpty {
                        tempWorkouts.append(TempWorkout(name: newWorkoutName, exercises: []))
                        newWorkoutName = ""
                    }
                }
            }
            // Add Exercise Sheet
            .sheet(item: Binding<TempWorkout?>(
                get: { tempWorkouts.first { $0.id == addingExForWorkoutId } },
                set: { _ in addingExForWorkoutId = nil }
            )) { targetWorkout in
                NavigationStack {
                    Form {
                        TextField("Exercise Name", text: $newExName)
                        Stepper("Sets: \(newExSets)", value: $newExSets, in: 1...10)
                        Stepper("Reps: \(newExReps)", value: $newExReps, in: 1...100)
                    }
                    .navigationTitle("Add to \(targetWorkout.name)")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") {
                                if !newExName.isEmpty, let idx = tempWorkouts.firstIndex(where: { $0.id == targetWorkout.id }) {
                                    tempWorkouts[idx].exercises.append(TempExercise(name: newExName, targetSets: newExSets, targetReps: newExReps))
                                }
                                addingExForWorkoutId = nil
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    private func saveSplit() {
        let newSplit = SplitTemplate(name: splitName)
        for (wIdx, tempW) in tempWorkouts.enumerated() {
            let workoutTemplate = WorkoutTemplate(name: tempW.name, order: wIdx)
            for (eIdx, tempE) in tempW.exercises.enumerated() {
                let exTemplate = ExerciseTemplate(name: tempE.name, targetSets: tempE.targetSets, targetReps: tempE.targetReps, order: eIdx)
                workoutTemplate.exercises.append(exTemplate)
            }
            newSplit.workouts.append(workoutTemplate)
        }
        
        modelContext.insert(newSplit)
        dismiss()
    }
}
