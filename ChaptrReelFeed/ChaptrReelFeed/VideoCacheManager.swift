//
//  VideoCacheManager.swift
//  ChaptrReelFeed
//
//  Created by Arun Jangid on 21/05/26.
//

import SwiftUI
import AVFoundation
import AVKit

@Observable
class VideoCacheManager {
    // Map of video ID to AVPlayer
    private var playerPool: [Int: AVPlayer] = [:]
    private var videoList: [VideoItem] = []
    
    // Tracks active preloading tasks so we can cancel them if the user swipes away rapidly
    private var preloadingTasks: [Int: Task<Void, Never>] = [:]
    
    func setVideos(_ videos: [VideoItem]) {
        self.videoList = videos
    }
    
    func getPlayer(for video: VideoItem) -> AVPlayer? {
        if let player = playerPool[video.id] {
            return player
        }
        
        // Lazy initialize player if missing
        guard let url = URL(string: video.url) else { return nil }
        let player = AVPlayer(url: url)
        player.automaticallyWaitsToMinimizeStalling = true
        playerPool[video.id] = player
        return player
    }
    
    /// Preloads and purges players based on the current index to protect system memory
    func updateLifecycle(currentIndex: Int) {
        let preloadAhead = 2
        let keepBehind = 1
        let validRange = (currentIndex - keepBehind)...(currentIndex + preloadAhead)
        
        // 1. Preload upcoming videos using iOS 16+ async/await
        for index in currentIndex...(currentIndex + preloadAhead) {
            guard index >= 0 && index < videoList.count else { continue }
            let video = videoList[index]
            
            // Only start a task if the player isn't already created and isn't currently loading
            if playerPool[video.id] == nil && preloadingTasks[video.id] == nil, let url = URL(string: video.url) {
                
                // Spawn a modern, cooperative asynchronous Task
                preloadingTasks[video.id] = Task(priority: .userInitiated) {
                    let asset = AVURLAsset(url: url)
                    
                    do {
                        // Modern iOS 16+ API replacement for loadValuesAsynchronously
                        let (isPlayable, _) = try await asset.load(.isPlayable, .duration)
                        
                        // Check if the task was cancelled mid-flight during a rapid user swipe
                        guard !Task.isCancelled else { return }
                        
                        if isPlayable {
                            let playerItem = AVPlayerItem(asset: asset)
                            let player = AVPlayer(playerItem: playerItem)
                            player.automaticallyWaitsToMinimizeStalling = true
                            
                            // Safely jump back to the Main Actor to mutate the UI-bound player pool
                            _ = await MainActor.run {
                                self.playerPool[video.id] = player
                                self.preloadingTasks.removeValue(forKey: video.id)
                            }
                        }
                    } catch {
                        print("❌ Failed to load asset asynchronously for video \(video.id): \(error)")
                        _ = await MainActor.run {
                            self.preloadingTasks.removeValue(forKey: video.id)
                        }
                    }
                }
            }
        }
        
        
        // 2. Map IDs directly to their current list positions in O(N) once per lifecycle step,
        // making the inner lookup loop O(1) constant-time instead of O(N) linear-time.
        let indexMap = Dictionary(uniqueKeysWithValues: videoList.enumerated().map { ($0.element.id, $0.offset) })
        
        // 3. Strict Purging of out-of-range players & tasks
        for oldId in Array(playerPool.keys) {
            // Fast dictionary lookup instead of running a slow loop search over the growing array
            if let targetIndex = indexMap[oldId] {
                if !validRange.contains(targetIndex) {
                    // Cancel any active network task still loading the video metadata
                    preloadingTasks[oldId]?.cancel()
                    preloadingTasks.removeValue(forKey: oldId)
                    
                    // Kill the active player to drop the memory ceiling down immediately
                    playerPool[oldId]?.pause()
                    playerPool[oldId] = nil
                    print("♻️ Memory Purged successfully for out-of-bounds video asset: \(oldId)")
                }
            } else {
                // Safety catch: if an ID is no longer present in the dataset, clean its memory immediately
                preloadingTasks[oldId]?.cancel()
                preloadingTasks.removeValue(forKey: oldId)
                playerPool[oldId]?.pause()
                playerPool[oldId] = nil
            }
        }
    }
    
    func pauseAll() {
        for player in playerPool.values {
            player.pause()
        }
    }
}
