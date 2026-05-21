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
    @State private var cacheManager = VideoCacheManager()
    @State private var videos: [VideoItem] = []
    @State private var activeVideoID: Int?
    @State private var currentIndex: Int = 0
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(videos.enumerated()), id: \.element.id) { index, video in
                        VideoFeedItemView(
                            video: video,
                            player: cacheManager.getPlayer(for: video),
                            isActive: video.id == activeVideoID,
                            onVideoEnded: {                                    
                                    // Find the index of the video that just finished
                                    if let currentIndex = videos.firstIndex(where: { $0.id == video.id }),
                                       currentIndex + 1 < videos.count {
                                        
                                        // Animate moving to the next item so it snaps smoothly
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            activeVideoID = videos[currentIndex + 1].id
                                        }
                                    }
                                }
                        )
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
            .onChange(of: activeVideoID) { _, newID in
                guard let newID = newID,
                      let index = videos.firstIndex(where: { $0.id == newID }) else { return }
                
                currentIndex = index
                // Lifecycle management: pauses past items, loads ahead 2 items
                cacheManager.updateLifecycle(currentIndex: currentIndex)
                UserDefaults.standard.set(newID, forKey: "last_watched_video_id")
            }
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
            
            // 🎯 RESTORE PREVIOUS STATE LOCALLY ON LAUNCH:
        if let savedID = Int(UserDefaults.standard.string(forKey: "last_watched_video_id") ?? "0") ,
               videos.contains(where: { $0.id == savedID }) {
                
                // If a valid saved video exists from their previous session, restore it
                self.activeVideoID = savedID
                if let index = videos.firstIndex(where: { $0.id == savedID }) {
                    self.currentIndex = index
                    self.cacheManager.updateLifecycle(currentIndex: index)
                }
                print("💾 Restored user session smoothly at video index: \(currentIndex)")
                
            } else if let firstVideo = response.videos.first {
                // Fall back to the very first video if no history is found
                self.activeVideoID = firstVideo.id
                self.cacheManager.updateLifecycle(currentIndex: 0)
            }
    }
}

// MARK: - Overlay

struct VideoOverlayView: View {
    
    let video: VideoItem
    let time: String
    
    // 🎯 State to track if the description text is expanded or collapsed
    @State private var isExpanded: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            HStack(alignment: .bottom) {
                // MARK: - Left Content (Metadata Stack)
                VStack(alignment: .leading, spacing: 8) {
                    // Video Title
                    Text(video.title)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    // 🎯 Expandable Description Block
                    VStack(alignment: .leading, spacing: 4) {
                        Text(video.description)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            // If expanded, remove limits. If collapsed, limit to 2 lines.
                            .lineLimit(isExpanded ? nil : 2)
                        
                        // "Show More" / "Less" Button Layer
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Text(isExpanded ? "Show Less" : "...more")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.vertical, 2)
                        }
                    }
                    .padding(.bottom, 4)
                    
                    // Dynamic Countdown Time Label Pill
                    Text(time)
                        .font(.system(.subheadline, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(.ultraThinMaterial))
                }
                .foregroundStyle(.white)
                .padding(.trailing, 24) // Keeps metadata from overlapping right action buttons
                
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
                } // VStack
            } // HStack
            .padding(.horizontal, 16)
            .padding(.bottom, UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 24)
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
