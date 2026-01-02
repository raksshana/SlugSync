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
    @State private var eventDescription: String = ""
    @State private var eventStartDate: Date = Date()
    @State private var eventEndDate: Date = Date()
    @State private var eventTime: Date = Date()
    @State private var location: String = ""
    @State private var selectedCategory: String = "Academic"
    @State private var isAllDay: Bool = false
    @State private var isMultiDay: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isCreating: Bool = false
    @State private var showSuccess: Bool = false

    let categories = ["Academic", "Sports", "Social", "Clubs"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header (sticky)
                HStack {
                    Text("Add Event")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 70)
                .padding(.bottom, 15)
                .background(Color.black)
                
                ScrollView {
                    VStack(spacing: 25) {
                        VStack(spacing: 20) {
                        // Organizer/Club Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Organizer/Club Name")
                                .font(.headline)
                                .foregroundColor(.white)
                            ZStack(alignment: .leading) {
                                if organizerName.isEmpty {
                                    Text("Enter organizer or club name")
                                        .foregroundColor(.white.opacity(0.6))
                                        .padding(.horizontal, 15)
                                }
                                TextField("", text: $organizerName)
                                    .foregroundColor(.white)
                                    .padding()
                            }
                            .background(Color(red: 0.0, green: 0.2, blue: 0.4)) // Dark blue
                            .cornerRadius(10)
                        }
                        
                        // Event Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Event Name")
                                .font(.headline)
                                .foregroundColor(.white)
                            ZStack(alignment: .leading) {
                                if eventName.isEmpty {
                                    Text("Enter event name")
                                        .foregroundColor(.white.opacity(0.6))
                                        .padding(.horizontal, 15)
                                }
                                TextField("", text: $eventName)
                                    .foregroundColor(.white)
                                    .padding()
                            }
                            .background(Color(red: 0.0, green: 0.2, blue: 0.4)) // Dark blue
                            .cornerRadius(10)
                        }

                        // Event Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.white)
                            ZStack(alignment: .leading) {
                                if eventDescription.isEmpty {
                                    Text("Enter event description")
                                        .foregroundColor(.white.opacity(0.6))
                                        .padding(.horizontal, 15)
                                }
                                TextField("", text: $eventDescription)
                                    .foregroundColor(.white)
                                    .padding()
                            }
                            .background(Color(red: 0.0, green: 0.2, blue: 0.4)) // Dark blue
                            .cornerRadius(10)
                        }

                        // Location
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location")
                                .font(.headline)
                                .foregroundColor(.white)
                            ZStack(alignment: .leading) {
                                if location.isEmpty {
                                    Text("Enter event location")
                                        .foregroundColor(.white.opacity(0.6))
                                        .padding(.horizontal, 15)
                                }
                                TextField("", text: $location)
                                    .foregroundColor(.white)
                                    .padding()
                            }
                            .background(Color(red: 0.0, green: 0.2, blue: 0.4)) // Dark blue
                            .cornerRadius(10)
                        }
                        
                        // Category Selection
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.headline)
                                .foregroundColor(.white)
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
                                                            LinearGradient(
                                                                gradient: Gradient(colors: [
                                                                    Color(red: 0.3, green: 0.7, blue: 1.0), // Light blue
                                                                    Color(red: 1.0, green: 0.9, blue: 0.0)  // Bright yellow
                                                                ]),
                                                                startPoint: .leading,
                                                                endPoint: .trailing
                                                            )
                                                        } else {
                                                            Color(red: 0.0, green: 0.2, blue: 0.4) // Dark blue
                                                        }
                                                    }
                                                )
                                                .cornerRadius(20)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Multi-Day Toggle
                        HStack {
                            Text("Multi-Day Event")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Toggle("", isOn: $isMultiDay)
                                .tint(Color(red: 0.0, green: 0.2, blue: 0.4)) // Dark blue when on
                        }
                        
                        if isMultiDay {
                            // Start Date
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Start Date")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                DatePicker("Event Start Date", selection: $eventStartDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .colorScheme(.dark)
                                    .accentColor(.white)
                            }
                            
                            // End Date
                            VStack(alignment: .leading, spacing: 8) {
                                Text("End Date")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                DatePicker("Event End Date", selection: $eventEndDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .colorScheme(.dark)
                                    .accentColor(.white)
                            }
                        } else {
                            // Single Date Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Date")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                DatePicker("Event Date", selection: $eventStartDate, displayedComponents: .date)
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .colorScheme(.dark)
                                    .accentColor(.white)
                            }
                        }
                        
                        // All Day Toggle
                        HStack {
                            Text("All Day Event")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Toggle("", isOn: $isAllDay)
                                .tint(Color(red: 0.0, green: 0.2, blue: 0.4)) // Dark blue when on
                        }
                        
                        // Time Selection (only if not all day)
                        if !isAllDay {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Time")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                DatePicker("Event Time", selection: $eventTime, displayedComponents: .hourAndMinute)
                                    .datePickerStyle(CompactDatePickerStyle())
                                    .colorScheme(.dark)
                                    .accentColor(.white)
                            }
                        }
                        
                    }
                    .padding(.horizontal, 20)
                    
                    // Add Event Button
                    Button(action: {
                        createEvent()
                    }) {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Creating...")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            } else {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text("Add Event")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isCreating ? Color.gray : Color(red: 0.0, green: 0.2, blue: 0.4)) // Dark blue
                        .cornerRadius(12)
                    }
                    .disabled(isCreating)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationBarHidden(true)
            .background(Color.black)
            .ignoresSafeArea()
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
            .alert("Success!", isPresented: $showSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Event created successfully!")
            }
        }
    }
    
    private func createEvent() {
        // Validate inputs
        guard !eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter an event name"
            showError = true
            return
        }

        guard !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a location"
            showError = true
            return
        }

        // Validate dates for multi-day events
        if isMultiDay && eventEndDate < eventStartDate {
            errorMessage = "End date must be after start date"
            showError = true
            return
        }

        // Validate that event name is reasonable length
        guard eventName.count <= 120 else {
            errorMessage = "Event name must be 120 characters or less"
            showError = true
            return
        }

        // Validate location length
        guard location.count <= 160 else {
            errorMessage = "Location must be 160 characters or less"
            showError = true
            return
        }

        // Validate description length if provided
        if !eventDescription.isEmpty && eventDescription.count > 10000 {
            errorMessage = "Description must be 10,000 characters or less"
            showError = true
            return
        }

        Task {
            isCreating = true
            do {
                // Create API event - simplified for testing
                // Convert tags array to comma-separated string for backend
                let tagsString = selectedCategory.lowercased()
                
                // Always include ends_at
                let calendar = Calendar.current
                let startDateString: String
                let endDateString: String

                if isAllDay {
                    // For all-day events, set time to midnight (00:00)
                    var startComponents = calendar.dateComponents([.year, .month, .day], from: eventStartDate)
                    startComponents.hour = 0
                    startComponents.minute = 0
                    startComponents.second = 0

                    if isMultiDay {
                        // Multi-day all-day event: start at midnight, end at 23:59 of end date
                        if let startDate = calendar.date(from: startComponents) {
                            let formatter = ISO8601DateFormatter()
                            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                            startDateString = formatter.string(from: startDate)
                        } else {
                            startDateString = formatISO8601Date(eventStartDate, Date())
                        }

                        var endComponents = calendar.dateComponents([.year, .month, .day], from: eventEndDate)
                        endComponents.hour = 23
                        endComponents.minute = 59
                        endComponents.second = 59

                        if let endDate = calendar.date(from: endComponents) {
                            let formatter = ISO8601DateFormatter()
                            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                            endDateString = formatter.string(from: endDate)
                        } else {
                            endDateString = formatISO8601Date(eventEndDate, Date())
                        }
                    } else {
                        // Single-day all-day event: start at midnight, end at 23:59 same day
                        if let startDate = calendar.date(from: startComponents) {
                            let formatter = ISO8601DateFormatter()
                            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                            startDateString = formatter.string(from: startDate)

                            // End at 23:59 of the same day
                            var endComponents = startComponents
                            endComponents.hour = 23
                            endComponents.minute = 59
                            endComponents.second = 59

                            if let endDate = calendar.date(from: endComponents) {
                                endDateString = formatter.string(from: endDate)
                            } else {
                                endDateString = startDateString
                            }
                        } else {
                            startDateString = formatISO8601Date(eventStartDate, Date())
                            endDateString = startDateString
                        }
                    }
                } else {
                    // Non-all-day events: use the selected time
                    startDateString = formatISO8601Date(eventStartDate, eventTime)

                    if isMultiDay {
                        // Multi-day timed event: use same time on end date
                        endDateString = formatISO8601Date(eventEndDate, eventTime)
                    } else {
                        // Single-day timed event: add 1 hour to start time
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
                }
                
                let apiEvent = EventIn(
                    name: eventName,
                    starts_at: startDateString,
                    ends_at: endDateString, // Always include ends_at
                    location: location,
                    description: eventDescription.isEmpty ? nil : eventDescription,
                    host: organizerName.isEmpty ? "Unknown" : organizerName,
                    tags: tagsString
                )
                
                print("📤 Sending event to backend:")
                print("Name: \(apiEvent.name)")
                print("Starts at: \(apiEvent.starts_at)")
                print("Ends at: \(apiEvent.ends_at ?? "nil")")
                print("Location: \(apiEvent.location)")
                print("Host: \(apiEvent.host ?? "nil")")
                print("Tags: \(apiEvent.tags ?? "nil")")
                print("Is Multi-Day: \(isMultiDay)")
                print("Start Date: \(eventStartDate)")
                print("End Date: \(eventEndDate)")
                
                // Send to backend
                let createdEvent = try await EventService.shared.createEvent(apiEvent)
                print("Event created successfully: \(createdEvent)")

                await MainActor.run {
                    isCreating = false

                    // Clear form
                    eventName = ""
                    organizerName = ""
                    eventDescription = ""
                    location = ""
                    selectedCategory = "Academic"
                    isMultiDay = false
                    isAllDay = false
                    eventStartDate = Date()
                    eventEndDate = Date()
                    eventTime = Date()

                    // Show success message
                    showSuccess = true
                    print("✅ Event created and form cleared!")

                    // Notify other views to refresh
                    NotificationCenter.default.post(name: .eventsUpdated, object: nil)
                }

            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = getFriendlyErrorMessage(error)
                    showError = true
                }
                print("❌ Error creating event: \(error)")
            }
        }
    }

    private func getFriendlyErrorMessage(_ error: Error) -> String {
        let errorDescription = error.localizedDescription.lowercased()

        if errorDescription.contains("not authorized") || errorDescription.contains("only event hosts") {
            return "Only event hosts can create events. Please update your profile to become a host."
        } else if errorDescription.contains("network") || errorDescription.contains("internet") {
            return "No internet connection. Please check your network and try again."
        } else if errorDescription.contains("timeout") || errorDescription.contains("timed out") {
            return "The request took too long. Please try again."
        } else if errorDescription.contains("401") || errorDescription.contains("unauthorized") {
            return "You must be logged in to create events. Please log in and try again."
        } else if errorDescription.contains("500") || errorDescription.contains("server") {
            return "Server error. Please try again in a few moments."
        } else {
            return "Failed to create event. Please check your connection and try again."
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
