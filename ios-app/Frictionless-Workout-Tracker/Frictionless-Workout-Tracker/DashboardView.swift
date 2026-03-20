import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query(sort: \WorkoutSession.startTime, order: .forward) private var sessions: [WorkoutSession]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Total Volume (Last 7 Days)")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    volumeChart
                        .frame(height: 250)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
        }
    }
    
    private var volumeChart: some View {
        let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let recentSessions = sessions.filter { $0.startTime >= oneWeekAgo }
        
        let data = VolumeChartData(sessions: recentSessions)
        
        return Chart {
             ForEach(data.items) { item in
                 BarMark(
                     x: .value("Date", item.date, unit: .day),
                     y: .value("Volume (lbs)", item.volume)
                 )
                 .foregroundStyle(.blue.gradient)
             }
         }
    }
}

struct VolumeChartData {
    var items: [VolumeDataItem] = []
    
    init(sessions: [WorkoutSession]) {
        var volumeByDate: [Date: Double] = [:]
        
        let calendar = Calendar.current
        for session in sessions {
            let startOfDay = calendar.startOfDay(for: session.startTime)
            var sessionVol: Double = 0
            for ex in session.exercises {
                for set in ex.sets {
                    sessionVol += Double(set.reps) * set.weight
                }
            }
            if sessionVol > 0 {
                volumeByDate[startOfDay, default: 0] += sessionVol
            }
        }
        
        items = volumeByDate.map { VolumeDataItem(date: $0.key, volume: $0.value) }
            .sorted(by: { $0.date < $1.date })
    }
}

struct VolumeDataItem: Identifiable {
    let id = UUID()
    let date: Date
    let volume: Double
}
