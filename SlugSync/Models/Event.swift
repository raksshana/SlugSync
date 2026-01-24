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
        let localTimeZone = TimeZone.current
        print("🌍 Local timezone detected: \(localTimeZone.identifier) (offset: \(localTimeZone.secondsFromGMT() / 3600) hours)")
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        var startDate: Date?
        if let parsed = formatter.date(from: starts_at) {
            startDate = parsed
        } else {
            // Fallback to simple string parsing
            let simpleFormatter = DateFormatter()
            simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            simpleFormatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
            startDate = simpleFormatter.date(from: starts_at)
        }

        guard let startDate = startDate else { return starts_at }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "EEEE, MMM dd, yyyy"
        displayFormatter.timeZone = localTimeZone // Convert UTC dates to local timezone

        // Always just show the start date for single-day events
        // Only show date range for multi-day events
        if let endsAt = ends_at {
            var endDate: Date?
            if let parsed = formatter.date(from: endsAt) {
                endDate = parsed
            } else {
                let simpleFormatter = DateFormatter()
                simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                simpleFormatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
                endDate = simpleFormatter.date(from: endsAt)
            }

            if let endDate = endDate {
                let calendar = Calendar.current

                // Check if start and end are on the same calendar day
                let isSameDay = calendar.isDate(startDate, inSameDayAs: endDate)

                // Debug logging
                print("📅 Event date check:")
                print("  Start: \(startDate)")
                print("  End: \(endDate)")
                print("  Same day? \(isSameDay)")

                // Only show date range for multi-day events
                if !isSameDay {
                    let startString = displayFormatter.string(from: startDate)
                    let endString = displayFormatter.string(from: endDate)
                    print("  ✅ Showing range: \(startString) - \(endString)")
                    return "\(startString) - \(endString)"
                } else {
                    print("  ✅ Same day, showing only start date")
                }
            }
        }

        // Single-day event: only show start date
        let result = displayFormatter.string(from: startDate)
        print("  📅 Final date display: \(result)")
        return result
    }
    var time: String {
        // Format starts_at time for display
        let localTimeZone = TimeZone.current
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var startDate: Date?
        if let parsed = formatter.date(from: starts_at) {
            startDate = parsed
        } else {
            // Fallback to simple string parsing
            let simpleFormatter = DateFormatter()
            simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            simpleFormatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
            startDate = simpleFormatter.date(from: starts_at)
        }
        
        guard let startDate = startDate else { return "" }
        
        // Debug logging
        print("🕐 Time formatting - UTC date: \(startDate)")
        print("🕐 Local timezone: \(localTimeZone.identifier)")
        
        // Extract time components in local timezone explicitly
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents(in: localTimeZone, from: startDate)
        let startHour = timeComponents.hour ?? 0
        let startMinute = timeComponents.minute ?? 0
        
        print("🕐 Extracted local time components: hour=\(startHour), minute=\(startMinute)")
        
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
                let endTimeComponents = calendar.dateComponents(in: localTimeZone, from: endDate)
                let endHour = endTimeComponents.hour ?? 0
                let endMinute = endTimeComponents.minute ?? 0
                
                print("🕐 End time components: hour=\(endHour), minute=\(endMinute)")
                    
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
        
        // Date objects from ISO8601 are in UTC, but Date objects themselves are timezone-agnostic
        // When we format with a DateFormatter set to local timezone, it converts correctly
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "h:mm a"
        displayFormatter.timeZone = localTimeZone // This ensures UTC dates are converted to local time
        displayFormatter.locale = Locale.current // Ensure proper AM/PM formatting
        
        print("🕐 DateFormatter timezone: \(displayFormatter.timeZone?.identifier ?? "nil")")
        print("🕐 DateFormatter locale: \(displayFormatter.locale.identifier)")
        
        // Show time range if there's an end time
        if let endsAt = ends_at {
            var endDate: Date?
            if let parsed = formatter.date(from: endsAt) {
                endDate = parsed
            } else {
                let simpleFormatter = DateFormatter()
                simpleFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                simpleFormatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC
                endDate = simpleFormatter.date(from: endsAt)
            }
            
            if let endDate = endDate {
                print("🕐 End UTC date: \(endDate)")
                // Format both dates - the DateFormatter will convert from UTC (stored) to local (displayed)
                let startTime = displayFormatter.string(from: startDate)
                let endTime = displayFormatter.string(from: endDate)
                print("🕐 Formatted time range: \(startTime) - \(endTime)")
                print("🕐 Expected: hour=\(startHour), minute=\(startMinute) should show as \(startHour > 12 ? "\(startHour - 12):\(String(format: "%02d", startMinute)) PM" : "\(startHour):\(String(format: "%02d", startMinute)) \(startHour == 0 ? "AM" : startHour < 12 ? "AM" : "PM")")")
                return "\(startTime) - \(endTime)"
            }
        }
        
        let result = displayFormatter.string(from: startDate)
        print("🕐 Formatted single time: \(result)")
        print("🕐 Expected: hour=\(startHour), minute=\(startMinute) should show as \(startHour > 12 ? "\(startHour - 12):\(String(format: "%02d", startMinute)) PM" : "\(startHour):\(String(format: "%02d", startMinute)) \(startHour == 0 ? "AM" : startHour < 12 ? "AM" : "PM")")")
        return result
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


