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
    @ObservedObject private var eventService = EventService.shared
    @State private var showEditSheet: Bool = false

    // Check if current user owns this event
    private var isOwner: Bool {
        guard let currentUser = UserService.shared.currentUser else {
            return false
        }
        return event.owner_id == currentUser.id
    }
    
    private var isFavorite: Bool {
        eventService.favoriteIds.contains(event.id)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                    // Event Image
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
                        .frame(maxWidth: .infinity, maxHeight: 200)
                        
                        // Category tag
                        VStack {
                            HStack {
                                Text(event.category)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(.thinMaterial)
                                    .cornerRadius(8)
                                Spacer()
                            }
                            Spacer()
                        }
                        .padding(16)
                        
                        // Event image (centered)
                        Image(systemName: event.imageName)
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
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
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Event Info Cards
                        VStack(spacing: 15) {
                            // Date Card
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.title2)
                                VStack(alignment: .leading) {
                                    Text("Date")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                    Text(event.date)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color(red: 0.0, green: 0.2, blue: 0.4)) // Dark blue
                            .cornerRadius(12)
                            
                            // Time Card
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.title2)
                                VStack(alignment: .leading) {
                                    Text("Time")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                    Text(event.time)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color(red: 0.0, green: 0.2, blue: 0.4)) // Dark blue
                            .cornerRadius(12)
                            
                            // Location Card
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(.white.opacity(0.8))
                                    .font(.title2)
                                VStack(alignment: .leading) {
                                    Text("Location")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                    Text(event.location)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color(red: 0.0, green: 0.2, blue: 0.4)) // Dark blue
                            .cornerRadius(12)
                            
                            // Organizer Card (if available)
                            if let clubName = event.clubName {
                                HStack {
                                    Image(systemName: "person.2")
                                        .foregroundColor(.white.opacity(0.8))
                                        .font(.title2)
                                    VStack(alignment: .leading) {
                                        Text("Organizer")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                        Text(clubName)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                }
                                .padding()
                                .background(Color(red: 0.0, green: 0.2, blue: 0.4)) // Dark blue
                                .cornerRadius(12)
                            }
                            
                            // Description Card (if available)
                            if let description = event.description, !description.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "text.alignleft")
                                            .foregroundColor(.white.opacity(0.8))
                                            .font(.title2)
                                        Text("Description")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.7))
                                        Spacer()
                                    }
                                    Text(description)
                                        .font(.body)
                                        .foregroundColor(.white)
                                }
                                .padding()
                                .background(Color(red: 0.0, green: 0.2, blue: 0.4)) // Dark blue
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        
                    }
                    
                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationTitle("Event Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white),
                trailing: isOwner ? AnyView(
                    Button(action: {
                        showEditSheet = true
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.white)
                    }
                ) : AnyView(EmptyView())
            )
            .background(Color.black)
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showEditSheet) {
                EditEventView(event: event)
            }
        }
    }
    
    private func toggleFavorite() {
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
}
