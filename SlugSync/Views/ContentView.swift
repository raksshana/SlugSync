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
    @State private var showDateFilter: Bool = false
    @State private var filterStartDate: Date = Date()
    @State private var filterEndDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var isDateFilterActive: Bool = false
    @StateObject private var eventService = EventService.shared

    let categories = ["All", "Sports", "Academic", "Social", "Clubs"]
    
    var filteredEvents: [Event] {
        let today = Date()
        let calendar = Calendar.current
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // First filter by category and search
        let categoryFiltered = selectedCategory == "All" ? events : events.filter { $0.category == selectedCategory }
        let searchFiltered = searchText.isEmpty ? categoryFiltered : categoryFiltered.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            $0.location.localizedCaseInsensitiveContains(searchText)
        }

        // Then filter out past events
        let futureEvents = searchFiltered.filter { event in
            return isEventInFuture(event: event, today: today, calendar: calendar)
        }

        // Apply date range filter if active
        let dateFiltered: [Event]
        if isDateFilterActive {
            print("📅 Date filter active: \(filterStartDate) to \(filterEndDate)")
            dateFiltered = futureEvents.filter { event in
                // Try to parse the event date
                var eventDate: Date?

                // Try ISO8601 with fractional seconds first
                eventDate = formatter.date(from: event.starts_at)

                // Fallback to simple format if needed
                if eventDate == nil {
                    let simpleFormatter = DateFormatter()
                    simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                    eventDate = simpleFormatter.date(from: event.starts_at)
                }

                guard let parsedDate = eventDate else {
                    print("⚠️ Failed to parse date for event: \(event.name), date string: \(event.starts_at)")
                    return false  // Don't include events with unparseable dates
                }

                // Normalize dates to start of day for comparison
                let eventStartOfDay = calendar.startOfDay(for: parsedDate)
                let filterStartOfDay = calendar.startOfDay(for: filterStartDate)
                let filterEndOfDay = calendar.startOfDay(for: filterEndDate)

                // Event is in range if its date is >= start date and <= end date
                let isInRange = eventStartOfDay >= filterStartOfDay && eventStartOfDay <= filterEndOfDay

                if !isInRange {
                    print("🚫 Event '\(event.name)' filtered out - event date: \(eventStartOfDay), range: \(filterStartOfDay) to \(filterEndOfDay)")
                } else {
                    print("✅ Event '\(event.name)' included - event date: \(eventStartOfDay), range: \(filterStartOfDay) to \(filterEndOfDay)")
                }

                return isInRange
            }
            print("📊 Events after date filtering: \(dateFiltered.count) out of \(futureEvents.count)")
        } else {
            dateFiltered = futureEvents
        }

        // Sort by start date - soonest first
        return dateFiltered.sorted { event1, event2 in
            var date1: Date?
            var date2: Date?

            // Parse date1
            date1 = formatter.date(from: event1.starts_at)
            if date1 == nil {
                let simpleFormatter = DateFormatter()
                simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                date1 = simpleFormatter.date(from: event1.starts_at)
            }

            // Parse date2
            date2 = formatter.date(from: event2.starts_at)
            if date2 == nil {
                let simpleFormatter = DateFormatter()
                simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                date2 = simpleFormatter.date(from: event2.starts_at)
            }

            guard let parsedDate1 = date1, let parsedDate2 = date2 else {
                return false
            }
            return parsedDate1 < parsedDate2
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
                HStack(alignment: .center) {
                    Text("SlugSync")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: {
                        showProfile = true
                    }) {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
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
                            Text("Search events...")
                                .foregroundColor(.gray)
                        }
                        TextField("", text: $searchText)
                            .foregroundColor(.primary)
                    }
                    
                    // Date filter toggle button
                    Button(action: {
                        showDateFilter.toggle()
                    }) {
                        Image(systemName: isDateFilterActive ? "calendar.badge.clock" : "calendar")
                            .foregroundColor(isDateFilterActive ? .blue : .gray)
                            .padding(.leading, 8)
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

                // Date Filter Panel
                if showDateFilter {
                    VStack(spacing: 12) {
                        HStack {
                            Text("Filter by Date Range")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                        }

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("From")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                DatePicker("", selection: $filterStartDate, displayedComponents: .date)
                                    .labelsHidden()
                            }

                            Spacer()

                            VStack(alignment: .leading, spacing: 4) {
                                Text("To")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                DatePicker("", selection: $filterEndDate, displayedComponents: .date)
                                    .labelsHidden()
                            }
                        }

                        HStack(spacing: 12) {
                            Button(action: {
                                isDateFilterActive = true
                                showDateFilter = false
                            }) {
                                Text("Apply Filter")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                            }

                            if isDateFilterActive {
                                Button(action: {
                                    isDateFilterActive = false
                                    showDateFilter = false
                                }) {
                                    Text("Clear")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom, 15)
                }
                
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
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Group {
                                            if selectedCategory == category {
                                                Color(red: 0.3, green: 0.7, blue: 1.0) // Light blue
                                            } else {
                                                Color(red: 0.0, green: 0.2, blue: 0.4) // Dark blue
                                            }
                                        }
                                    )
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 15)
                
                // Events List
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView("Loading events...")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        let columns = [
                            GridItem(.flexible(), spacing: 10),
                            GridItem(.flexible(), spacing: 10)
                        ]
                        
                        LazyVGrid(columns: columns, spacing: 15) {
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
            .background(Color.black)
            .ignoresSafeArea()
        }
        .onAppear {
            loadEvents()
        }
        .onReceive(NotificationCenter.default.publisher(for: .eventsUpdated)) { _ in
            print("🔔 Received eventsUpdated notification - refreshing events...")
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
                            created_at: apiEvent.created_at,
                            owner_id: apiEvent.owner_id
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
