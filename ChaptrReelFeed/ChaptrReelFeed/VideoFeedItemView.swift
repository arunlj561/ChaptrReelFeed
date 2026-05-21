//
//  VideoFeedItemView.swift
//  ChaptrReelFeed
//
//  Created by Arun Jangid on 21/05/26.
//

import AVFoundation
import AVKit
import SwiftUI
import Combine

struct VideoFeedItemView: View {
    let video: VideoItem
    let player: AVPlayer?
    var isActive: Bool
    var onVideoEnded: () -> Void
    @State private var secondsRemaining: Int = 0
        // A 1-second interval timer running on the main runloop
    @State private var countdownTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State private var isLoading = true
    @State private var isError = false
    @State private var isPlayerReady = false
    @State private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        ZStack {
            // Background: Always show the static thumbnail immediately
            AsyncImage(url: URL(string: video.thumbnail)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.black
            }
            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            .edgesIgnoringSafeArea(.all) // Keep image locked to screen borders
            .ignoresSafeArea()
            
            // Middleground: Render the video view layer only when the stream is ready
            if let player = player, isPlayerReady {
                CustomVideoPlayerView(player: player)
                    .ignoresSafeArea()
                    .transition(.opacity.animation(.linear(duration: 0.2)))
                    .onTapGesture {
                        if player.rate != 0 {
                            player.pause()
                        } else {
                            player.play()
                        }
                    }
            }
            
            // Loading Overlay (Sits perfectly over the thumbnail image)
            if isLoading && !isError {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
            
            // MARK: - Dark Overlay
            
            LinearGradient(
                colors: [
                    .clear,
                    .black.opacity(0.7)
                ],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
            Spacer()
            // The Floating Glassmorphic Timer Pill
            
            // MARK: - Overlay Content
            VideoOverlayView(video: video, time: formatTime(secondsRemaining))
        }
        .onAppear {
            // Initialize the countdown clock with the video's JSON duration
            self.secondsRemaining = video.duration
        }
        // Respond instantly when the feed scrolls to this item
        .onChange(of: isActive, initial: true) { _, newValue in
            handlePlayback(shouldPlay: newValue)
            if newValue {
                // Reset the timer cleanly if the user swipes away and comes back
                self.secondsRemaining = video.duration
            }
        }
        .onReceive(countdownTimer) { _ in
            // Only count down if this specific screen item is active and playing
            guard isActive, isPlayerReady, let player = player, player.rate != 0 else { return }
            
            if secondsRemaining > 0 {
                secondsRemaining -= 1
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { notification in
            guard let currentItem = player?.currentItem,
                  let notificationItem = notification.object as? AVPlayerItem,
                  currentItem == notificationItem else { return }
            
            // Explicitly notify the parent container view that this video is done!
            DispatchQueue.main.async {
                onVideoEnded()
            }
        }
    }
    
    private func handlePlayback(shouldPlay: Bool) {
        // Cancel any existing stream status observers
        cancellables.removeAll()
        
        guard let player = player else {
            if shouldPlay {
                isLoading = true
                isPlayerReady = false
            }
            return
        }
        
        if shouldPlay {
            isLoading = true
            // Explicitly listen to status modifications safely using Combine
            player.currentItem?.publisher(for: \.status)
                .receive(on: DispatchQueue.main)
                .sink { status in
                    switch status {
                    case .readyToPlay:
                        self.isLoading = false
                        self.isPlayerReady = true
                        player.play()
                    case .failed:
                        self.isLoading = false
                        self.isError = true
                    default:
                        break
                    }
                }
                .store(in: &cancellables)
        } else {
            player.pause()
            player.seek(to: .zero)
            self.isPlayerReady = false
            self.isLoading = false
        }
    }
    
    // 🎯 HELPER FUNCTION TO FORMAT SECONDS (e.g., 125 -> "02:05")
    private func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
}
