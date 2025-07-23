//
//  ButtonAnimationHelper.swift
//  KarirKurir
//
//  Created by Hayya U on 22/07/25.
//

import SpriteKit

extension SKScene {
    func animatePress(on node: SKNode) {
        let pressAction = SKAction.scale(to: 0.9, duration: 0.05)
        (node.name != nil ? node : node.parent)?.run(pressAction)
    }
    
    func resetScale(on node: SKNode) {
        let resetAction = SKAction.scale(to: 1.0, duration: 0.05)
        (node.name != nil ? node : node.parent)?.run(resetAction)
    }
}
