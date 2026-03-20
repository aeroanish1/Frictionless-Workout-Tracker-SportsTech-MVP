//
//  ContentView.swift
//  Frictionless-Workout-Tracker
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
            
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [SplitTemplate.self, WorkoutTemplate.self, ExerciseTemplate.self, WorkoutSession.self, SessionExercise.self, WorkoutSet.self], inMemory: true)
}
