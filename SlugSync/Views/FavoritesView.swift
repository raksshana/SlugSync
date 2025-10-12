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
    
    var filteredFavorites: [Event] {
        let today = Date()
        let calendar = Calendar.current
        
        // First filter by search
        let searchFiltered = searchText.isEmpty ? favoriteEvents : favoriteEvents.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        
        // Then filter out past events
        return searchFiltered.filter { event in
            return isEventInFuture(event: event, today: today, calendar: calendar)
        }
    }
    
    private func isEventInFuture(event: Event, today: Date, calendar: Calendar) -> Bool {
        // Parse the event date
        guard let eventDate = parseEventDate(event.date) else { return true } // If parsing fails, show the event
        
        // Compare dates (ignore time, just compare dates)
        let todayStart = calendar.startOfDay(for: today)
        let eventStart = calendar.startOfDay(for: eventDate)
        
        return eventStart >= todayStart
    }
    
    private func parseEventDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM dd, yyyy"
        return formatter.date(from: dateString)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Saved")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.0, green: 0.2, blue: 0.4)) // Navy blue
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search saved...", text: $searchText)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                if favoriteEvents.isEmpty {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Nothing Saved Yet")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Tap the bookmark icon on events to save them")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Favorites list
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(filteredFavorites) { event in
                                EventCardView(event: event)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 1.0, green: 0.8, blue: 0.0), // UCSC Gold
                        Color(red: 0.0, green: 0.3, blue: 0.6), // UCSC Blue
                        Color.white // Pure white at bottom
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .onAppear {
            loadFavorites()
        }
        .onReceive(NotificationCenter.default.publisher(for: .favoritesChanged)) { _ in
            loadFavorites()
        }
    }
    
    private func loadFavorites() {
        // Load favorites from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "favoriteEvents"),
           let favorites = try? JSONDecoder().decode([Event].self, from: data) {
            favoriteEvents = favorites
        }
    }
}
