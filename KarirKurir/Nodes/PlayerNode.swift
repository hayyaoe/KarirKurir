//
//  PlayerNode.swift
//  KarirKurir
//

import SpriteKit

enum FacingDirection: String {
    case up, down, left, right
}

class PlayerNode: SKSpriteNode {
    private let moveDuration: TimeInterval = 0.18
    private var directionIndicator: SKSpriteNode!
    
    static let category: UInt32 = 0x1 << 0
    
    private var facing: FacingDirection = .right
    private var animationFrames: [FacingDirection: [SKTexture]] = [:]
    private var slowdownIndicator: SKSpriteNode?
    private var isShowingSlowdownEffect: Bool = false
    
    // Separate sprite node for visual offset
    private var visualSprite: SKSpriteNode!
    private let yOffsetAmount: CGFloat = 8.0
    
    init(tileSize: CGSize) {
        // Load textures once for default
        let defaultTexture = SKTexture(imageNamed: "courierRight1")
        let playerSize = CGSize(width: tileSize.width, height: tileSize.height)
        
        super.init(texture: nil, color: .clear, size: playerSize)
        
        // Create visual sprite as child node
        visualSprite = SKSpriteNode(texture: defaultTexture, size: playerSize)
        visualSprite.position = CGPoint.zero
        addChild(visualSprite)
        
        setupTextures()
        setupPhysics(size: playerSize)
        
        // Apply initial visual offset since player starts facing right
        applyVisualYOffset()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupTextures() {
        animationFrames[.down] = (1...4).map { SKTexture(imageNamed: "courierDown\($0)") }
        animationFrames[.up] = (1...4).map { SKTexture(imageNamed: "courierUp\($0)") }
        animationFrames[.left] = (1...4).map { SKTexture(imageNamed: "courierLeft\($0)") }
        animationFrames[.right] = (1...4).map { SKTexture(imageNamed: "courierRight\($0)") }
    }
    
    private func setupPhysics(size: CGSize) {
        physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 30, height: 30))
        physicsBody?.affectedByGravity = false
        physicsBody?.isDynamic = true
        physicsBody?.allowsRotation = false
        physicsBody?.categoryBitMask = PlayerNode.category // Player
        physicsBody?.collisionBitMask = 2 | CatObstacle.categoryBitMask | WagonObstacle.categoryBitMask// Walls + Cat + Wagon
        physicsBody?.contactTestBitMask = 2 | 4 | ItemNode.categoryBitMask | CatObstacle.categoryBitMask | WagonObstacle.categoryBitMask // Walls + Destination + Items + Obstacles
    }
    
    func move(to targetPosition: CGPoint, completion: @escaping () -> Void) {
        moveWithCustomDuration(to: targetPosition, duration: moveDuration, completion: completion)
    }
    
//    func showSlowdownEffect() {
//        print("🔴 showSlowdownEffect() called - current state: \(isShowingSlowdownEffect)")
//        
//        guard !isShowingSlowdownEffect else {
//            print("⚠️ Slowdown effect already showing, skipping")
//            return
//        }
//        
//        // Set the flag
//        isShowingSlowdownEffect = true
//        
//        // FIXED: Apply effect to main PlayerNode, not visualSprite to avoid conflicts
//        // Stop any existing slowdown animation first
//        self.removeAction(forKey: "playerSlowdownFlash")
//        
//        // Reset to normal state first
//        self.alpha = 1.0
//        
//        // Create flashing animation - apply to main PlayerNode
//        let fadeToLow = SKAction.fadeAlpha(to: 0.4, duration: 0.3)
//        let fadeToNormal = SKAction.fadeAlpha(to: 1.0, duration: 0.3)
//        let flash = SKAction.sequence([fadeToLow, fadeToNormal])
//        let repeatFlash = SKAction.repeatForever(flash)
//        
//        // Apply to main PlayerNode (self) instead of visualSprite
//        self.run(repeatFlash, withKey: "playerSlowdownFlash")
//        
//        print("✅ Player slowdown flashing effect started on main node")
//        print("🔍 Player alpha after start: \(self.alpha)")
//    }
    
    func showSlowdownEffect() {
            print("🔴 showSlowdownEffect() called - current state: \(isShowingSlowdownEffect)")
            
            guard !isShowingSlowdownEffect else {
                print("⚠️ Slowdown effect already showing, skipping")
                return
            }
            
            // Set the flag
            isShowingSlowdownEffect = true
            
            // Stop any existing slowdown animation first
            self.removeAction(forKey: "playerSlowdownFlash")
            
            // Reset to normal state first
            self.color = .clear
            self.colorBlendFactor = 0.0
            
            // Create flashing effect using color blending
            // Flash between normal appearance and darkened appearance
            let flashToDark = SKAction.group([
                SKAction.colorize(with: .black, colorBlendFactor: 0.6, duration: 0.3)
            ])
            
            let flashToNormal = SKAction.group([
                SKAction.colorize(with: .clear, colorBlendFactor: 0.0, duration: 0.3)
            ])
            
            let flash = SKAction.sequence([flashToDark, flashToNormal])
            let repeatFlash = SKAction.repeatForever(flash)
            
            // Apply to main PlayerNode
            self.run(repeatFlash, withKey: "playerSlowdownFlash")
            
            print("✅ Player slowdown COLOR FLASHING effect started")
            print("🔍 Player color: \(self.color), blendFactor: \(self.colorBlendFactor)")
        }
    
