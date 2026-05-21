//
//  VideoItem.swift
//  ChaptrReelFeed
//
//  Created by Arun Jangid on 21/05/26.
//


import Foundation

struct FeedResponse: Codable {

    let videos: [VideoItem]

}

struct VideoItem: Codable, Identifiable {

    let id: Int

    let title: String

    let duration: Int

    let width: Int

    let height: Int

    let url: String

    let thumbnail: String
    
    let description: String

}
struct VideoCatalog: Decodable, Sendable {
    let videos: [VideoItem]
}
