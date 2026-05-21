//
//  ForYouFeedView.swift
//  ChaptrReelFeed
//
//  Created by Arun Jangid on 21/05/26.
//


import SwiftUI
import AVKit
import AVFoundation

// MARK: - ForYouFeedView
struct ForYouFeedView: View {
    
    @State private var videos: [VideoItem] = []
    @State private var activeVideoID: Int?
    @State private var currentIndex: Int = 0
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(videos.enumerated()), id: \.element.id) { index, video in
                        
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                        .id(video.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging) // Forces snapping to full screen
            .scrollPosition(id: $activeVideoID)
            .scrollClipDisabled()
            .ignoresSafeArea()
            .background(Color.black)            
            .onAppear {
                loadJSONData()
            }
            // Requirements: Pause properly when app moves to background
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                cacheManager.pauseAll()
            }
            
        }
    }
    
    private func loadJSONData() {
        guard let url = Bundle.main.url(forResource: "for-you", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let response = try? JSONDecoder().decode(FeedResponse.self, from: data) else {
            return
        }
        self.videos = response.videos
        self.cacheManager.setVideos(response.videos)
        
        if let firstVideo = response.videos.first {
            self.activeVideoID = firstVideo.id
            self.cacheManager.updateLifecycle(currentIndex: 0)
        }
    }
}

// MARK: - Overlay

struct VideoOverlayView: View {
    
    let video: VideoItem
    
    var body: some View {        
        VStack {
            Spacer()
            HStack(alignment: .bottom) {
                // MARK: - Left Content
                VStack(alignment: .leading,
                       spacing: 12){
                    Text(video.title)
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("\(video.duration)s")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        }// VStack
                       .foregroundStyle(.white)
                Spacer()
                
                // MARK: - Right Actions
                VStack(spacing: 24) {
                    ActionButton(
                        icon: "heart.fill",
                        title: "12.4K"
                    )
                    ActionButton(
                        icon: "message.fill",
                        title: "542"
                    )
                    ActionButton(
                        icon: "arrowshape.turn.up.right.fill",
                        title: "Share"
                    )
                } // Vstack
            }// Hstack
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    
    let icon: String
    let title: String
    var body: some View {
        VStack(spacing: 8) {
            Button {
            } label: {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
            }
            Text(title)
                .font(.caption)
                .foregroundStyle(.white)
        }
    }
}

// MARK: - Preview

#Preview {
    ForYouFeedView()
}
