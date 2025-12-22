//
//  EventCardView.swift
//  SlugSync
//
//  Created by Raksshana Harish Babu on 10/11/25.
//

import SwiftUI

struct EventCardView: View {
    let event: Event
    @State private var isFavorite: Bool = false
    @State private var showDetails: Bool = false
    
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
        .onAppear {
            loadFavoriteStatus()
        }
        .sheet(isPresented: $showDetails) {
            EventDetailView(event: event)
        }
    }
    
    private func toggleFavorite() {
        isFavorite.toggle()
        saveFavoriteStatus()
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
                    NotificationCenter.default.post(name: .eventsUpdated, object: nil)
                }

            } catch {
                print("❌ Error deleting event: \(error)")
            }
        }
    }

    private func removeFavoriteIfExists() {
        var favorites = loadFavorites()
        let originalCount = favorites.count

        // Remove the deleted event from favorites
        favorites.removeAll { $0.id == event.id }

        // Only update if something was actually removed
        if favorites.count < originalCount {
            if let encoded = try? JSONEncoder().encode(favorites) {
                UserDefaults.standard.set(encoded, forKey: "favoriteEvents")
                // Notify that favorites changed
                NotificationCenter.default.post(name: .favoritesChanged, object: nil)
                print("✅ Removed deleted event from favorites")
            }
        }
    }
    
    private func loadFavoriteStatus() {
        // Check if this event is in favorites
        if let data = UserDefaults.standard.data(forKey: "favoriteEvents"),
           let favorites = try? JSONDecoder().decode([Event].self, from: data) {
            isFavorite = favorites.contains { $0.id == event.id }
        }
    }
    
    private func saveFavoriteStatus() {
        // Load current favorites
        var favorites = loadFavorites()
        
        if isFavorite {
            // Add to favorites if not already there
            if !favorites.contains(where: { $0.id == event.id }) {
                favorites.append(event)
            }
        } else {
            // Remove from favorites
            favorites.removeAll { $0.id == event.id }
        }
        
        // Save back to UserDefaults
        if let encoded = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(encoded, forKey: "favoriteEvents")
            // Notify that favorites changed
            NotificationCenter.default.post(name: .favoritesChanged, object: nil)
        }
    }
    
    private func loadFavorites() -> [Event] {
        if let data = UserDefaults.standard.data(forKey: "favoriteEvents"),
           let favorites = try? JSONDecoder().decode([Event].self, from: data) {
            return favorites
        }
        return []
    }
}
