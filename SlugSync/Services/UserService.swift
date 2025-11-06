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

struct UserOut: Codable, Identifiable {
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
    
    @Published var currentUser: UserOut? {
        didSet {
            saveCurrentUser()
        }
    }
    
    private init() {
        loadCurrentUser()
    }
    
    // MARK: - Register User
    func registerUser(email: String, name: String, password: String) async throws -> UserOut {
        guard let url = URL(string: "\(baseURL)/users/register") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let userCreate = UserCreate(email: email, name: name, password: password)
        let jsonData = try JSONEncoder().encode(userCreate)
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        if httpResponse.statusCode == 201 {
            let user = try JSONDecoder().decode(UserOut.self, from: data)
            await MainActor.run {
                self.currentUser = user
            }
            return user
        } else {
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            if let errorData = try? JSONDecoder().decode([String: String].self, from: data),
               let detail = errorData["detail"] {
                throw NSError(domain: "UserService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: detail])
            }
            throw NetworkError.invalidResponse
        }
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
    
    func logout() {
        currentUser = nil
    }
}


