//
//  ContentView.swift
//  KarirKurir
//
//  Created by Mahardika Putra Wardhana on 12/07/25.
//

import SpriteKit
import SwiftUI

struct ContentView: View {
    var scene: SKScene {
        let scene = GameScene()
        
        let screenBounds = UIScreen.main.bounds
        let screenSize = CGSize(width: screenBounds.width, height: screenBounds.height)
        scene.size = screenSize
        scene.scaleMode = .resizeFill
        return scene
    }

    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: scene)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
        .ignoresSafeArea(.all) // Changed to ignore all safe areas
        .statusBarHidden() // Hide status bar for full screen experience
    }
}

#Preview {
    ContentView()
}
