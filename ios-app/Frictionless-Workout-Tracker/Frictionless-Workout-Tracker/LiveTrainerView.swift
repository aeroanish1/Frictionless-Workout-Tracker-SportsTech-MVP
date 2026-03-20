import SwiftUI
import SwiftData
import Combine

struct LiveTrainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let workoutSession: WorkoutSession
    
    @State private var elapsedSeconds: Int = 0
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var currentIndex: Int = 0
    
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var inputText: String = ""
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            VStack {
                // Timer
                Text(timeString(from: elapsedSeconds))
                    .font(.system(size: 48, weight: .thin, design: .monospaced))
                    .padding(.top)
                
                if workoutSession.exercises.isEmpty {
                    Text("No exercises in this workout.")
                        .padding()
                    Spacer()
                } else {
                    // Paging View for Exercises
                    TabView(selection: $currentIndex) {
                        ForEach(Array(workoutSession.exercises.sorted(by: { $0.order < $1.order }).enumerated()), id: \.element.id) { index, exercise in
                            ExerciseFocusView(exercise: exercise)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                    
                    // AI Companion Section
                    VStack(spacing: 12) {
                        if let error = errorMessage {
                            Text(error).foregroundColor(.red).font(.caption)
                        }
                        
                        HStack {
                            TextField("Tell me what you just did...", text: $inputText)
                                .textFieldStyle(.roundedBorder)
                                .disabled(isProcessing)
                            
                            Button(action: {
                                if !inputText.isEmpty {
                                    processTextSet(text: inputText)
                                }
                            }) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(inputText.isEmpty ? .gray : .blue)
                            }
                            .disabled(inputText.isEmpty || isProcessing)
                        }
                        
                        Button(action: handleVoiceButton) {
                            HStack {
                                if isProcessing {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: audioRecorder.isRecording ? "stop.circle.fill" : "mic.fill")
                                    Text(audioRecorder.isRecording ? "Stop Recording" : "Log with Voice")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(audioRecorder.isRecording ? Color.red : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isProcessing)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                    .padding()
                }
            }
            .navigationTitle(workoutSession.workoutName ?? "Live Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel Session") {
                        modelContext.delete(workoutSession)
                        dismiss()
                    }
                    .foregroundColor(.red)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Finish") {
                        workoutSession.endTime = Date()
                        dismiss()
                    }
                    .bold()
                    .foregroundColor(.green)
                }
            }
            .onReceive(timer) { _ in
                elapsedSeconds += 1
            }
        }
    }
    
    private func handleVoiceButton() {
        if audioRecorder.isRecording {
            if let base64 = audioRecorder.stopRecording() {
                processAudioSet(base64: base64)
            }
        } else {
            audioRecorder.requestPermission { granted in
                if granted {
                    audioRecorder.startRecording()
                } else {
                    errorMessage = "Microphone access denied."
                }
            }
        }
    }
    
    private func currentExercise() -> SessionExercise? {
        let sorted = workoutSession.exercises.sorted(by: { $0.order < $1.order })
        guard currentIndex >= 0 && currentIndex < sorted.count else { return nil }
        return sorted[currentIndex]
    }
    
    private func processTextSet(text: String) {
        guard let current = currentExercise() else { return }
        isProcessing = true
        errorMessage = nil
        
        let safeText = text // Capture locally UI state
        inputText = ""
        
        Task {
            do {
                let parsedSets = try await GeminiService.shared.parseActiveSet(text: safeText, audioBase64: nil, exerciseName: current.name)
                await MainActor.run {
                    for ps in parsedSets {
                        let newSet = WorkoutSet(reps: ps.reps, weight: ps.weight)
                        current.sets.append(newSet)
                    }
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to parse: \(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }
    
    private func processAudioSet(base64: String) {
        guard let current = currentExercise() else { return }
        isProcessing = true
        errorMessage = nil
        
        Task {
            do {
                let parsedSets = try await GeminiService.shared.parseActiveSet(text: "Audio attached.", audioBase64: base64, exerciseName: current.name)
                await MainActor.run {
                    for ps in parsedSets {
                        let newSet = WorkoutSet(reps: ps.reps, weight: ps.weight)
                        current.sets.append(newSet)
                    }
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to parse audio: \(error.localizedDescription)"
                    isProcessing = false
                }
            }
        }
    }
    
    private func timeString(from totalSeconds: Int) -> String {
        let m = (totalSeconds % 3600) / 60
        let s = totalSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

struct ExerciseFocusView: View {
    @Bindable var exercise: SessionExercise
    
    var body: some View {
        VStack {
            Text(exercise.name)
                .font(.largeTitle)
                .bold()
                .padding()
            
            Text("Sets Logged: \(exercise.sets.count)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            List {
                ForEach(exercise.sets.sorted(by: { $0.id.uuidString < $1.id.uuidString })) { set in
                    HStack {
                        Text("\(set.reps) reps")
                        Spacer()
                        Text("\(set.weight, specifier: "%.1f") lbs")
                        Toggle("Drop", isOn: Bindable(set).isDropSet).labelsHidden().toggleStyle(.button).tint(.orange)
                        Toggle("Super", isOn: Bindable(set).isSuperSet).labelsHidden().toggleStyle(.button).tint(.yellow)
                    }
                }
                
                Button("+ Manual Set") {
                    exercise.sets.append(WorkoutSet(reps: 0, weight: 0.0))
                }
            }
            .listStyle(.plain)
        }
    }
}
