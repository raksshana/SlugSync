//
//  ContentView.swift
//  SlugSync
//
//  Created by Raksshana Harish Babu on 10/11/25.
//

import SwiftUI
import Foundation

extension Notification.Name {
    static let eventsUpdated = Notification.Name("eventsUpdated")
}

struct ContentView: View {
    @State private var searchText: String = ""
    @State private var selectedCategory: String = "All"
    @State private var events: [Event] = []
    @State private var isLoading: Bool = true
    @State private var showProfile: Bool = false
    @StateObject private var eventService = EventService.shared
    
    let categories = ["All", "Sports", "Academic", "Social", "Clubs"]
    
    var filteredEvents: [Event] {
        let today = Date()
        let calendar = Calendar.current
        
        // First filter by category and search
        let categoryFiltered = selectedCategory == "All" ? events : events.filter { $0.category == selectedCategory }
        let searchFiltered = searchText.isEmpty ? categoryFiltered : categoryFiltered.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        
        // Then filter out past events
        return searchFiltered.filter { event in
            return isEventInFuture(event: event, today: today, calendar: calendar)
        }
    }
    
    private func isEventInFuture(event: Event, today: Date, calendar: Calendar) -> Bool {
        // Parse the event date from ISO8601 string (starts_at)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Try ISO8601 format first
        if let eventDate = isoFormatter.date(from: event.starts_at) {
            let todayStart = calendar.startOfDay(for: today)
            let eventStart = calendar.startOfDay(for: eventDate)
            return eventStart >= todayStart
        }
        
        // Fallback: try simple format
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        if let eventDate = simpleFormatter.date(from: event.starts_at) {
            let todayStart = calendar.startOfDay(for: today)
            let eventStart = calendar.startOfDay(for: eventDate)
            return eventStart >= todayStart
        }
        
        // If parsing fails, show the event (better to show than hide)
        return true
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("UCSC")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.0, green: 0.2, blue: 0.4)) // Navy blue
                    Text("Event Tracker")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.0, green: 0.2, blue: 0.4)) // Navy blue
                    Spacer()
                    Button(action: {
                        showProfile = true
                    }) {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color(red: 0.0, green: 0.2, blue: 0.4))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search events...", text: $searchText)
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.bottom, 15)
                
                // Category Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                Text(category)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedCategory == category ? Color.blue : Color(.systemGray5))
                                    .foregroundColor(selectedCategory == category ? .white : .primary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 20)
                
                // Events List
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Loading events...")
                            .font(.headline)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(filteredEvents) { event in
                                EventCardView(event: event)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .background(Color.clear)
                }
            }
            .navigationBarHidden(true)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 1.0, green: 0.8, blue: 0.0), // UCSC Gold
                        Color(red: 0.0, green: 0.3, blue: 0.6)  // UCSC Blue
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .onAppear {
            loadEvents()
        }
        .onReceive(NotificationCenter.default.publisher(for: .eventsUpdated)) { _ in
            loadEvents()
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
    }
    
    private func loadEvents() {
        Task {
            do {
                print("🔄 Loading events...")
                let apiEvents = try await eventService.fetchEvents()
                print("📦 Received \(apiEvents.count) events from API")

                await MainActor.run {
                    // Convert API events to our Event model
                    self.events = apiEvents.map { apiEvent in
                        print("  - Event: \(apiEvent.name), ID: \(apiEvent.id), Tags: \(apiEvent.tags ?? "none")")
                        
                        return Event(
                            id: apiEvent.id, // Event model expects Int, not String
                            name: apiEvent.name,
                            location: apiEvent.location,
                            starts_at: apiEvent.starts_at,
                            ends_at: apiEvent.ends_at,
                            host: apiEvent.host,
                            description: apiEvent.description,
                            tags: apiEvent.tags, // Event model expects String? (comma-separated), not [String]
                            created_at: apiEvent.created_at
                        )
                    }
                    print("✅ Events loaded and converted. Total: \(self.events.count)")
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
                print("❌ Error loading events: \(error)")
            }
        }
    }
    
}
