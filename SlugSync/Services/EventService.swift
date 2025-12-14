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
    let ends_at: String?
    let location: String
    let description: String?
    let host: String?
    let tags: [String]
}

struct EventOut: Codable, Identifiable {
    let id: String
    let name: String
    let starts_at: String
    let ends_at: String?
    let location: String
    let description: String?
    let host: String?
    let tags: [String]
    let created_at: String
}

// MARK: - EventService
class EventService: ObservableObject {
    static let shared = EventService()
    
    // Backend API base URL
    private let baseURL = "https://slugsync-1.onrender.com"
    
    private init() {}
    
    // MARK: - Fetch Events
    func fetchEvents() async throws -> [EventOut] {
        guard let url = URL(string: "\(baseURL)/events") else {
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
        guard let url = URL(string: "\(baseURL)/events") else {
            throw NetworkError.invalidURL
        }
        
        // Get access token from UserService
        guard let accessToken = UserService.shared.accessToken else {
            throw NSError(domain: "EventService", code: 401, userInfo: [NSLocalizedDescriptionKey: "You must be logged in to create events"])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let jsonData = try JSONEncoder().encode(event)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        print("Response status code: \(httpResponse.statusCode)")
        print("Response headers: \(httpResponse.allHeaderFields)")
        
        if httpResponse.statusCode != 201 {
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            print("Error response body: \(responseString)")
            throw NetworkError.invalidResponse
        }
        
        let createdEvent = try JSONDecoder().decode(EventOut.self, from: data)
        return createdEvent
    }
    
    // MARK: - Get Single Event
    func getEvent(id: String) async throws -> EventOut {
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
    func updateEvent(id: String, event: EventIn) async throws -> EventOut {
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
        guard let url = URL(string: "\(baseURL)/events/\(id)") else {
            throw NetworkError.invalidURL
        }
        
        // Get access token from UserService
        guard let accessToken = UserService.shared.accessToken else {
            throw NSError(domain: "EventService", code: 401, userInfo: [NSLocalizedDescriptionKey: "You must be logged in to delete events"])
        }
        
        print("🗑️ Deleting event with ID: \(id)")
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