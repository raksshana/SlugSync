//
//  AddEventView.swift
//  SlugSync
//
//  Created by Raksshana Harish Babu on 10/11/25.
//

import SwiftUI

struct AddEventView: View {
    @State private var eventName: String = ""
    @State private var organizerName: String = ""
    @State private var eventStartDate: Date = Date()
    @State private var eventEndDate: Date = Date()
    @State private var eventTime: Date = Date()
    @State private var location: String = ""
    @State private var selectedCategory: String = "Academic"
    @State private var isAllDay: Bool = false
    @State private var isMultiDay: Bool = false
    
    let categories = ["Academic", "Sports", "Social", "Clubs"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    HStack {
                        Text("Add Event")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.0, green: 0.2, blue: 0.4)) // Navy blue
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        // Organizer/Club Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Organizer/Club Name")
                                .font(.headline)
                                .foregroundColor(.primary)
                            TextField("Enter organizer or club name", text: $organizerName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Event Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Event Name")
                                .font(.headline)
                                .foregroundColor(.primary)
                            TextField("Enter event name", text: $eventName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Location
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location")
                                .font(.headline)
                                .foregroundColor(.primary)
                            TextField("Enter event location", text: $location)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Category Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Picker("Category", selection: $selectedCategory) {
                                ForEach(categories, id: \.self) { category in
                                    Text(category).tag(category)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        // Multi-Day Toggle
                        Toggle("Multi-Day Event", isOn: $isMultiDay)
                            .font(.headline)
                        
                        if isMultiDay {
                            // Start Date
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Start Date")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                DatePicker("Event Start Date", selection: $eventStartDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                            }
                            
                            // End Date
                            VStack(alignment: .leading, spacing: 8) {
                                Text("End Date")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                DatePicker("Event End Date", selection: $eventEndDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                            }
                        } else {
                            // Single Date Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Date")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                DatePicker("Event Date", selection: $eventStartDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                            }
                        }
                        
                        // All Day Toggle
                        Toggle("All Day Event", isOn: $isAllDay)
                            .font(.headline)
                        
                        // Time Selection (only if not all day)
                        if !isAllDay {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Time")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                DatePicker("Event Time", selection: $eventTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(CompactDatePickerStyle())
                            }
                        }
                        
                    }
                    .padding(.horizontal)
                    
                    // Add Event Button
                    Button(action: {
                        createEvent()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Add Event")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(red: 0.0, green: 0.2, blue: 0.4)) // Navy blue
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    Spacer(minLength: 50)
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
    }
    
    private func createEvent() {
        Task {
            do {
                // Create API event - simplified for testing
                // Convert tags array to comma-separated string for backend
                let tagsString = selectedCategory.lowercased()
                
                // Always include ends_at - if not provided, use starts_at + 1 hour
                let startDateString = formatISO8601Date(eventStartDate, eventTime)
                let endDateString: String
                if isMultiDay && eventEndDate > eventStartDate {
                    endDateString = formatISO8601Date(eventEndDate, eventTime)
                } else {
                    // If not multi-day, set ends_at to starts_at + 1 hour
                    // Create the combined start date/time, then add 1 hour
                    let calendar = Calendar.current
                    let dateComponents = calendar.dateComponents([.year, .month, .day], from: eventStartDate)
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: eventTime)
                    var combinedComponents = DateComponents()
                    combinedComponents.year = dateComponents.year
                    combinedComponents.month = dateComponents.month
                    combinedComponents.day = dateComponents.day
                    combinedComponents.hour = timeComponents.hour
                    combinedComponents.minute = timeComponents.minute
                    if let combinedStartDate = calendar.date(from: combinedComponents) {
                        let endDate = combinedStartDate.addingTimeInterval(3600) // Add 1 hour
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        endDateString = formatter.string(from: endDate)
                    } else {
                        // Fallback: parse start date and add 1 hour
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        if let startDate = formatter.date(from: startDateString) {
                            let endDate = startDate.addingTimeInterval(3600)
                            endDateString = formatter.string(from: endDate)
                        } else {
                            endDateString = startDateString // Last resort
                        }
                    }
                }
                
                let apiEvent = EventIn(
                    name: eventName,
                    starts_at: startDateString,
                    ends_at: endDateString, // Always include ends_at
                    location: location,
                    description: "Test event from iOS app",
                    host: organizerName.isEmpty ? "Unknown" : organizerName,
                    tags: tagsString
                )
                
                print("📤 Sending event to backend:")
                print("Name: \(apiEvent.name)")
                print("Starts at: \(apiEvent.starts_at)")
                print("Ends at: \(apiEvent.ends_at)")
                print("Location: \(apiEvent.location)")
                print("Host: \(apiEvent.host ?? "nil")")
                print("Tags: \(apiEvent.tags ?? "nil")")
                print("Is Multi-Day: \(isMultiDay)")
                print("Start Date: \(eventStartDate)")
                print("End Date: \(eventEndDate)")
                
                // Send to backend
                let createdEvent = try await EventService.shared.createEvent(apiEvent)
                print("Event created successfully: \(createdEvent)")
                
                // Clear form
                eventName = ""
                organizerName = ""
                location = ""
                selectedCategory = "Academic"
                isMultiDay = false
                isAllDay = false
                eventStartDate = Date()
                eventEndDate = Date()
                eventTime = Date()
                
                // Show success message
                print("✅ Event created and form cleared!")
                
                // Notify other views to refresh
                NotificationCenter.default.post(name: .eventsUpdated, object: nil)
                
            } catch {
                print("Error creating event: \(error)")
                // TODO: Show error message
            }
        }
    }
    
    private func formatISO8601Date(_ date: Date, _ time: Date) -> String {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        
        let combinedDate = calendar.date(from: combinedComponents) ?? date
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: combinedDate)
    }
    
    private func formatEventDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM dd, yyyy"
        
        if isMultiDay {
            let startDateString = formatter.string(from: eventStartDate)
            let endDateString = formatter.string(from: eventEndDate)
            return "\(startDateString) - \(endDateString)"
        } else {
            return formatter.string(from: eventStartDate)
        }
    }
    
    private func formatEventTime() -> String {
        if isAllDay {
            return "All Day"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            return formatter.string(from: eventTime)
        }
    }
    
    private func getImageForCategory(_ category: String) -> String {
        switch category {
        case "Sports":
            return "sportscourt"
        case "Academic":
            return "book"
        case "Social":
            return "person.3"
        case "Clubs":
            return "music.note"
        default:
            return "calendar"
        }
    }
    
    private func generateEventId() -> Int {
        // Temporary ID generation until backend integration
        return Int.random(in: 1000...9999)
    }
}
