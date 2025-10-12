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
                        Color(red: 0.0, green: 0.3, blue: 0.6), // UCSC Blue
                        Color.white // Pure white at bottom
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    private func createEvent() {
        // Format the date based on single or multi-day
        let formattedDate = formatEventDate()
        
        // Format the time based on all-day or specific time
        let formattedTime = formatEventTime()
        
        // Get appropriate image for category
        let imageName = getImageForCategory(selectedCategory)
        
        // Create the new event
        let newEvent = Event(
            id: generateEventId(), // Temporary ID until backend assigns real one
            title: eventName,
            imageName: imageName,
            category: selectedCategory,
            date: formattedDate,
            time: formattedTime,
            location: location,
            clubName: organizerName.isEmpty ? nil : organizerName
        )
        
        // TODO: Send to backend API
        // For now, just print the event
        print("Creating event: \(newEvent)")
        
        // TODO: Add success/error handling
        // TODO: Clear form after successful creation
        // TODO: Navigate back to main view
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
