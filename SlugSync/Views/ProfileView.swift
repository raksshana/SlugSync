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
    @State private var showSignUp = false
    @State private var showLogin = false
    
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
                
                VStack(spacing: 30) {
                    if let user = userService.currentUser {
                        // User is logged in
                        VStack(spacing: 30) {
                            // Profile Picture (empty placeholder)
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.top, 40)
                            
                            // User Info Section
                            VStack(alignment: .leading, spacing: 20) {
                                // Name
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Name:")
                                        .font(.headline)
                                        .foregroundColor(.white.opacity(0.8))
                                    Text(user.name)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                                
                                Divider()
                                    .background(Color.white.opacity(0.3))
                                
                                // Email
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Email:")
                                        .font(.headline)
                                        .foregroundColor(.white.opacity(0.8))
                                    Text(user.email)
                                        .font(.title3)
                                        .foregroundColor(.white)
                                }
                                
                                // Member Since
                                if let createdDate = parseDate(user.created_at) {
                                    Divider()
                                        .background(Color.white.opacity(0.3))
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Member Since:")
                                            .font(.headline)
                                            .foregroundColor(.white.opacity(0.8))
                                        Text(formatDate(createdDate))
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 30)
                            
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
                            
                            Text("Log in to your account or create a new one")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            // Log In Button
                            Button(action: {
                                showLogin = true
                            }) {
                                Text("Log In")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal, 30)
                            .padding(.top, 20)
                            
                            // Create Account Button
                            Button(action: {
                                showSignUp = true
                            }) {
                                Text("Create Account")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal, 30)
                            .padding(.top, 10)
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
                }
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showLogin) {
                LoginView()
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
