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
    @State private var eventTime: Date
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
        if let startDate = formatter.date(from: event.starts_at) {
            _eventStartDate = State(initialValue: startDate)
            _eventTime = State(initialValue: startDate)
        } else {
            _eventStartDate = State(initialValue: Date())
            _eventTime = State(initialValue: Date())
        }

        if let endsAt = event.ends_at, let endDate = formatter.date(from: endsAt) {
            _eventEndDate = State(initialValue: endDate)
            // Check if it's multi-day
            let calendar = Calendar.current
            if let startDate = formatter.date(from: event.starts_at) {
                _isMultiDay = State(initialValue: !calendar.isDate(startDate, inSameDayAs: endDate))
            } else {
                _isMultiDay = State(initialValue: false)
            }
        } else {
            _eventEndDate = State(initialValue: Date())
            _isMultiDay = State(initialValue: false)
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    HStack {
                        Text("Edit Event")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color(red: 0.0, green: 0.2, blue: 0.4))
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

                        // Event Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                                .foregroundColor(.primary)
                            TextField("Enter event description", text: $eventDescription)
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
                        .background(Color(red: 0.0, green: 0.2, blue: 0.4))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    Spacer(minLength: 50)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 1.0, green: 0.8, blue: 0.0),
                        Color(red: 0.0, green: 0.3, blue: 0.6)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
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
        Task {
            do {
                let tagsString = selectedCategory.lowercased()

                // Format dates
                let startDateString = formatISO8601Date(eventStartDate, eventTime)
                let endDateString: String
                if isMultiDay && eventEndDate > eventStartDate {
                    endDateString = formatISO8601Date(eventEndDate, eventTime)
                } else {
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
                        let endDate = combinedStartDate.addingTimeInterval(3600)
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        endDateString = formatter.string(from: endDate)
                    } else {
                        let formatter = ISO8601DateFormatter()
                        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        if let startDate = formatter.date(from: startDateString) {
                            let endDate = startDate.addingTimeInterval(3600)
                            endDateString = formatter.string(from: endDate)
                        } else {
                            endDateString = startDateString
                        }
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
