import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var splits: [SplitTemplate]
    
    @State private var showingSplitEditor = false
    @State private var activeSession: WorkoutSession? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Ready to crush it?")
                        .font(.largeTitle)
                        .bold()
                        .padding(.horizontal)
                    
                    Text("Your Programs")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                        .padding(.top)
                    
                    if splits.isEmpty {
                        VStack(spacing: 12) {
                            Text("No workout splits yet.")
                                .foregroundColor(.secondary)
                            Button("Create First Split") {
                                showingSplitEditor = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else {
                        ForEach(splits) { split in
                            VStack(alignment: .leading, spacing: 10) {
                                Text(split.name)
                                    .font(.title3)
                                    .bold()
                                
                                ForEach(split.workouts.sorted(by: { $0.order < $1.order })) { workout in
                                    Button(action: { startWorkout(workout: workout, split: split) }) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(workout.name)
                                                    .font(.headline)
                                                Text("\(workout.exercises.count) exercises")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "play.circle.fill")
                                                .font(.title)
                                                .foregroundColor(.green)
                                        }
                                        .padding()
                                        .background(Color(.systemGray5))
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                        
                        Button("Create New Split") {
                            showingSplitEditor = true
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Home")
            .sheet(isPresented: $showingSplitEditor) {
                SplitBuilderView()
            }
            .fullScreenCover(item: $activeSession) { session in
                LiveTrainerView(workoutSession: session)
            }
        }
    }
    
    private func startWorkout(workout: WorkoutTemplate, split: SplitTemplate) {
        let newSession = WorkoutSession(startTime: Date(), splitName: split.name, workoutName: workout.name)
        
        for ex in workout.exercises.sorted(by: { $0.order < $1.order }) {
            let sessionEx = SessionExercise(name: ex.name, order: ex.order)
            newSession.exercises.append(sessionEx)
        }
        
        modelContext.insert(newSession)
        self.activeSession = newSession
    }
}
