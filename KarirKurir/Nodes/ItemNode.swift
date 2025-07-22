//
//  ItemNode.swift
//  KarirKurir
//
//  Created by Willas Daniel Rorrong Lumban Tobing on 11/07/25.
//

import SpriteKit

class ItemNode: SKSpriteNode {
    private var countdownTimer: Timer?
    private var remainingTime: Int
    private var initialTime: Int
    
    // Chat bubble components
    private var chatBubble: SKSpriteNode!
    private var progressBarBackground: SKShapeNode!
    private var progressBarFill: SKShapeNode!
    
    // The item's category can now be changed internally.
    private(set) var category: ItemCategory
    
    static let categoryBitMask: UInt32 = 0x1 << 1
    
    // Callback to notify the scene when the timer expires
    var onTimerExpired: (() -> Void)?
    
    init(size: CGSize, initialTime: Int) {
        self.remainingTime = initialTime
        self.initialTime = initialTime
        self.category = ItemCategory.category(for: initialTime)
        super.init(texture: nil, color: .clear, size: size)
        
        setupVisuals()
        setupChatBubbleTimer()
        setupPhysics()
        startCountdown()
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupVisuals() {
        // Add a subtle pulse animation
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        let pulse = SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown]))
        run(pulse)
    }
    
    private func setupChatBubbleTimer() {
        // Create chat bubble using the provided image
        let bubbleTexture = SKTexture(imageNamed: "package") // Use your chat bubble image name
        chatBubble = SKSpriteNode(texture: bubbleTexture, size: CGSize(width: size.width * 2.6, height: size.height * 2.3))
        chatBubble.position = CGPoint(x: 0, y: size.height * 0.8) // Position above the item
        chatBubble.zPosition = 1
        addChild(chatBubble)
        
        // Create progress bar background inside the bubble
        let barWidth: CGFloat = chatBubble.size.width * 0.7
        let barHeight: CGFloat = 8
        progressBarBackground = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 4)
        progressBarBackground.fillColor = .darkGray
        progressBarBackground.strokeColor = .clear
        progressBarBackground.position = CGPoint(x: 0, y: -2) // Slightly below center of bubble
        chatBubble.addChild(progressBarBackground)
        
        // Create progress bar fill
        progressBarFill = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight), cornerRadius: 4)
        progressBarFill.fillColor = category.color
        progressBarFill.strokeColor = .clear
        progressBarFill.position = CGPoint(x: 0, y: 0)
        progressBarBackground.addChild(progressBarFill)
    }
    
    private func setupPhysics() {
        physicsBody = SKPhysicsBody(circleOfRadius: size.width / 2)
        physicsBody?.isDynamic = false
        
        // Assign Physics Categories
        physicsBody?.categoryBitMask = ItemNode.categoryBitMask
        physicsBody?.collisionBitMask = PlayerNode.category
        physicsBody?.contactTestBitMask = 0
    }
    
    private func startCountdown() {
        // The timer closure now safely unwraps self.
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            // Safely unwrap self. If self is nil (because the node was deallocated),
            // the code inside the guard will not execute, preventing a crash.
            guard let self = self else { return }
            
            // Now that we have a strong reference to self, we can safely call the instance method.
            self.updateTimer()
        }
    }
    
    private func updateTimer() {
        // Add a guard to ensure the node is still part of the scene.
        // This prevents crashes if the timer fires after the node has been removed
        // but before it has been deallocated.
        guard scene != nil else {
            countdownTimer?.invalidate()
            return
        }
        
        guard remainingTime > 0 else {
            // This case should ideally not be hit if the timer is invalidated properly,
            // but as a safeguard, we invalidate and exit.
            countdownTimer?.invalidate()
            return
        }
        
        remainingTime -= 1
        updateProgressBar()
        
        // Update category and color based on remaining time
        let newCategory = ItemCategory.category(for: remainingTime)
        if newCategory != category {
            // Update the internal category state
            category = newCategory
            
            // Update progress bar color with animation
            let colorChangeAction = SKAction.run {
                self.progressBarFill.fillColor = newCategory.color
            }
            
            // Add a subtle scale animation to indicate the category change
            let scaleUp = SKAction.scale(to: 1.1, duration: 0.15)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.15)
            let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
            
            progressBarFill.run(SKAction.group([colorChangeAction, scaleSequence]))
            
            print("Category changed to \(newCategory) at time \(remainingTime) - Color: \(newCategory.color)")
        }
        
        if remainingTime <= 0 {
            countdownTimer?.invalidate()
            onTimerExpired?()
            
            run(SKAction.fadeOut(withDuration: 0.2)) {
                self.removeFromParent()
            }
        }
    }
    
    private func updateProgressBar() {
        let progress = CGFloat(remainingTime) / CGFloat(initialTime)
        let maxWidth = progressBarBackground.frame.width
        let newWidth = maxWidth * progress
        
        // Animate the progress bar shrinking
        let newSize = CGSize(width: newWidth, height: progressBarFill.frame.height)
        
        // Remove current fill and create new one with updated size
        progressBarFill.removeFromParent()
        progressBarFill = SKShapeNode(rectOf: newSize, cornerRadius: 4)
        progressBarFill.fillColor = category.color
        progressBarFill.strokeColor = .clear
        
        // Position the bar to align to the left side
        let offsetX = -(maxWidth - newWidth) / 2
        progressBarFill.position = CGPoint(x: offsetX, y: 0)
        progressBarBackground.addChild(progressBarFill)
        
        // Add a subtle animation to the bar update
        progressBarFill.alpha = 0.8
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.2)
        progressBarFill.run(fadeIn)
    }
    
    deinit {
        // Ensure the timer is invalidated when the node is removed
        countdownTimer?.invalidate()
    }
}
