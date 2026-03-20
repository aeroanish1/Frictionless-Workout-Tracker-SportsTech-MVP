import Foundation

struct GeminiResponse: Codable {
    let date: String?
    let notes: String?
    let exercises: [GeminiExercise]
}

struct GeminiExercise: Codable {
    let name: String
    let muscleGroup: String?
    let sets: Int?
    let reps: Int?
    let weight: Double?
    let distance: Double?
    let duration: Double?
    let calories: Double?
}

struct GeminiSet: Codable {
    let reps: Int
    let weight: Double
}

struct GeminiResponseWrapper: Decodable {
    struct Candidate: Decodable {
        struct Content: Decodable {
            struct Part: Decodable {
                let text: String
            }
            let parts: [Part]
        }
        let content: Content
    }
    let candidates: [Candidate]
}

class GeminiService {
    static let shared = GeminiService()
    
    private let apiKey = "AIzaSyAjBi_5ICcENaGsnDqDssZRZzwd10-y4HM"
    private var baseURL: String {
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKey)"
    }
    
    func parseTextWorkout(text: String) async throws -> GeminiResponse {
        let prompt = "Extract workout data from this text: \"\(text)\". Return a JSON object with 'date' (ISO string), 'notes' (string), and 'exercises' (array of objects with 'name', 'muscleGroup', 'sets', 'reps', 'weight'). If no workout is found, return an empty exercises array."
        return try await makeRequest(prompt: prompt, mimeType: nil, data: nil)
    }
    
    func parseAudioWorkout(audioBase64: String, mimeType: String = "audio/m4a") async throws -> GeminiResponse {
        let prompt = "Extract workout data from this audio. Return a JSON object with 'date' (ISO string), 'notes' (string), and 'exercises' (array of objects with 'name', 'muscleGroup', 'sets', 'reps', 'weight'). If no workout is found, return an empty exercises array."
        return try await makeRequest(prompt: prompt, mimeType: mimeType, data: audioBase64)
    }
    
    func parseImageWorkout(imageBase64: String, mimeType: String = "image/jpeg") async throws -> GeminiResponse {
        let prompt = "Extract workout data from this gym machine summary image. The image could be from a treadmill, elliptical, rower, or a strength machine. Rules: 1. Identify the machine type and put it in 'notes'. 2. For CARDIO: 'distance', 'duration', 'calories'. 3. For STRENGTH: 'name', 'sets', 'reps', 'weight' (in lbs). Return JSON with 'date', 'notes', and 'exercises' array."
        return try await makeRequest(prompt: prompt, mimeType: mimeType, data: imageBase64)
    }
    
    func parseActiveSet(text: String, audioBase64: String?, exerciseName: String) async throws -> [GeminiSet] {
        let prompt = "The user is doing the exercise \"\(exerciseName)\". They logged an entry (text or audio). Extract the sets performed from this log. Return a JSON array of set objects. Each object should have 'reps' (integer) and 'weight' (number, in lbs). Return only the raw JSON array (e.g., [{\"reps\": 10, \"weight\": 135}]). Text log: \"\(text)\""
        return try await makeRequest(prompt: prompt, mimeType: audioBase64 != nil ? "audio/m4a" : nil, data: audioBase64)
    }
    
    private func makeRequest<T: Decodable>(prompt: String, mimeType: String?, data: String?) async throws -> T {
        guard let url = URL(string: baseURL) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var parts: [[String: Any]] = [["text": prompt]]
        
        if let mimeType = mimeType, let data = data {
            parts.append([
                "inlineData": [
                    "mimeType": mimeType,
                    "data": data
                ]
            ])
        }
        
        let body: [String: Any] = [
            "contents": [ ["parts": parts] ],
            "generationConfig": [ "responseMimeType": "application/json" ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 120
        let session = URLSession(configuration: config)
        
        let (responseData, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let wrapper = try JSONDecoder().decode(GeminiResponseWrapper.self, from: responseData)
        guard var jsonString = wrapper.candidates.first?.content.parts.first?.text else {
            throw URLError(.cannotParseResponse)
        }
        
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        if jsonString.hasPrefix("```json") { jsonString = String(jsonString.dropFirst(7)) }
        else if jsonString.hasPrefix("```") { jsonString = String(jsonString.dropFirst(3)) }
        if jsonString.hasSuffix("```") { jsonString = String(jsonString.dropLast(3)) }
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw URLError(.cannotParseResponse)
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(T.self, from: jsonData)
            return decodedResponse
        } catch {
            print("Gemini JSON Decoding error: \(error)")
            throw NSError(domain: "GeminiError", code: 1, userInfo: [NSLocalizedDescriptionKey: "JSON Format Error: \(error.localizedDescription)"])
        }
    }
}
