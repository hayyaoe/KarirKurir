//
//  PlayMusicHelper.swift
//  KarirKurir
//
//  Created by Hayya U on 22/07/25.
//

import SpriteKit
import AVFoundation

extension SKScene {
    
    func playMusicIfEnabled(named soundName: String, on node: SKNode) {
        let musicEnabled = UserDefaults.standard.bool(forKey: "musicEnabled")

        // Remove existing music node if disabled
        if !musicEnabled {
            node.childNode(withName: "backgroundMusic")?.removeFromParent()
            return
        }

        // Prevent duplicate music node
        if node.childNode(withName: "backgroundMusic") != nil {
            return
        }

        // Create and add the music node
        let musicNode = SKAudioNode(fileNamed: soundName)
        musicNode.autoplayLooped = true
        musicNode.name = "backgroundMusic"
        musicNode.isPositional = false
        node.addChild(musicNode)

        // Lower volume
        musicNode.run(SKAction.changeVolume(to: 0.2, duration: 0))

        // Workaround: Ensure music actually starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            musicNode.run(SKAction.play())
        }
    }

    
    func toggleMusic(on node: SKNode, fileName: String) {
        let current = UserDefaults.standard.bool(forKey: "musicEnabled")
        
        if current {
            playMusicIfEnabled(named: fileName, on: node)
        } else {
            if let musicNode = node.childNode(withName: "backgroundMusic") {
                musicNode.removeFromParent()
            }
        }
    }
}
