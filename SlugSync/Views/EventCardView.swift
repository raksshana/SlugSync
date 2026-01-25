//
//  EventCardView.swift
//  SlugSync
//
//  Created by Raksshana Harish Babu on 10/11/25.
//

import SwiftUI

struct EventCardView: View {
    let event: Event
    @ObservedObject private var eventService = EventService.shared
    @StateObject private var userService = UserService.shared
    @State private var showDetails: Bool = false
    @State private var showLoginAlert: Bool = false
    @State private var showLoginView: Bool = false
    
    private var isFavorite: Bool {
        eventService.favoriteIds.contains(event.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image with category tag and favorite button
            ZStack {
                // Gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.3, blue: 0.7), // Medium-dark blue
                        Color(red: 0.95, green: 0.8, blue: 0.2)  // Warm golden-yellow
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(maxWidth: .infinity, maxHeight: 100)
                
                // Category tag (top left)
                VStack {
                    HStack {
                        Text(event.category)
                            .font(.system(size: 9))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.thinMaterial)
                            .cornerRadius(5)
                        Spacer()
                    }
                    Spacer()
                }
                .padding(8)
                
                // Event image (centered)
                Image(systemName: event.imageName)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                
                // Bookmark button (top right)
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            toggleFavorite()
                        }) {
                            Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                                .font(.title3)
                                .foregroundColor(isFavorite ? .yellow : .white)
                                .padding(6)
                                .background(.thinMaterial)
                                .cornerRadius(18)
                        }
                        .padding(8)
                    }
                    Spacer()
                }
            }
            
            // Event details
            VStack(alignment: .leading, spacing: 8) {
                Text(event.title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                // Date
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.caption)
                    Text(event.date)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
                
                // Time
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.caption)
                    Text(event.time)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
                
                // Location
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.caption)
                    Text(event.location)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                    .padding(.vertical, 5)
                
                // Bottom buttons
                HStack {
                    // Delete button (left side)
                    Button(action: {
                        deleteEvent()
                    }) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(15)
                    }
                    
                    Spacer()
                    
                    // View Details button (right side)
                    Button(action: {
                        showDetails = true
                    }) {
                        HStack(spacing: 2) {
                            Text("Details")
                                .font(.caption2)
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                                .font(.caption2)
                        }
                        .foregroundColor(.white)
                    }
                }
            }
            .padding(10)
        }
        .background(Color(red: 0.0, green: 0.2, blue: 0.4)) // Dark blue
        .cornerRadius(15)
        .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
        .sheet(isPresented: $showDetails) {
            EventDetailView(event: event)
        }
        .alert("Sign In Required", isPresented: $showLoginAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign In") {
                showLoginView = true
            }
        } message: {
            Text("You need to sign in to save events. Sign in to continue.")
        }
        .sheet(isPresented: $showLoginView) {
            LoginView()
        }
    }
    
    private func toggleFavorite() {
        // Check if user is logged in
        guard userService.currentUser != nil else {
            showLoginAlert = true
            return
        }
        
        Task {
            do {
                if isFavorite {
                    try await eventService.unfavoriteEvent(id: event.id)
                } else {
                    try await eventService.favoriteEvent(id: event.id)
                }
                
                await MainActor.run {
                    NotificationCenter.default.post(name: Notification.Name("favoritesChanged"), object: nil)
                }
            } catch {
                print("❌ Error toggling favorite: \(error)")
            }
        }
    }
    
    private func deleteEvent() {
        Task {
            do {
                // Convert Int ID to String for deleteEvent
                let eventId = String(event.id)
                try await EventService.shared.deleteEvent(id: eventId)
                print("✅ Event deleted successfully")

                // Remove from favorites if it was favorited
                await MainActor.run {
                    removeFavoriteIfExists()

                    // Notify other views to refresh
                    NotificationCenter.default.post(name: Notification.Name("eventsUpdated"), object: nil)
                }

            } catch {
                print("❌ Error deleting event: \(error)")
            }
        }
    }

    private func removeFavoriteIfExists() {
        // When an event is deleted, the backend will handle cascade deletion of favorites
        // Just notify that favorites might have changed
        NotificationCenter.default.post(name: Notification.Name("favoritesChanged"), object: nil)
    }
}
