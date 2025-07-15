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
        scene.size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        scene.scaleMode = .aspectFit
        return scene
    }

    var body: some View {
        VStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    ContentView()
}
