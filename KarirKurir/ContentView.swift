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
        let scene = TitleScene(size: screenSize)
        scene.scaleMode = .resizeFill
        return scene
    }

    var body: some View {
        VStack {
            GeometryReader { geometry in
                SpriteView(scene: scene)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
            .ignoresSafeArea(.all)
            .statusBarHidden()
            Button(action: {
                let randomScore = Int.random(in: 1000 ... 9999)
                GameCenterManager.shared.gameOver(withScore: randomScore)
                print("New score submitted: \(randomScore)")
            }) {
                Text("Set New High Score")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            Button(action: {
                if let rootVC = UIApplication.shared.connectedScenes
                    .compactMap({ ($0 as? UIWindowScene)?.keyWindow?.rootViewController })
                    .first
                {
                    GameCenterManager.shared.showLeaderboard(from: rootVC)
                }
            }) {
                Text("View Leaderboard")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding([.horizontal, .top])
            }

            Button(action: {
                showingHighScore = true
            }) {
                Text("Check High Score")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding([.horizontal, .bottom])
            }
        }.alert(isPresented: $showingHighScore) {
            Alert(
                title: Text("High Score"),
                message: Text("Your highest score: \(scoreManager.highScore)"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

#Preview {
    ContentView()
}
