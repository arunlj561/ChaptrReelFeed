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
    @Environment(\.scenePhase) private var scenePhase
    
    let video: VideoItem
    let player: AVPlayer?
    var isActiveVideoId: Int
    var onVideoEnded: () -> Void
    private var isActive: Bool {
        video.id == isActiveVideoId
    }
    
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
            if isActive, let player = player {
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
            if isError {
                VStack(spacing: 16) {
                    // Warning Icon
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    // Error Messages
                    Text("Feed Unreachable")
                        .font(.headline)
                        .foregroundColor(.white)
                        
                    Text("The video couldn't stream properly. Please check your internet connection and try again.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        
                    // Tap to Retry interaction button
                    Button(action: {
                        // Flips the error switch off and forces the item to attempt connection again
                        self.isError = false
                        self.isLoading = true
                        self.handlePlayback(shouldPlay: isActive)
                    }) {
                        Text("Tap to Retry")
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .cornerRadius(20)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Dark dimmed overlay masks the thumbnail seamlessly when structural streams fail
                .background(Color.black.opacity(0.85))
                .transition(.opacity.animation(.easeInOut(duration: 0.2)))
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
        .task(id: isActiveVideoId) {
                    if isActive {
                        // The moment this ID matches, force immediate play execution
                        player?.play()
                    } else {
                        // The moment it moves off-screen, instantly pause and rewind
                        player?.pause()
                        player?.seek(to: .zero)
                        self.isPlayerReady = false
                    }
        }
        .task(id: player) {
                    guard let player = player else { return }
                    
                    // Loop and wait natively for AVPlayer to warm up its network stream
                    while isActive {
                        if player.currentItem?.status == .readyToPlay {
                            self.isLoading = false
                            self.isPlayerReady = false // Set true if you hide via opacity layout filters
                            
                            if isActive {
                                player.play() // Double-check safety play call
                            }
                            break // Stream is stable, exit monitoring loop safely
                        } else if player.currentItem?.status == .failed {
                            self.isLoading = false
                            self.isError = true
                            break
                        }
                        
                        // Sleep for 100 milliseconds before inspecting player stream frames again
                        try? await Task.sleep(for: .milliseconds(100))
                    }
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
            // Only query the player if this video item is active on screen and playing
            guard isActive, isPlayerReady, let player = player, player.rate != 0 else { return }
            
            // Extract the current render time directly from the active AVPlayer engine
            let currentTimeInSeconds = player.currentTime().seconds
            let totalDurationInSeconds = player.currentItem?.duration.seconds ?? Double(video.duration)
            
            // Safety check for streaming initialization states
            let finalDuration = totalDurationInSeconds.isNaN ? Double(video.duration) : totalDurationInSeconds
            
            // Compute the remaining seconds safely on the fly
            let remaining = max(0, Int(ceil(finalDuration - currentTimeInSeconds)))
            
            // Update the UI state
            self.secondsRemaining = remaining
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
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                // Instantly pauses video/audio if the user hits the home button or locks screen
                player?.pause()
            } else if isActive {
                // Resumes playback automatically ONLY if this specific cell is still the active one on screen
                if let player = player, player.rate == 0 && isPlayerReady {
                    player.play()
                }
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
                        DispatchQueue.main.async {
                                self.isLoading = false
                                self.isPlayerReady = true
                                
                                // 🎯 AUTOPLAY ENFORCEMENT:
                                // If this item is flagged active on launch, trigger immediate execution
                                if self.isActive {
                                    self.player?.play()
                                    
                                    // Instantly synchronize your direct heartbeat time layout properties
                                    if let player = self.player {
                                        let current = player.currentTime().seconds
                                        let duration = player.currentItem?.duration.seconds ?? Double(video.duration)
                                        let finalDuration = duration.isNaN ? Double(video.duration) : duration
                                        self.secondsRemaining = max(0, Int(ceil(finalDuration - current)))
                                    }
                                }
                            }
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
