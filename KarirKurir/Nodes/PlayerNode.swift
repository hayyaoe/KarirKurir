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
            
            // ALWAYS reset completely first, even if already showing
            // This fixes the "sometimes doesn't work" issue
            forceResetSlowdownEffectInternal()
            
            // Set the flag
            isShowingSlowdownEffect = true
            
            // Create flashing animation with more reliable timing
            let fadeToLow = SKAction.fadeAlpha(to: 0.4, duration: 0.25)    // Slightly faster
            let fadeToNormal = SKAction.fadeAlpha(to: 1.0, duration: 0.25) // Slightly faster
            fadeToLow.timingMode = .easeInEaseOut
            fadeToNormal.timingMode = .easeInEaseOut
            
            let flash = SKAction.sequence([fadeToLow, fadeToNormal])
            let repeatFlash = SKAction.repeatForever(flash)
            
            // Apply to main PlayerNode with a unique key
            self.run(repeatFlash, withKey: "playerSlowdownAlphaFlash")
            
            // Double-check that the animation actually started
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self = self else { return }
                if self.isShowingSlowdownEffect && !self.hasActions() {
                    print("⚠️ Animation failed to start, retrying...")
                    self.retrySlowdownAnimation()
                }
            }
            
            print("✅ Player slowdown ALPHA flashing effect started")
            print("🔍 Player alpha: \(self.alpha), hasActions: \(self.hasActions())")
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
            
            // Force complete reset
            forceResetSlowdownEffectInternal()
            
            print("✅ Player slowdown effect hidden and reset")
            print("🔍 Player alpha: \(self.alpha)")
        }
    
    private func forceResetSlowdownEffectInternal() {
            print("🔄 forceResetSlowdownEffectInternal() - complete cleanup")
            
            // Clear the flag
            isShowingSlowdownEffect = false
            
            // Stop ALL actions on main node (but preserve walking animations on visualSprite)
            self.removeAction(forKey: "playerSlowdownAlphaFlash")
            self.removeAllActions() // Nuclear option - remove all actions from main node
            
            // Force reset alpha to normal with immediate action
            let resetAlpha = SKAction.fadeAlpha(to: 1.0, duration: 0.0) // Instant reset
            self.run(resetAlpha)
            
            // Also manually set alpha as backup
            self.alpha = 1.0
            
            print("🔄 Reset complete - alpha: \(self.alpha), hasActions: \(self.hasActions())")
        }
    
    private func retrySlowdownAnimation() {
            print("🔄 retrySlowdownAnimation() - attempting to restart failed animation")
            
            guard isShowingSlowdownEffect else { return }
            
            // Clear any stuck state
            self.removeAction(forKey: "playerSlowdownAlphaFlash")
            self.alpha = 1.0
            
            // Try starting the animation again
            let fadeToLow = SKAction.fadeAlpha(to: 0.4, duration: 0.25)
            let fadeToNormal = SKAction.fadeAlpha(to: 1.0, duration: 0.25)
            let flash = SKAction.sequence([fadeToLow, fadeToNormal])
            let repeatFlash = SKAction.repeatForever(flash)
            
            self.run(repeatFlash, withKey: "playerSlowdownAlphaFlash")
            
            print("🔄 Retry complete - hasActions: \(self.hasActions())")
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
    
    func forceResetSlowdownEffect() {
            print("🚨 PUBLIC FORCE RESET slowdown effect")
            forceResetSlowdownEffectInternal()
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
    
//    func forceResetSlowdownEffect() {
//            print("🚨 FORCE RESET slowdown effect")
//            
//            // Clear the flag
//            isShowingSlowdownEffect = false
//            
//            // Stop all slowdown-related actions on main node
//            self.removeAction(forKey: "playerSlowdownFlash")
//            
//            // Force reset color to normal
//            self.color = .clear
//            self.colorBlendFactor = 0.0
//            
//            print("🚨 Force reset complete - color: \(self.color), blendFactor: \(self.colorBlendFactor)")
//        }
    
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
            print("   main node alpha: \(self.alpha)")
            print("   main node hasActions: \(self.hasActions())")
            
            // Check if the specific action is running
            if self.action(forKey: "playerSlowdownAlphaFlash") != nil {
                print("   ✅ Slowdown animation IS running")
            } else {
                print("   ❌ Slowdown animation NOT running")
            }
            
            if let visualSprite = visualSprite {
                print("   visualSprite alpha: \(visualSprite.alpha)")
                print("   visualSprite hasActions: \(visualSprite.hasActions())")
            }
            
            // Check for action conflicts
            if self.hasActions() {
                print("   📋 Main node has actions")
            }
            if let vs = visualSprite, vs.hasActions() {
                print("   📋 VisualSprite has actions (walking animation)")
            }
        }
    
    override func removeAllActions() {
            // If slowdown effect is active, preserve its state
            let wasShowingSlowdown = isShowingSlowdownEffect
            
            // Remove all actions
            super.removeAllActions()
            
            // If slowdown was active, restart it
            if wasShowingSlowdown {
                print("🔄 removeAllActions called during slowdown - restarting effect")
                DispatchQueue.main.async { [weak self] in
                    self?.retrySlowdownAnimation()
                }
            }
        }
}
