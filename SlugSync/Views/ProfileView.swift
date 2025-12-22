//
//  ProfileView.swift
//  SlugSync
//
//  Created by Raksshana Harish Babu on 11/4/25.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var userService = UserService.shared
    @State private var isGoogleLoading: Bool = false
    @State private var errorMessage: String = ""
    private let googleSignInService = GoogleSignInService.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    if let user = userService.currentUser {
                        // User is logged in
                        VStack(spacing: 30) {
                            // Profile Picture and User Info (side by side)
                            HStack(alignment: .top, spacing: 20) {
                                // Profile Picture (left side)
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 100, height: 100)
                                    
                                    Image(systemName: "person.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                // User Info Section (right side)
                                VStack(alignment: .leading, spacing: 15) {
                                    // Name
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Name:")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                        Text(user.name)
                                            .font(.title3)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                    }
                                    
                                    // Email
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Email:")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                        Text(user.email)
                                            .font(.body)
                                            .foregroundColor(.white)
                                    }
                                    
                                    // Member Since
                                    if let createdDate = parseDate(user.created_at) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Member Since:")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.7))
                                            Text(formatDate(createdDate))
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.9))
                                        }
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 30)
                            .padding(.top, 40)
                            
                            Spacer()
                            
                            // Logout Button
                            Button(action: {
                                userService.logout()
                            }) {
                                Text("Log Out")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal, 30)
                            .padding(.bottom, 40)
                        }
                        .padding(.top, 20)
                    } else {
                        // User is not logged in
                        VStack(spacing: 20) {
                            Image(systemName: "person.circle")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("Not Signed In")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("Sign in with your UCSC Google account to continue")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            // Error Message
                            if !errorMessage.isEmpty {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.subheadline)
                                    .padding(.horizontal, 30)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 10)
                            }
                            
                            // Google Sign-In Button
                            Button(action: {
                                signInWithGoogle()
                            }) {
                                HStack(spacing: 12) {
                                    if isGoogleLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "globe")
                                            .font(.title3)
                                        Text("Sign in with Google")
                                            .font(.headline)
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                            }
                            .padding(.horizontal, 30)
                            .padding(.top, 20)
                            .disabled(isGoogleLoading)
                            .opacity(isGoogleLoading ? 0.6 : 1.0)
                        }
                        .padding(.top, 100)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .font(.headline)
                }
            }
        }
    }
    
    private func signInWithGoogle() {
        isGoogleLoading = true
        errorMessage = ""
        
        Task {
            do {
                // Get Google ID token
                let idToken = try await googleSignInService.signIn()
                
                // Login with Google token
                _ = try await userService.loginWithGoogle(idToken: idToken)
                
                await MainActor.run {
                    isGoogleLoading = false
                }
            } catch {
                await MainActor.run {
                    isGoogleLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Try with fractional seconds first
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
