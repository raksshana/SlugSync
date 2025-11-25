//
//  SlugSyncApp.swift
//  SlugSync
//
//  Created by Raksshana Harish Babu on 10/11/25.
//

import SwiftUI
import GoogleSignIn

@main
struct SlugSyncApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onOpenURL { url in
                    // Handle Google Sign-In URL callback
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
