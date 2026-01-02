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
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var startDate: Date?
        if let parsed = formatter.date(from: starts_at) {
            startDate = parsed
        } else {
            // Fallback to simple string parsing
            let simpleFormatter = DateFormatter()
            simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            startDate = simpleFormatter.date(from: starts_at)
        }
        
        guard let startDate = startDate else { return starts_at }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "EEEE, MMM dd, yyyy"
        
        // Check if it's a multi-day event
        if let endsAt = ends_at {
            var endDate: Date?
            if let parsed = formatter.date(from: endsAt) {
                endDate = parsed
            } else {
                let simpleFormatter = DateFormatter()
                simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                endDate = simpleFormatter.date(from: endsAt)
            }
            
            if let endDate = endDate {
                let calendar = Calendar.current
                // Normalize both dates to start of day for comparison
                let startOfStartDay = calendar.startOfDay(for: startDate)
                let startOfEndDay = calendar.startOfDay(for: endDate)
                
                // Check if start and end are on different days
                if startOfStartDay != startOfEndDay {
                    // For display, use the actual dates (not normalized)
                    let startString = displayFormatter.string(from: startDate)
                    // For multi-day events, show the end date (not the end datetime)
                    let endString = displayFormatter.string(from: startOfEndDay)
                    return "\(startString) - \(endString)"
                }
            }
        }
        
        return displayFormatter.string(from: startDate)
    }
    var time: String {
        // Format starts_at time for display
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var startDate: Date?
        if let parsed = formatter.date(from: starts_at) {
            startDate = parsed
        } else {
            // Fallback to simple string parsing
            let simpleFormatter = DateFormatter()
            simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            startDate = simpleFormatter.date(from: starts_at)
        }
        
        guard let startDate = startDate else { return "" }
        
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: startDate)
        let startMinute = calendar.component(.minute, from: startDate)
        
        // Check if it's an all-day event (starts at or very close to midnight 00:00)
        // Allow up to 1 minute difference to account for formatting variations
        let startsAtMidnight = startHour == 0 && startMinute <= 1
        
        if startsAtMidnight {
            // Check the end time to confirm it's all day
            if let endsAt = ends_at {
                var endDate: Date?
                if let parsed = formatter.date(from: endsAt) {
                    endDate = parsed
                } else {
                    let simpleFormatter = DateFormatter()
                    simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                    endDate = simpleFormatter.date(from: endsAt)
                }
                
                if let endDate = endDate {
                    let endHour = calendar.component(.hour, from: endDate)
                    let endMinute = calendar.component(.minute, from: endDate)
                    
                    // Check if end is at end of day (23:59) or very close to it
                    let endsAtEndOfDay = (endHour == 23 && endMinute >= 58) || (endHour == 0 && endMinute <= 1)
                    
                    // Check if duration is at least 20 hours (for multi-day all-day events, this will be much longer)
                    let duration = endDate.timeIntervalSince(startDate)
                    let isFullDay = duration >= 72000 // 20 hours (allowing for multi-day events)
                    
                    if endsAtEndOfDay || isFullDay {
                        return "All Day"
                    }
                } else {
                    // No end date, but starts at midnight - assume all day
                    return "All Day"
                }
            } else {
                // Starts at midnight and no end date - assume all day
                return "All Day"
            }
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "h:mm a"
        
        // Show time range if there's an end time
        if let endsAt = ends_at {
            var endDate: Date?
            if let parsed = formatter.date(from: endsAt) {
                endDate = parsed
            } else {
                let simpleFormatter = DateFormatter()
                simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                endDate = simpleFormatter.date(from: endsAt)
            }
            
            if let endDate = endDate {
                let startTime = displayFormatter.string(from: startDate)
                let endTime = displayFormatter.string(from: endDate)
                return "\(startTime) - \(endTime)"
            }
        }
        
        return displayFormatter.string(from: startDate)
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


