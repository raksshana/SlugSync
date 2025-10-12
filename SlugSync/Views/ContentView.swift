//
//  ContentView.swift
//  SlugSync
//
//  Created by Raksshana Harish Babu on 10/11/25.
//

import SwiftUI

struct ContentView: View {
    @State private var searchText: String = ""
    @State private var selectedCategory: String = "All"
    
    let categories = ["All", "Sports", "Academic", "Social", "Clubs"]
    
    // Mock events data
    let events: [Event] = [
        Event(id: 1, title: "SCAI Linear Regression Meeting", imageName: "book", category: "Clubs", date: "Wednesday, Oct 15, 2025", time: "3:00 PM - 4:00 PM", location: "E2-180", clubName: "SCAI"),
        Event(id: 2, title: "Midterm Study Group", imageName: "book", category: "Academic", date: "Monday, Oct 14, 2025", time: "6:00 PM - 9:00 PM", location: "McHenry Library Room 234", clubName: "CSE Tutoring"),
        Event(id: 3, title: "Club Fair 2025", imageName: "person.3", category: "Social", date: "Wednesday, Oct 16, 2025", time: "11:00 AM - 3:00 PM", location: "Quarry Plaza", clubName: "Student Life"),
        Event(id: 4, title: "Soccer Match: UCSC vs Stanford", imageName: "sportscourt", category: "Sports", date: "Friday, Oct 18, 2025", time: "2:00 PM - 4:00 PM", location: "East Field", clubName: "UCSC Athletics"),
        Event(id: 5, title: "ACM Hacks", imageName: "briefcase", category: "Academic", date: "Friday, Oct 10 - Monday, Oct 13, 2025", time: "10:00 AM - 2:00 PM", location: "Engineering 2 Building", clubName: "Association of Computing Machinery"),
        Event(id: 6, title: "Music Club Concert", imageName: "music.note", category: "Clubs", date: "Thursday, Oct 24, 2025", time: "7:30 PM - 9:30 PM", location: "Music Center Recital Hall", clubName: "UCSC Music Club")
    ]
    
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
                    Text("UCSC")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.0, green: 0.2, blue: 0.4)) // Navy blue
                    Text("Event Tracker")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(red: 0.0, green: 0.2, blue: 0.4)) // Navy blue
                    Spacer()
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
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(filteredEvents) { event in
                            EventCardView(event: event)
                        }
                    }
                    .padding(.horizontal)
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
    }
}
