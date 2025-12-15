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
            ZStack(alignment: .topLeading) {
                // Event image
                Image(systemName: event.imageName)
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: 150)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Category tag
                Text(event.category)
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.thinMaterial)
                    .cornerRadius(8)
                    .padding(12)
                
                // Bookmark button (top right)
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            toggleFavorite()
                        }) {
                            Image(systemName: isFavorite ? "bookmark.fill" : "bookmark")
                                .font(.title2)
                                .foregroundColor(isFavorite ? .yellow : .white)
                                .padding(8)
                                .background(.thinMaterial)
                                .cornerRadius(20)
                        }
                        .padding(12)
                    }
                    Spacer()
                }
                
            }
            
            // Event details
            VStack(alignment: .leading, spacing: 10) {
                Text(event.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                // Date
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                    Text(event.date)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Time
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                    Text(event.time)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Location
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.gray)
                    Text(event.location)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Divider()
                    .background(Color.gray.opacity(0.3))
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
                            .background(.thinMaterial)
                            .cornerRadius(15)
                    }
                    
                    Spacer()
                    
                    // View Details button (right side)
                    Button(action: {
                        showDetails = true
                    }) {
                        HStack {
                            Text("View Details")
                                .font(.footnote)
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right")
                                .font(.footnote)
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .padding()
        }
        .background(Color.white.opacity(0.9))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
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

                // Notify other views to refresh on main thread
                await MainActor.run {
                    NotificationCenter.default.post(name: .eventsUpdated, object: nil)
                }

            } catch {
                print("❌ Error deleting event: \(error)")
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
