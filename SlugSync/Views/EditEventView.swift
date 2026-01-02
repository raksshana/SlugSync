//
//  EditEventView.swift
//  SlugSync
//
//  Created for editing existing events
//

import SwiftUI

struct EditEventView: View {
    let event: Event
    @Environment(\.presentationMode) var presentationMode

    @State private var eventName: String
    @State private var organizerName: String
    @State private var eventDescription: String
    @State private var eventStartDate: Date
    @State private var eventEndDate: Date
    @State private var eventStartTime: Date
    @State private var eventEndTime: Date
    @State private var location: String
    @State private var selectedCategory: String
    @State private var isAllDay: Bool = false
    @State private var isMultiDay: Bool = false
    @State private var showSuccessAlert: Bool = false
    @State private var showErrorAlert: Bool = false
    @State private var errorMessage: String = ""

    let categories = ["Academic", "Sports", "Social", "Clubs"]

    init(event: Event) {
        self.event = event

        // Initialize state from event
        _eventName = State(initialValue: event.name)
        _organizerName = State(initialValue: event.host ?? "")
        _eventDescription = State(initialValue: event.description ?? "")
        _location = State(initialValue: event.location)
        _selectedCategory = State(initialValue: event.category)

        // Parse dates from ISO 8601 strings
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Try parsing with fractional seconds first, then without
        var startDate: Date?
        if let parsed = formatter.date(from: event.starts_at) {
            startDate = parsed
        } else {
            // Try without fractional seconds
            let simpleFormatter = ISO8601DateFormatter()
            simpleFormatter.formatOptions = [.withInternetDateTime]
            startDate = simpleFormatter.date(from: event.starts_at)
        }
        
        if let startDate = startDate {
            _eventStartDate = State(initialValue: startDate)
            _eventStartTime = State(initialValue: startDate)
            
            // Check if it's an all-day event (time is midnight)
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: startDate)
            let minute = calendar.component(.minute, from: startDate)
            _isAllDay = State(initialValue: hour == 0 && minute == 0)
        } else {
            _eventStartDate = State(initialValue: Date())
            _eventStartTime = State(initialValue: Date())
            _isAllDay = State(initialValue: false)
        }

        // Parse end date
        var endDate: Date?
        if let endsAt = event.ends_at {
            if let parsed = formatter.date(from: endsAt) {
                endDate = parsed
            } else {
                // Try without fractional seconds
                let simpleFormatter = ISO8601DateFormatter()
                simpleFormatter.formatOptions = [.withInternetDateTime]
                endDate = simpleFormatter.date(from: endsAt)
            }
        }
        
        if let endDate = endDate, let startDate = startDate {
            _eventEndDate = State(initialValue: endDate)
            _eventEndTime = State(initialValue: endDate)
            // Check if it's multi-day
            let calendar = Calendar.current
            _isMultiDay = State(initialValue: !calendar.isDate(startDate, inSameDayAs: endDate))
        } else if let startDate = startDate {
            // If no end date, set it to 1 hour after start
            let endTime = startDate.addingTimeInterval(3600)
            _eventEndDate = State(initialValue: startDate)
            _eventEndTime = State(initialValue: endTime)
            _isMultiDay = State(initialValue: false)
        } else {
            let defaultEndTime = Date().addingTimeInterval(3600)
            _eventEndDate = State(initialValue: Date())
            _eventEndTime = State(initialValue: defaultEndTime)
            _isMultiDay = State(initialValue: false)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header (sticky)
                HStack {
                    Text("Edit Event")
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
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Time")
                                        .font(.headline)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    HStack {
                                        Text("Start Time")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Spacer()
                                        DatePicker("", selection: $eventStartTime, displayedComponents: .hourAndMinute)
                                            .datePickerStyle(CompactDatePickerStyle())
                                            .colorScheme(.dark)
                                            .accentColor(.white)
                                    }
                                    
                                    HStack {
                                        Text("End Time")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Spacer()
                                        DatePicker("", selection: $eventEndTime, displayedComponents: .hourAndMinute)
                                            .datePickerStyle(CompactDatePickerStyle())
                                            .colorScheme(.dark)
                                            .accentColor(.white)
                                    }
                                }
                            }

                        }
                        .padding(.horizontal, 20)

                        // Update Event Button
                        Button(action: {
                            updateEvent()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                Text("Update Event")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.0, green: 0.2, blue: 0.4)) // Dark blue
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white)
            )
            .background(Color.black)
            .ignoresSafeArea()
            .alert("Success", isPresented: $showSuccessAlert) {
                Button("OK") {
                    presentationMode.wrappedValue.dismiss()
                }
            } message: {
                Text("Event updated successfully!")
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func updateEvent() {
        // Validate inputs
        guard !eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter an event name"
            showErrorAlert = true
            return
        }

        guard !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a location"
            showErrorAlert = true
            return
        }

        // Validate dates for multi-day events
        if isMultiDay && eventEndDate < eventStartDate {
            errorMessage = "End date must be after start date"
            showErrorAlert = true
            return
        }

        // Validate times for single-day events
        if !isMultiDay && !isAllDay && eventEndTime <= eventStartTime {
            errorMessage = "End time must be after start time for single-day events"
            showErrorAlert = true
            return
        }

        // Validate field lengths
        guard eventName.count <= 120 else {
            errorMessage = "Event name must be 120 characters or less"
            showErrorAlert = true
            return
        }

        guard location.count <= 160 else {
            errorMessage = "Location must be 160 characters or less"
            showErrorAlert = true
            return
        }

        if !eventDescription.isEmpty && eventDescription.count > 10000 {
            errorMessage = "Description must be 10,000 characters or less"
            showErrorAlert = true
            return
        }

        Task {
            do {
                let tagsString = selectedCategory.lowercased()

                // Format dates - handle all-day events properly
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
                    // Non-all-day events: use the selected start and end times
                    startDateString = formatISO8601Date(eventStartDate, eventStartTime)

                    if isMultiDay {
                        // Multi-day timed event: use start time on start date, end time on end date
                        endDateString = formatISO8601Date(eventEndDate, eventEndTime)
                    } else {
                        // Single-day timed event: use start time on start date, end time on same date
                        endDateString = formatISO8601Date(eventStartDate, eventEndTime)
                    }
                }

                let apiEvent = EventIn(
                    name: eventName,
                    starts_at: startDateString,
                    ends_at: endDateString,
                    location: location,
                    description: eventDescription.isEmpty ? nil : eventDescription,
                    host: organizerName.isEmpty ? "Unknown" : organizerName,
                    tags: tagsString
                )

                print("📤 Updating event \(event.id):")
                print("Name: \(apiEvent.name)")
                print("Starts at: \(apiEvent.starts_at)")
                print("Ends at: \(apiEvent.ends_at ?? "nil")")

                let updatedEvent = try await EventService.shared.updateEvent(id: event.id, event: apiEvent)
                print("✅ Event updated successfully: \(updatedEvent)")

                // Notify other views to refresh
                NotificationCenter.default.post(name: .eventsUpdated, object: nil)

                // Show success alert
                await MainActor.run {
                    showSuccessAlert = true
                }

            } catch {
                print("❌ Error updating event: \(error)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
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
}
