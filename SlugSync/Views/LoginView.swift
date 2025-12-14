//
//  LoginView.swift
//  SlugSync
//
//  Created by Raksshana Harish Babu on 11/4/25.
//

import SwiftUI

struct LoginView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var userService = UserService.shared
    
    @State private var isGoogleLoading: Bool = false
    @State private var errorMessage: String = ""
    private let googleSignInService = GoogleSignInService.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 1.0, green: 0.8, blue: 0.0), // UCSC Gold
                        Color(red: 0.0, green: 0.3, blue: 0.6)  // UCSC Blue
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        Text("Sign In")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.top, 60)
                        
                        Text("Sign in with your UCSC Google account")
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
                        
                        Spacer()
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
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
                
                // Login with Google token (if UserService has this method)
                // For now, we'll need to add this to UserService
                _ = try await userService.loginWithGoogle(idToken: idToken)
                
                await MainActor.run {
                    isGoogleLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isGoogleLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}


