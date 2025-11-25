//
//  GoogleSignInService.swift
//  SlugSync
//
//  Created by Raksshana Harish Babu on 11/4/25.
//

import Foundation
import SwiftUI
import UIKit
// Uncomment when Google Sign-In SDK is added via Swift Package Manager
import GoogleSignIn

class GoogleSignInService {
    static let shared = GoogleSignInService()
    
    // Set this to your Google OAuth Client ID (iOS client ID from Google Cloud Console)
    var googleClientID: String {
        return "907752492307-gsg1nir0smku3u0ekonfu9im74u9sknp.apps.googleusercontent.com"
    }
    
    private init() {
        // Configure Google Sign-In
        // Option 1: Use GoogleService-Info.plist (recommended)
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path),
           let clientId = plist["CLIENT_ID"] as? String {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
        } else {
            // Option 2: Use hardcoded client ID
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: googleClientID)
        }
    }
    
    func signIn() async throws -> String {
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = await windowScene.windows.first?.rootViewController else {
            throw NSError(domain: "GoogleSignInService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No presenting view controller"])
        }
        
        // Configure if not already configured
        if GIDSignIn.sharedInstance.configuration == nil {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: googleClientID)
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "GoogleSignInService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No ID token from Google"])
        }
        
        return idToken
    }
}
