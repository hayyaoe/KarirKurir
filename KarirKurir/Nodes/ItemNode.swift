//
//  ItemNode.swift
//  KarirKurir
//
//  Created by Willas Daniel Rorrong Lumban Tobing on 11/07/25.
//

import SpriteKit

class ItemNode: SKSpriteNode {
    
    private var timerLabel: SKLabelNode!
    private var countdownTimer: Timer?
    private var remainingTime: Int
    
    // The category bar node, now a class property to be accessible later.
    private var categoryBar: SKShapeNode!
    
    // The item's category can now be changed internally.
    private(set) var category: ItemCategory
    
    static let categoryBitMask: UInt32 = 0x1 << 1
    
    // Callback to notify the scene when the timer expires
    var onTimerExpired: (() -> Void)?
    
    init(size: CGSize, initialTime: Int) {
        self.remainingTime = initialTime
        self.category = ItemCategory.category(for: initialTime)
        super.init(texture: nil, color: .clear, size: size)
        
        setupVisuals()
        setupCategoryIndicator()
        setupTimerLabel()
        setupPhysics()
        startCountdown()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupVisuals() {
        // Simple circle shape for the item
        let circle = SKShapeNode(circleOfRadius: size.width / 2)
        circle.fillColor = .systemYellow
        circle.strokeColor = .white
        circle.lineWidth = 2
        addChild(circle)
        
        // Add a subtle pulse animation
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        let pulse = SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown]))
        run(pulse)
    }
    
    private func setupCategoryIndicator() {
        // Create a colored bar above the item to show its category
        let barSize = CGSize(width: size.width * 0.8, height: 8)
        categoryBar = SKShapeNode(rectOf: barSize, cornerRadius: 4)
        categoryBar.fillColor = category.color
        categoryBar.strokeColor = category.color
        categoryBar.position = CGPoint(x: 0, y: (size.height / 2) + barSize.height)
        addChild(categoryBar)
    }
    
    private func setupPhysics() {
        self.physicsBody = SKPhysicsBody(circleOfRadius: size.width / 2)
        self.physicsBody?.isDynamic = false
        
        // Assign Physics Categories
        self.physicsBody?.categoryBitMask = ItemNode.categoryBitMask
        self.physicsBody?.collisionBitMask = PlayerNode.category
        self.physicsBody?.contactTestBitMask = 0
    }
    
    private func setupTimerLabel() {
        timerLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        timerLabel.fontSize = 18
        timerLabel.fontColor = .black
        timerLabel.position = CGPoint(x: 0, y: -timerLabel.frame.height / 2)
        updateTimerLabel()
        addChild(timerLabel)
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
        updateTimerLabel()
        
        // *** LOGIC TO UPDATE CATEGORY BAR COLOR ***
        let newCategory = ItemCategory.category(for: remainingTime)
        if newCategory != self.category {
            // Update the internal category state
            self.category = newCategory
            
            // Remove all existing actions on the category bar to prevent conflicts
            categoryBar?.removeAllActions()
            
            // Update both fill and stroke colors immediately, then animate
            categoryBar?.fillColor = newCategory.color
            categoryBar?.strokeColor = newCategory.color
            
            // Add a subtle scale animation to indicate the category change
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.15)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.15)
            let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
            categoryBar?.run(scaleSequence)
            
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
    
    private func updateTimerLabel() {
        timerLabel.text = "\(remainingTime)"
    }
    
    deinit {
        // Ensure the timer is invalidated when the node is removed
        countdownTimer?.invalidate()
    }
}
