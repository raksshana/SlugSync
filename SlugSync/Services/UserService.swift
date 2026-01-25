//
//  UserService.swift
//  SlugSync
//
//  Created by Raksshana Harish Babu on 10/11/25.
//

import Foundation
import SwiftUI
import Combine

// MARK: - API Models
struct UserCreate: Codable {
    let email: String
    let name: String
    let password: String
}

struct UserOut: Codable, Identifiable, Equatable {
    let id: Int
    let email: String
    let name: String
    let created_at: String
    let is_host: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id, email, name, created_at
        case is_host
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        name = try container.decode(String.self, forKey: .name)
        created_at = try container.decode(String.self, forKey: .created_at)
        is_host = try container.decodeIfPresent(Bool.self, forKey: .is_host)
    }
}

// MARK: - UserService
class UserService: ObservableObject {
    static let shared = UserService()
    
    // Backend API base URL
    private let baseURL = "https://slugsync-1.onrender.com"
    
    // User defaults keys
    private let userDefaultsKey = "currentUser"
    private let tokenDefaultsKey = "accessToken"
    
    @Published var currentUser: UserOut? {
        didSet {
            saveCurrentUser()
        }
    }
    
    var accessToken: String? {
        get {
            UserDefaults.standard.string(forKey: tokenDefaultsKey)
        }
        set {
            if let token = newValue {
                UserDefaults.standard.set(token, forKey: tokenDefaultsKey)
            } else {
                UserDefaults.standard.removeObject(forKey: tokenDefaultsKey)
            }
        }
    }
    
    private init() {
        loadCurrentUser()
    }
    
