//
//  Models.swift
//  Frictionless-Workout-Tracker
//

import Foundation
import SwiftData

// MARK: - TEMPLATES

@Model
final class SplitTemplate {
    var id: UUID = UUID()
    var name: String // e.g. "Push/Pull/Legs"
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutTemplate.split)
    var workouts: [WorkoutTemplate] = []
    
    init(id: UUID = UUID(), name: String, workouts: [WorkoutTemplate] = []) {
        self.id = id
        self.name = name
        self.workouts = workouts
    }
}

@Model
final class WorkoutTemplate {
    var id: UUID = UUID()
    var name: String // e.g. "Push Day"
    var order: Int
    
    var split: SplitTemplate?
    
    @Relationship(deleteRule: .cascade, inverse: \ExerciseTemplate.workout)
    var exercises: [ExerciseTemplate] = []
    
    init(id: UUID = UUID(), name: String, order: Int, exercises: [ExerciseTemplate] = []) {
        self.id = id
        self.name = name
        self.order = order
        self.exercises = exercises
    }
}

@Model
final class ExerciseTemplate {
    var id: UUID = UUID()
    var name: String
    var targetSets: Int
    var targetReps: Int
    var order: Int
    
    var workout: WorkoutTemplate?
    
    init(id: UUID = UUID(), name: String, targetSets: Int = 3, targetReps: Int = 10, order: Int = 0) {
        self.id = id
        self.name = name
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.order = order
    }
}

// MARK: - SESSIONS (LOGS)

@Model
final class WorkoutSession {
    var id: UUID = UUID()
    var startTime: Date
    var endTime: Date?
    var notes: String
    
    var splitName: String?
    var workoutName: String?
    
    @Relationship(deleteRule: .cascade, inverse: \SessionExercise.session)
    var exercises: [SessionExercise] = []
    
    init(id: UUID = UUID(), startTime: Date = Date(), endTime: Date? = nil, notes: String = "", splitName: String? = nil, workoutName: String? = nil) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
        self.splitName = splitName
        self.workoutName = workoutName
    }
    
    var isCompleted: Bool {
        return endTime != nil
    }
}

@Model
final class SessionExercise {
    var id: UUID = UUID()
    var name: String
    var order: Int
    
    var session: WorkoutSession?
    
    @Relationship(deleteRule: .cascade, inverse: \WorkoutSet.exercise)
    var sets: [WorkoutSet] = []
    
    init(id: UUID = UUID(), name: String, order: Int) {
        self.id = id
        self.name = name
        self.order = order
    }
}

@Model
final class WorkoutSet {
    var id: UUID = UUID()
    var reps: Int
    var weight: Double
    var isDropSet: Bool
    var isSuperSet: Bool
    
    var exercise: SessionExercise?
    
    init(id: UUID = UUID(), reps: Int, weight: Double = 0, isDropSet: Bool = false, isSuperSet: Bool = false) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.isDropSet = isDropSet
        self.isSuperSet = isSuperSet
    }
}
