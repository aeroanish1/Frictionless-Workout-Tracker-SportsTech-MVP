import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.startTime, order: .reverse) private var sessions: [WorkoutSession]
    
    var body: some View {
        NavigationStack {
            List {
                if sessions.isEmpty {
                    Text("No workouts recorded yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(sessions) { session in
                        NavigationLink(destination: WorkoutDetailView(session: session)) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(session.workoutName ?? session.splitName ?? "AI Logged Workout")
                                    .font(.headline)
                                Text(session.startTime, style: .date)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                if !session.notes.isEmpty {
                                    Text(session.notes)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deleteSessions)
                }
            }
            .navigationTitle("History")
        }
    }
    
    private func deleteSessions(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(sessions[index])
            }
        }
    }
}

struct WorkoutDetailView: View {
    let session: WorkoutSession
    var body: some View {
        List {
            if let end = session.endTime {
                Section {
                    let diff = Int(end.timeIntervalSince(session.startTime))
                    Text("Duration: \(diff / 60) mins")
                }
            }
            if !session.notes.isEmpty {
                Section(header: Text("Notes")) {
                    Text(session.notes)
                }
            }
            ForEach(session.exercises.sorted(by: { $0.order < $1.order })) { exercise in
                Section(header: Text(exercise.name)) {
                    ForEach(Array(exercise.sets.sorted(by: { $0.id.uuidString < $1.id.uuidString }).enumerated()), id: \.element.id) { index, set in
                        HStack {
                            Text("Set \(index + 1)")
                            Spacer()
                            Text("\(set.reps) reps @ \(set.weight, specifier: "%.1f") lbs")
                                .foregroundColor(.secondary)
                            if set.isDropSet {
                                Text("(Drop)")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .padding(.leading, 4)
                            }
                            if set.isSuperSet {
                                Text("(Super)")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                                    .padding(.leading, 4)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(session.workoutName ?? session.splitName ?? "Workout")
        .navigationBarTitleDisplayMode(.inline)
    }
}
