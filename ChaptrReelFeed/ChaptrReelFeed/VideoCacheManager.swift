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
        
    
    func pauseAll() {
        for player in playerPool.values {
            player.pause()
        }
    }
}
