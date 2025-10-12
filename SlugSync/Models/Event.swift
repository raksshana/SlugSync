//
//  Event.swift
//  SlugSync
//
//  Created by Raksshana Harish Babu on 10/11/25.
//

import Foundation

// The blueprint for a single event
struct Event: Codable, Identifiable {
    let id: Int
    let title: String
    let imageName: String
    let category: String // "Sports", "Academic", etc.
    let date: String
    let time: String
    let location: String
    let clubName: String? // Optional, since not all events have one
}


