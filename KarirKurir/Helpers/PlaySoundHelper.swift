//
//  playSoundIfEnabledHelper.swift
//  KarirKurir
//
//  Created by Hayya U on 17/07/25.
//
import SpriteKit

extension SKScene {
    func playSoundIfEnabled(named soundName: String, on node: SKNode, forceUI: Bool = false) {
        let soundEnabled = UserDefaults.standard.bool(forKey: "soundEffectsEnabled")
        
        // Always play if it's a UI sound (forceUI = true) or if sound effects are enabled
        if forceUI || soundEnabled {
            let sound = SKAction.playSoundFileNamed(soundName, waitForCompletion: false)
            node.run(sound)
        }
    }
}

