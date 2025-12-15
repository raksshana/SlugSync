//
//  EventService.swift
//  SlugSync
//
//  Created by Raksshana Harish Babu on 10/11/25.
//

import Foundation
import Combine

// MARK: - API Models
struct EventIn: Codable {
    let name: String
    let starts_at: String // ISO 8601 format
    let ends_at: String? // Always required (backend needs it, even if same as starts_at)
    let location: String
    let description: String?
    let host: String?
    let tags: String? // Backend expects comma-separated string, not array
}

struct EventOut: Codable, Identifiable {
    let id: Int
    let name: String
    let starts_at: String
    let ends_at: String?
    let location: String
    let description: String?
    let host: String?
    let tags: String?
    let created_at: String
    let owner_id: Int?
}

// MARK: - EventService
class EventService: ObservableObject {
    static let shared = EventService()
    
    // Backend API base URL
    private let baseURL = "https://slugsync-1.onrender.com"
    
    private init() {}
    
    // MARK: - Fetch Events
    func fetchEvents() async throws -> [EventOut] {
        guard let url = URL(string: "\(baseURL)/events/") else {
            throw NetworkError.invalidURL
        }
        
        print("🌐 Fetching events from: \(url)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("📥 Response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 200 {
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            print("❌ Error response: \(responseString)")
            throw NetworkError.invalidResponse
        }
        
        let events = try JSONDecoder().decode([EventOut].self, from: data)
        print("✅ Successfully fetched \(events.count) events")
        return events
    }
    
    // MARK: - Create Event
    func createEvent(_ event: EventIn) async throws -> EventOut {
        guard let url = URL(string: "\(baseURL)/events/") else {
            throw NetworkError.invalidURL
        }
        
        // Get access token from UserService
        guard let accessToken = UserService.shared.accessToken else {
            print("❌ No JWT token found in UserService. User may not be logged in.")
            throw NSError(domain: "EventService", code: 401, userInfo: [NSLocalizedDescriptionKey: "You must be logged in to create events"])
        }
        
        print("🔑 JWT Token found (length: \(accessToken.count))")
        print("🔑 Token preview: \(String(accessToken.prefix(30)))...")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        print("📤 Sending Authorization header: Bearer \(String(accessToken.prefix(30)))...")
        
        // Configure encoder to include null values
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(event)
        request.httpBody = jsonData
        
        // Debug: Print the JSON being sent
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📤 JSON being sent: \(jsonString)")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("Response status code: \(httpResponse.statusCode)")
        print("Response headers: \(httpResponse.allHeaderFields)")
        
        if httpResponse.statusCode != 201 {
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            print("❌ Error response body: \(responseString)")
            
            // Try to parse error detail for better error messages
            struct ErrorDetail: Codable {
                let detail: String?
            }
            
            struct ValidationError: Codable {
                let msg: String
            }
            
            struct ValidationErrorResponse: Codable {
                let detail: [ValidationError]?
            }
            
            // Try to parse as simple error detail
            if let errorDetail = try? JSONDecoder().decode(ErrorDetail.self, from: data),
               let detail = errorDetail.detail {
                print("❌ Error detail: \(detail)")
                throw NSError(domain: "EventService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: detail])
            }
            
            // Try to parse as validation error array
            if let validationError = try? JSONDecoder().decode(ValidationErrorResponse.self, from: data),
               let firstError = validationError.detail?.first {
                print("❌ Validation error: \(firstError.msg)")
                throw NSError(domain: "EventService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: firstError.msg])
            }
            
            // If it's a 500 error, suggest checking login status
            if httpResponse.statusCode == 500 {
                throw NSError(domain: "EventService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error. Please try logging out and logging back in. Error: \(responseString)"])
            }
            
            throw NSError(domain: "EventService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Error creating event: \(responseString)"])
        }
        
        let createdEvent = try JSONDecoder().decode(EventOut.self, from: data)
        return createdEvent
    }
    
    // MARK: - Get Single Event
    func getEvent(id: Int) async throws -> EventOut {
        guard let url = URL(string: "\(baseURL)/events/\(id)") else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        let event = try JSONDecoder().decode(EventOut.self, from: data)
        return event
    }
    
    // MARK: - Update Event
    func updateEvent(id: Int, event: EventIn) async throws -> EventOut {
        guard let url = URL(string: "\(baseURL)/events/\(id)") else {
            throw NetworkError.invalidURL
        }
        
        // Get access token from UserService
        guard let accessToken = UserService.shared.accessToken else {
            throw NSError(domain: "EventService", code: 401, userInfo: [NSLocalizedDescriptionKey: "You must be logged in to update events"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let jsonData = try JSONEncoder().encode(event)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        let updatedEvent = try JSONDecoder().decode(EventOut.self, from: data)
        return updatedEvent
    }
    
    // MARK: - Delete Event
    func deleteEvent(id: String) async throws {
        // Convert String ID to Int for backend
        guard let eventId = Int(id) else {
            throw NSError(domain: "EventService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid event ID format"])
        }
        
        guard let url = URL(string: "\(baseURL)/events/\(eventId)") else {
            throw NetworkError.invalidURL
        }
        
        // Get access token from UserService
        guard let accessToken = UserService.shared.accessToken else {
            throw NSError(domain: "EventService", code: 401, userInfo: [NSLocalizedDescriptionKey: "You must be logged in to delete events"])
        }
        
        print("🗑️ Deleting event with ID: \(eventId)")
        print("🌐 DELETE URL: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("📥 Delete response status: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode != 204 {
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            print("❌ Delete error response: \(responseString)")
            throw NetworkError.invalidResponse
        }
        
        print("✅ Event deleted successfully")
    }
}

// MARK: - Network Errors
enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case noData
    case decodingError
}