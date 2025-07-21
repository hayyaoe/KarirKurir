//
//  HeartNode.swift
//  KarirKurir
//
//  Created by Willas Daniel Rorrong Lumban Tobing on 18/07/25.
//

import SpriteKit

class HeartNode: SKSpriteNode {
    
    static let categoryBitMask: UInt32 = 0x1 << 5
    
    init(size: CGSize) {
        super.init(texture: nil, color: .clear, size: size)
        setupVisuals()
        setupPhysics()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupVisuals() {
        // Create heart sprite - using a red heart shape
        let heartTexture = SKTexture(imageNamed: "heart") // You can replace with your heart image
        self.texture = heartTexture
        
        // If no heart image exists, create a simple heart shape
        if heartTexture.size() == CGSize.zero {
            // Create a simple heart using shapes
            let heartShape = createHeartShape()
            addChild(heartShape)
        }
        
        // Add a gentle pulsing animation
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.8)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.8)
        let pulse = SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown]))
        run(pulse)
        
//        // Add a subtle glow effect
//        let glowEffect = SKSpriteNode(color: .systemPink, size: CGSize(width: size.width * 1.2, height: size.height * 1.2))
//        glowEffect.alpha = 0.3
//        glowEffect.zPosition = -1
//        glowEffect.blendMode = .add
//        addChild(glowEffect)
        
        // Animate the glow
        let glowPulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.6),
            SKAction.fadeAlpha(to: 0.1, duration: 0.6)
        ])
//        glowEffect.run(SKAction.repeatForever(glowPulse))
    }
    
    private func createHeartShape() -> SKShapeNode {
        // Create a simple heart shape if no texture is available
        let heartPath = CGMutablePath()
        
        // Simple heart shape using curves
        let heartSize: CGFloat = size.width * 0.8
        heartPath.move(to: CGPoint(x: 0, y: -heartSize/3))
        heartPath.addQuadCurve(to: CGPoint(x: -heartSize/2, y: heartSize/4), control: CGPoint(x: -heartSize/2, y: -heartSize/6))
        heartPath.addQuadCurve(to: CGPoint(x: 0, y: heartSize/2), control: CGPoint(x: -heartSize/2, y: heartSize/2))
        heartPath.addQuadCurve(to: CGPoint(x: heartSize/2, y: heartSize/4), control: CGPoint(x: heartSize/2, y: heartSize/2))
        heartPath.addQuadCurve(to: CGPoint(x: 0, y: -heartSize/3), control: CGPoint(x: heartSize/2, y: -heartSize/6))
        
        let heartShape = SKShapeNode(path: heartPath)
        heartShape.fillColor = .systemRed
        heartShape.strokeColor = .darkGray
        heartShape.lineWidth = 2
        heartShape.glowWidth = 1
        
        return heartShape
    }
    
    private func setupPhysics() {
        self.physicsBody = SKPhysicsBody(circleOfRadius: size.width / 2)
        self.physicsBody?.isDynamic = false
        
        // Assign Physics Categories
        self.physicsBody?.categoryBitMask = HeartNode.categoryBitMask
        self.physicsBody?.collisionBitMask = 0 // Hearts don't block movement at all
        self.physicsBody?.contactTestBitMask = PlayerNode.category
    }
}
