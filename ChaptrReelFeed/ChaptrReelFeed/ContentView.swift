//
//  ContentView.swift
//  ChaptrReelFeed
//
//  Created by Arun Jangid on 21/05/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            ForYouFeedView()
        }
    }
}

#Preview {
    ContentView()
}
