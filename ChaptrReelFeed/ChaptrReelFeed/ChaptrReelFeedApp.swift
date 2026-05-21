//
//  ChaptrReelFeedApp.swift
//  ChaptrReelFeed
//
//  Created by Arun Jangid on 21/05/26.
//

import SwiftUI

@main
struct ChaptrReelFeedApp: App {
    @State private var showLaunchScreen = true        
        var body: some Scene {
            WindowGroup {
                ZStack {
                    if showLaunchScreen {
                        LaunchScreenView()
                            .transition(.opacity) // Smoothly fades out when active
                    } else {
                        ForYouFeedView()
                            .transition(.asymmetric(insertion: .opacity, removal: .identity))
                    }
                }
                .onAppear {
                    // Adjust duration (e.g., 1.5 seconds) to allow JSON configurations to warm up
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            showLaunchScreen = false
                        }
                    }
                }
            }
        }
}
