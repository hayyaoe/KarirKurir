//
//  GameView.swift
//  KarirKurir
//
//  Created by Mahardika Putra Wardhana on 22/07/25.
//

import SpriteKit
import SwiftUI

struct GameView: View {
    var scene: SKScene {
        let screenBounds = UIScreen.main.bounds
        let screenSize = CGSize(width: screenBounds.width, height: screenBounds.height)
        let scene = GameScene(size: screenSize)
        scene.scaleMode = .resizeFill
        return scene
    }

    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: scene)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
        .ignoresSafeArea(.all)
        .statusBarHidden()
        .navigationBarHidden(true)
    }
}

#Preview {
    GameView()
}
