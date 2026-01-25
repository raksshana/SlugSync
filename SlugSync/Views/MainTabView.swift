//
//  MainTabView.swift
//  SlugSync
//
//  Created by Raksshana Harish Babu on 10/11/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @StateObject private var userService = UserService.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)
            
            FavoritesView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "bookmark.fill" : "bookmark")
                    Text("Saved")
                }
                .tag(1)
            
            // Only show Add Event tab if user is signed in
            if userService.currentUser != nil {
                AddEventView()
                    .tabItem {
                        Image(systemName: selectedTab == 2 ? "plus.circle.fill" : "plus.circle")
                        Text("Add Event")
                    }
                    .tag(2)
            }
        }
        .accentColor(.blue)
        .onChange(of: userService.currentUser) { newUser in
            // If user logs out while on Add Event tab, switch to Home tab
            if newUser == nil && selectedTab == 2 {
                selectedTab = 0
            }
        }
    }
}
