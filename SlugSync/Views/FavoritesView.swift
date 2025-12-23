//
//  FavoritesView.swift
//  SlugSync
//
//  Created by Raksshana Harish Babu on 10/11/25.
//

import SwiftUI

extension Notification.Name {
    static let favoritesChanged = Notification.Name("favoritesChanged")
}

struct FavoritesView: View {
    @State private var favoriteEvents: [Event] = []
    @State private var searchText: String = ""
    @StateObject private var eventService = EventService.shared
    @StateObject private var userService = UserService.shared
    
    var filteredFavorites: [Event] {
        let today = Date()
        let calendar = Calendar.current
        
        // First filter by search
        let searchFiltered = searchText.isEmpty ? favoriteEvents : favoriteEvents.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            $0.location.localizedCaseInsensitiveContains(searchText)
        }
        
        // Then filter out past events
        return searchFiltered.filter { event in
            return isEventInFuture(event: event, today: today, calendar: calendar)
        }
    }
    
    private func isEventInFuture(event: Event, today: Date, calendar: Calendar) -> Bool {
        // Parse the event end date from ISO8601 string (ends_at)
        // Events should only disappear after their end date/time has passed
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Use ends_at if available, otherwise fall back to starts_at
        let dateString = event.ends_at ?? event.starts_at

        // Try ISO8601 format first
        if let eventEndDate = isoFormatter.date(from: dateString) {
            // Event is in future if its end date/time hasn't passed yet
            return eventEndDate >= today
        }

        // Fallback: try simple format
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        if let eventEndDate = simpleFormatter.date(from: dateString) {
            // Event is in future if its end date/time hasn't passed yet
            return eventEndDate >= today
        }

        // If parsing fails, show the event (better to show than hide)
        return true
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .center) {
                    Text("Saved")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 70)
                .padding(.bottom, 15)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    ZStack(alignment: .leading) {
                        if searchText.isEmpty {
                            Text("Search saved...")
                                .foregroundColor(.gray)
                        }
                        TextField("", text: $searchText)
                            .foregroundColor(.primary)
                    }
                }
                .padding(12)
                .background(Color(.systemGray5))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 15)
                
                if favoriteEvents.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 60))
                            .foregroundColor(.white)
                        Text("Nothing Saved Yet")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Tap the bookmark icon on events to save them")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Favorites list
                    ScrollView {
                        let columns = [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)
                        ]
                        
                        LazyVGrid(columns: columns, spacing: 15) {
                            ForEach(filteredFavorites) { event in
                                EventCardView(event: event)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .background(Color.clear)
                }
            }
            .navigationBarHidden(true)
            .background(Color.black)
            .ignoresSafeArea()
        }
        .onAppear {
            loadFavorites()
        }
        .onReceive(NotificationCenter.default.publisher(for: .favoritesChanged)) { _ in
            loadFavorites()
        }
        .onReceive(NotificationCenter.default.publisher(for: .eventsUpdated)) { _ in
            loadFavorites()
        }
    }
    
    private func loadFavorites() {
        guard userService.currentUser != nil else {
            favoriteEvents = []
            return
        }

        Task {
            do {
                let apiFavorites = try await eventService.fetchFavorites()
                await MainActor.run {
                    self.favoriteEvents = apiFavorites.map { apiEvent in
                        Event(
                            id: apiEvent.id,
                            name: apiEvent.name,
                            location: apiEvent.location,
                            starts_at: apiEvent.starts_at,
                            ends_at: apiEvent.ends_at,
                            host: apiEvent.host,
                            description: apiEvent.description,
                            tags: apiEvent.tags,
                            created_at: apiEvent.created_at,
                            owner_id: apiEvent.owner_id
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    self.favoriteEvents = []
                }
                print("❌ Error loading favorites: \(error)")
            }
        }
    }
}
