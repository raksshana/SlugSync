//
//  Event.swift
//  SlugSync
//
//  Created by Raksshana Harish Babu on 10/11/25.
//

import Foundation

// The blueprint for a single event - matches backend EventOut structure
struct Event: Codable, Identifiable, Hashable {
    let id: Int // Backend uses integer IDs
    let name: String // Backend field name
    let location: String
    let starts_at: String // ISO 8601 string from backend
    let ends_at: String? // Optional ISO 8601 string
    let host: String? // Backend field name
    let description: String?
    let tags: String? // Backend returns comma-separated string
    let created_at: String // ISO 8601 string from backend
    let owner_id: Int? // Owner's user ID
    
    // Computed properties for UI display
    var title: String { name }
    var clubName: String? { host }
    var category: String {
        // Determine category from tags (comma-separated string)
        let tagString = (tags ?? "").lowercased()
        if tagString.contains("sport") || tagString.contains("athletic") {
            return "Sports"
        } else if tagString.contains("academic") || tagString.contains("study") || tagString.contains("career") {
            return "Academic"
        } else if tagString.contains("social") || tagString.contains("fair") {
            return "Social"
        } else if tagString.contains("club") || tagString.contains("music") {
            return "Clubs"
        } else {
            return "Academic" // Default category
        }
    }
    var imageName: String {
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
    var date: String {
        // Format starts_at for display
        let formatter = ISO8601DateFormatter()
        guard let startDate = formatter.date(from: starts_at) else { 
            // Fallback to simple string parsing
            let simpleFormatter = DateFormatter()
            simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            guard let fallbackDate = simpleFormatter.date(from: starts_at) else { return starts_at }
            
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "EEEE, MMM dd, yyyy"
            return displayFormatter.string(from: fallbackDate)
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "EEEE, MMM dd, yyyy"
        
        if let endsAt = ends_at, let endDate = formatter.date(from: endsAt) {
            let startString = displayFormatter.string(from: startDate)
            let endString = displayFormatter.string(from: endDate)
            return "\(startString) - \(endString)"
        } else {
            return displayFormatter.string(from: startDate)
        }
    }
    var time: String {
        // Format starts_at time for display
        let formatter = ISO8601DateFormatter()
        guard let startDate = formatter.date(from: starts_at) else {
            // Fallback to simple string parsing
            let simpleFormatter = DateFormatter()
            simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            guard let fallbackDate = simpleFormatter.date(from: starts_at) else { return "" }

            // Check if this is an all-day event (midnight to 23:59)
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: fallbackDate)
            let minute = calendar.component(.minute, from: fallbackDate)

            if hour == 0 && minute == 0 {
                if let endsAt = ends_at, let endDate = simpleFormatter.date(from: endsAt) {
                    let endHour = calendar.component(.hour, from: endDate)
                    let endMinute = calendar.component(.minute, from: endDate)
                    if endHour == 23 && endMinute == 59 {
                        return "All Day"
                    }
                }
            }

            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "h:mm a"
            return displayFormatter.string(from: fallbackDate)
        }

        // Check if this is an all-day event (midnight to 23:59)
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: startDate)
        let minute = calendar.component(.minute, from: startDate)

        if hour == 0 && minute == 0 {
            if let endsAt = ends_at, let endDate = formatter.date(from: endsAt) {
                let endHour = calendar.component(.hour, from: endDate)
                let endMinute = calendar.component(.minute, from: endDate)
                if endHour == 23 && endMinute == 59 {
                    return "All Day"
                }
            }
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "h:mm a"

        if let endsAt = ends_at, let endDate = formatter.date(from: endsAt) {
            let startTime = displayFormatter.string(from: startDate)
            let endTime = displayFormatter.string(from: endDate)
            return "\(startTime) - \(endTime)"
        } else {
            return displayFormatter.string(from: startDate)
        }
    }
}

// You should also have a struct for creating events
struct EventCreate: Codable {
    let name: String
    let location: String
    let startsAt: Date
    let endsAt: Date?
    let host: String?
    let description: String?
    let tags: String?
}


