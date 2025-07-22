//
//  ContentView.swift
//  KarirKurir
//
//  Created by Mahardika Putra Wardhana on 12/07/25.
//

import SpriteKit
import SwiftUI

struct ContentView: View {
    @State private var showingHighScore = false
    @StateObject var scoreManager = ScoreManager.shared

    var scene: SKScene {
        let screenBounds = UIScreen.main.bounds
        let screenSize = CGSize(width: screenBounds.width, height: screenBounds.height)
        let scene = GameScene(size: screenSize)
        scene.scaleMode = .resizeFill
        return scene
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                SpriteView(scene: scene)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
            .ignoresSafeArea(.all)
            .statusBarHidden()

//            VStack {
//                Image("logo")
//                    .padding(.top, 30)
//                Spacer()
//                Image("playButton")
//                    .padding(.bottom, 30)
//            }
        }
    }
}

#Preview {
    ContentView()
}
