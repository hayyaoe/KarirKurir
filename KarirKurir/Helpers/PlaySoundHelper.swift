//
//  playSoundIfEnabledHelper.swift
//  KarirKurir
//
//  Created by Hayya U on 17/07/25.
//
import SpriteKit

extension SKScene {
    func playSoundIfEnabled(named name: String, on node: SKNode) {
        let sfxEnabled = UserDefaults.standard.bool(forKey: "sfxEnabled")
        guard sfxEnabled else {
            return
        }

        let sound = SKAction.playSoundFileNamed(name, waitForCompletion: true)
        node.run(sound)
    }
}

