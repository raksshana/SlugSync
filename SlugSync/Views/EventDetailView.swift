//
//  EventDetailView.swift
//  SlugSync
//
//  Created by Raksshana Harish Babu on 10/11/25.
//

import SwiftUI

struct EventDetailView: View {
    let event: Event
    @Environment(\.presentationMode) var presentationMode
    @State private var isFavorite: Bool = false
    @State private var showEditSheet: Bool = false

    // Check if current user owns this event
    private var isOwner: Bool {
        guard let currentUser = UserService.shared.currentUser else {
            return false
        }
        return event.owner_id == currentUser.id
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Event Image
                    ZStack(alignment: .topLeading) {
                        Image(systemName: event.imageName)
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, maxHeight: 200)
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
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.thinMaterial)
                            .cornerRadius(8)
                            .padding(16)
                        
                        // Favorite button
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
                                .padding(16)
                            }
                            Spacer()
                        }
                    }
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // Event Details
                    VStack(spacing: 20) {
                        // Event Title
                        Text(event.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Event Info Cards
                        VStack(spacing: 15) {
                            // Date Card
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                VStack(alignment: .leading) {
                                    Text("Date")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(event.date)
                                        .font(.headline)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            // Time Card
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                VStack(alignment: .leading) {
                                    Text("Time")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(event.time)
                                        .font(.headline)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            // Location Card
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(.red)
                                    .font(.title2)
                                VStack(alignment: .leading) {
                                    Text("Location")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(event.location)
                                        .font(.headline)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                            // Organizer Card (if available)
                            if let clubName = event.clubName {
                                HStack {
                                    Image(systemName: "person.2")
                                        .foregroundColor(.orange)
                                        .font(.title2)
                                    VStack(alignment: .leading) {
                                        Text("Organizer")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(clubName)
                                            .font(.headline)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            
                            // Description Card (if available)
                            if let description = event.description, !description.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "text.alignleft")
                                            .foregroundColor(.purple)
                                            .font(.title2)
                                        Text("Description")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Spacer()
                                    }
                                    Text(description)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        
                    }
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: isOwner ? AnyView(
                    Button(action: {
                        showEditSheet = true
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                ) : AnyView(EmptyView())
            )
            .onAppear {
                loadFavoriteStatus()
            }
            .sheet(isPresented: $showEditSheet) {
                EditEventView(event: event)
            }
        }
    }
    
    private func toggleFavorite() {
        isFavorite.toggle()
        saveFavoriteStatus()
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
