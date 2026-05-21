//
//  LaunchScreenView.swift
//  ChaptrReelFeed
//
//  Created by Arun Jangid on 22/05/26.
//


import SwiftUI

struct LaunchScreenView: View {
    @State private var isActive = false
    @State private var logoOpacity = 0.0
    @State private var logoScale: CGFloat = 0.85
    
    var body: some View {
        ZStack {
            // Dark cinematic background matching the video feed
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Spacer()
                
                // Splash Emblem / Logo
                Image(systemName: "play.rectangle.on.rectangle.fill")
                    .font(.system(size: 80))
                    .symbolRenderingMode(.multicolor)
                    .foregroundStyle(.linearGradient(colors: [.white, .gray], startPoint: .top, endPoint: .bottom))
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                // Brand Typography
                Text("CHAPTR FEED")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .tracking(4) // Clean, premium tracking space
                    .foregroundColor(.white)
                    .opacity(logoOpacity)
                
                Spacer()
                
                // Subtle attribution at the bottom
                Text("MOBILE CHALLENGE")
                    .font(.caption2)
                    .tracking(2)
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.bottom, 24)
            }
        }
        .onAppear {
            // Fluid splash entrance animation sequence
            withAnimation(.easeOut(duration: 0.6)) {
                self.logoOpacity = 1.0
                self.logoScale = 1.0
            }
        }
    }
}