//
//  Frictionless_Workout_TrackerApp.swift
//  Frictionless-Workout-Tracker
//

import SwiftUI
import SwiftData

@main
struct Frictionless_Workout_TrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SplitTemplate.self,
            WorkoutTemplate.self,
            ExerciseTemplate.self,
            WorkoutSession.self,
            SessionExercise.self,
            WorkoutSet.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