//    func hideSlowdownEffect() {
//        print("🟢 hideSlowdownEffect() called - current state: \(isShowingSlowdownEffect)")
//        
//        guard isShowingSlowdownEffect else {
//            print("⚠️ hideSlowdownEffect called but effect not showing")
//            return
//        }
//        
//        // Clear the flag
//        isShowingSlowdownEffect = false
//        
//        // Stop the animation
//        self.removeAction(forKey: "playerSlowdownFlash")
//        
//        // Force reset alpha to normal immediately
//        self.alpha = 1.0
//        
//        print("✅ Player slowdown effect hidden and reset")
//        print("🔍 Player alpha after hide: \(self.alpha)")
//    }
    
    func hideSlowdownEffect() {
            print("🟢 hideSlowdownEffect() called - current state: \(isShowingSlowdownEffect)")
            
            guard isShowingSlowdownEffect else {
                print("⚠️ hideSlowdownEffect called but effect not showing")
                return
            }
            
            // Clear the flag
            isShowingSlowdownEffect = false
            
            // Stop the animation
            self.removeAction(forKey: "playerSlowdownFlash")
            
            // Force reset color to normal immediately
            self.color = .clear
            self.colorBlendFactor = 0.0
            
            print("✅ Player slowdown COLOR FLASHING effect hidden and reset")
            print("🔍 Player color: \(self.color), blendFactor: \(self.colorBlendFactor)")
        }
    
    private var slowdownOverlay: SKSpriteNode?
        
        func showSlowdownEffectOverlay() {
            print("🔴 showSlowdownEffectOverlay() called - current state: \(isShowingSlowdownEffect)")
            
            guard !isShowingSlowdownEffect else {
                print("⚠️ Slowdown effect already showing, skipping")
                return
            }
            
            // Set the flag
            isShowingSlowdownEffect = true
            
            // Remove existing overlay if any
            slowdownOverlay?.removeFromParent()
            
            // Create a red overlay sprite
            slowdownOverlay = SKSpriteNode(color: .red, size: self.size)
            slowdownOverlay!.alpha = 0.0
            slowdownOverlay!.zPosition = 1000 // Above everything
            slowdownOverlay!.blendMode = .multiply
            self.addChild(slowdownOverlay!)
            
            // Animate the overlay
            let fadeIn = SKAction.fadeAlpha(to: 0.3, duration: 0.3)
            let fadeOut = SKAction.fadeAlpha(to: 0.0, duration: 0.3)
            let flash = SKAction.sequence([fadeIn, fadeOut])
            let repeatFlash = SKAction.repeatForever(flash)
            
            slowdownOverlay!.run(repeatFlash, withKey: "overlayFlash")
            
            print("✅ Player slowdown OVERLAY effect started")
        }
    
    func hideSlowdownEffectOverlay() {
            print("🟢 hideSlowdownEffectOverlay() called - current state: \(isShowingSlowdownEffect)")
            
            guard isShowingSlowdownEffect else {
                print("⚠️ hideSlowdownEffectOverlay called but effect not showing")
                return
            }
            
            // Clear the flag
            isShowingSlowdownEffect = false
            
            // Remove the overlay
            slowdownOverlay?.removeFromParent()
            slowdownOverlay = nil
            
            print("✅ Player slowdown OVERLAY effect hidden and reset")
        }
    
    func isShowingSlowdown() -> Bool {
        return isShowingSlowdownEffect
    }
    
    private func resetSlowdownEffect() {
        print("🔄 resetSlowdownEffect() - cleaning up all slowdown state")
        
        // Clear the flag
        isShowingSlowdownEffect = false
        
        // Stop ALL actions on visual sprite to ensure clean state
        visualSprite.removeAllActions()
        
        // Force reset opacity to normal with immediate action
        visualSprite.alpha = 1.0
        
        // Also ensure any stuck actions are cleared
        visualSprite.removeAction(forKey: "playerSlowdownFlash")
        visualSprite.removeAction(forKey: "playerFlashingEffect") // Legacy key
        
        print("🔄 Reset complete - opacity: \(visualSprite.alpha), hasActions: \(visualSprite.hasActions())")
    }
    
    func moveWithCustomDuration(to targetPosition: CGPoint, duration: TimeInterval, completion: @escaping () -> Void) {
        // Remove any existing actions from both main node and visual sprite
        removeAllActions()
        visualSprite.removeAllActions()
        
        updateDirection(to: targetPosition)
        animateWalk()
        
        // Move the main node to the exact target position (keeps collision detection correct)
        let moveAction = SKAction.move(to: targetPosition, duration: duration)
        moveAction.timingMode = .easeInEaseOut
        
        let done = SKAction.run {
            completion()
        }
        
        run(SKAction.sequence([moveAction, done]), withKey: "moveAction")
    }
    
    private func updateDirection(to target: CGPoint) {
        let dx = target.x - position.x
        let dy = target.y - position.y
        
        if abs(dx) > abs(dy) {
            facing = dx > 0 ? .right : .left
        } else {
            facing = dy > 0 ? .up : .down
        }
    }
    
    private func animateWalk() {
        guard let frames = animationFrames[facing] else { return }
        
        let frameTimePerFrame = moveDuration / Double(frames.count)
        let animation = SKAction.animate(with: frames, timePerFrame: frameTimePerFrame)
        let repeatAction = SKAction.repeatForever(animation)
        
        // Apply animation to the visual sprite
        visualSprite.run(repeatAction, withKey: "walkAnimation")
        
        // Apply visual Y offset for left/right sprites
        applyVisualYOffset()
    }
    
    func forceResetSlowdownEffect() {
            print("🚨 FORCE RESET slowdown effect")
            
            // Clear the flag
            isShowingSlowdownEffect = false
            
            // Stop all slowdown-related actions on main node
            self.removeAction(forKey: "playerSlowdownFlash")
            
            // Force reset color to normal
            self.color = .clear
            self.colorBlendFactor = 0.0
            
            print("🚨 Force reset complete - color: \(self.color), blendFactor: \(self.colorBlendFactor)")
        }
    
    private func applyVisualYOffset() {
        // Remove any existing offset animation
        visualSprite.removeAction(forKey: "visualOffset")
        
        if facing == .left || facing == .right || facing == .down || facing == .up{
            // Move visual sprite up for left/right animations
            let offsetAction = SKAction.moveTo(y: yOffsetAmount, duration: 0.0)
            visualSprite.run(offsetAction, withKey: "visualOffset")
            print("Applied visual Y offset for \(facing.rawValue)")
        } else {
            // Reset visual sprite position for up/down animations
            let resetAction = SKAction.moveTo(y: 0, duration: 0.1)
            visualSprite.run(resetAction, withKey: "visualOffset")
            print("Reset visual Y offset for \(facing.rawValue)")
        }
    }
    
    func debugSlowdownState() {
            print("🐛 PLAYER SLOWDOWN DEBUG:")
            print("   isShowingSlowdownEffect: \(isShowingSlowdownEffect)")
            print("   color: \(self.color)")
            print("   colorBlendFactor: \(self.colorBlendFactor)")
            print("   alpha: \(self.alpha)")
            print("   hasActions: \(self.hasActions())")
            
            if self.hasActions() {
                print("   ✅ Main node has actions running")
            } else {
                print("   ❌ Main node has NO actions running")
            }
        }
    
    override func removeAllActions() {
        super.removeAllActions()
        visualSprite?.removeAllActions()
    }
}