    // MARK: - Register User
    func registerUser(email: String, name: String, password: String) async throws -> UserOut {
        // Try multiple endpoint variations
        let endpoints = [
            "\(baseURL)/users/register",  // New endpoint
            "\(baseURL)/users/",          // With trailing slash
            "\(baseURL)/users"            // Without trailing slash
        ]
        
        var lastError: Error?
        var lastStatusCode: Int?
        var lastResponseBody: String?
        
        // First, try to wake up the server with a quick GET request
        print("🌐 Attempting to wake up server...")
        if let wakeURL = URL(string: "\(baseURL)/events?limit=1") {
            let wakeRequest = URLRequest(url: wakeURL, timeoutInterval: 10)
            _ = try? await URLSession.shared.data(for: wakeRequest)
            // Wait a moment for server to fully wake up
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        }
        
        for endpointURLString in endpoints {
            guard let url = URL(string: endpointURLString) else {
                continue
            }
            
            print("🌐 Attempting registration at: \(endpointURLString)")
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.timeoutInterval = 30 // 30 second timeout
            
            let userCreate = UserCreate(email: email, name: name, password: password)
            let jsonData = try JSONEncoder().encode(userCreate)
            
            // Print request for debugging
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📤 Request body: \(jsonString)")
            }
            
            request.httpBody = jsonData
            
            do {
                // Use async with timeout
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    lastError = NetworkError.invalidResponse
                    continue
                }
                
                let responseString = String(data: data, encoding: .utf8) ?? "No response body"
                print("📥 Registration response status: \(httpResponse.statusCode)")
                print("📥 Response URL: \(url)")
                print("📥 Response body: \(responseString)")
                
                if httpResponse.statusCode == 201 {
                    let user = try JSONDecoder().decode(UserOut.self, from: data)
                    await MainActor.run {
                        self.currentUser = user
                    }
                    print("✅ Registration successful!")
                    return user
                } else {
                    lastStatusCode = httpResponse.statusCode
                    lastResponseBody = responseString
                    
                    if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                       let detail = errorData["detail"] {
                        print("❌ Error detail: \(detail)")
                        // If it's a 404, try next endpoint
                        if httpResponse.statusCode == 404 {
                            print("⚠️ Endpoint \(endpointURLString) returned 404, trying next endpoint...")
                            lastError = NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Endpoint not found"])
                            continue
                        }
                        // For other errors, throw immediately
                        throw NSError(domain: "UserService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: detail])
                    }
                    // If it's a 404, try next endpoint
                    if httpResponse.statusCode == 404 {
                        print("⚠️ Endpoint \(endpointURLString) returned 404, trying next endpoint...")
                        lastError = NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Endpoint not found"])
                        continue
                    }
                    // For other non-201 status codes, throw
                    throw NSError(domain: "UserService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Registration failed with status \(httpResponse.statusCode): \(responseString)"])
                }
            } catch {
                print("❌ Request error: \(error)")
                // If it's a timeout or network error, try next endpoint
                if let urlError = error as? URLError {
                    print("❌ URLError code: \(urlError.code.rawValue)")
                    if urlError.code == .timedOut {
                        print("⚠️ Request timed out for \(endpointURLString)")
                        // If this is the first endpoint and it timed out, the server might be sleeping
                        // Try waiting a bit longer and retry once
                        if endpointURLString == endpoints.first {
                            print("⏳ Server might be sleeping (free tier). Waiting 5 seconds and retrying...")
                            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                            // Retry this endpoint once
                            continue
                        }
                        lastError = NSError(domain: "UserService", code: -1001, userInfo: [NSLocalizedDescriptionKey: "Request timed out. The server may be sleeping (free tier instances can take 50+ seconds to wake up). Please try again in a moment."])
                        continue
                    }
                    // For other network errors, try next endpoint
                    if urlError.code == .notConnectedToInternet || urlError.code == .networkConnectionLost {
                        throw error // Don't continue on network issues
                    }
                    lastError = error
                    continue
                }
                // If decoding fails, don't continue - endpoint exists but response is wrong
                if let decodingError = error as? DecodingError {
                    print("❌ Decoding error: \(decodingError)")
                    throw error
                }
                lastError = error
                continue
            }
        }
        
        // If we get here, all endpoints failed
        if let error = lastError {
            // If all endpoints returned 404, provide helpful message
            if lastStatusCode == 404 {
                let errorMsg = "Registration endpoint not found. The backend may need to be deployed. Tried: \(endpoints.joined(separator: ", ")). Last response: \(lastResponseBody ?? "none")"
                print("❌ \(errorMsg)")
                throw NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: errorMsg])
            }
            // If it's a timeout error, provide helpful message about free tier
            if let nsError = error as NSError?, nsError.code == -1001 {
                throw NSError(domain: "UserService", code: -1001, userInfo: [NSLocalizedDescriptionKey: "Request timed out. Render.com free tier instances can take 50+ seconds to wake up after inactivity. Please wait a moment and try again, or check if the server is running."])
            }
            throw error
        }
        throw NSError(domain: "UserService", code: lastStatusCode ?? 500, userInfo: [NSLocalizedDescriptionKey: "Registration failed: endpoint not available. Last response: \(lastResponseBody ?? "none")"])
    }
    
    // MARK: - Save/Load User
    private func saveCurrentUser() {
        if let user = currentUser,
           let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        }
    }
    
    private func loadCurrentUser() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let user = try? JSONDecoder().decode(UserOut.self, from: data) {
            self.currentUser = user
        }
    }
    
    // MARK: - Login
    func login(email: String, password: String) async throws -> UserOut {
        guard let url = URL(string: "\(baseURL)/token") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        // OAuth2PasswordRequestForm expects form data
        let formData = "username=\(email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? email)&password=\(password.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? password)"
        request.httpBody = formData.data(using: .utf8)
        
        print("🌐 Attempting login at: \(url)")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            print("📥 Login response status: \(httpResponse.statusCode)")
            print("📥 Response body: \(responseString)")
            
            if httpResponse.statusCode == 200 {
                // Parse token response
                struct TokenResponse: Codable {
                    let access_token: String
                    let token_type: String
                }
                let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                
                // Store the token
                self.accessToken = tokenResponse.access_token
                print("✅ Token stored, fetching user info...")
                
                // Now fetch user info using the token
                return try await fetchCurrentUser()
            } else {
                if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
                   let detail = errorData["detail"] {
                    throw NSError(domain: "UserService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: detail])
                }
                throw NSError(domain: "UserService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Login failed: \(responseString)"])
            }
        } catch {
            print("❌ Login error: \(error)")
            throw error
        }
    }
    
    // MARK: - Fetch Current User (after login)
    private func fetchCurrentUser() async throws -> UserOut {
        guard let token = accessToken else {
            throw NSError(domain: "UserService", code: 401, userInfo: [NSLocalizedDescriptionKey: "No access token available"])
        }
        
        guard let url = URL(string: "\(baseURL)/users/me") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        print("🌐 Fetching user info from: \(url)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        let responseString = String(data: data, encoding: .utf8) ?? "No response body"
        print("📥 User info response status: \(httpResponse.statusCode)")
        print("📥 User info response body: \(responseString)")
        
        if httpResponse.statusCode == 200 {
            let user = try JSONDecoder().decode(UserOut.self, from: data)
            await MainActor.run {
                self.currentUser = user
            }
            print("✅ User info fetched and stored")
            return user
        } else {
            print("❌ Failed to fetch user info. Status: \(httpResponse.statusCode), Response: \(responseString)")
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let detail = errorData["detail"] {
                throw NSError(domain: "UserService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: detail])
            }
            throw NSError(domain: "UserService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch user info: \(responseString)"])
        }
    }
    
    // MARK: - Google Login
    func loginWithGoogle(idToken: String) async throws -> UserOut {
        guard let url = URL(string: "\(baseURL)/auth/google") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        struct GoogleTokenRequest: Codable {
            let id_token: String
        }
        
        let requestBody = GoogleTokenRequest(id_token: idToken)
        let jsonData = try JSONEncoder().encode(requestBody)
        request.httpBody = jsonData
        
        print("🌐 Attempting Google login at: \(url)")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        let responseString = String(data: data, encoding: .utf8) ?? "No response body"
        print("📥 Google login response status: \(httpResponse.statusCode)")
        print("📥 Response body: \(responseString)")
        
        if httpResponse.statusCode == 200 {
            // Backend returns Token (access_token and token_type)
            struct TokenResponse: Codable {
                let access_token: String
                let token_type: String
            }
            
            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
            
            // Store the token
            self.accessToken = tokenResponse.access_token
            print("✅ Token stored, fetching user info...")
            
            // Now fetch user info using the token
            return try await fetchCurrentUser()
        } else {
            // Try to get detailed error message
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let detail = errorData["detail"] {
                print("❌ Google login error detail: \(detail)")
                throw NSError(domain: "UserService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: detail])
            }
            // If no detail, show full response
            print("❌ Google login failed. Full response: \(responseString)")
            throw NSError(domain: "UserService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Google login failed: \(responseString)"])
        }
    }
    
    func logout() {
        currentUser = nil
        accessToken = nil
    }
}


