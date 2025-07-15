//
//  PlayerNode.swift
//  KarirKurir
//
import SpriteKit

class PlayerNode: SKSpriteNode {
    private let moveDuration: TimeInterval = 0.18
    private var directionIndicator: SKSpriteNode!
    
    static let category: UInt32 = 0x1 << 0

    init(tileSize: CGSize) {
        let playerSize = CGSize(width: tileSize.width * 0.8, height: tileSize.height * 0.8)
        super.init(texture: nil, color: .systemGreen, size: playerSize)
        
        setupVisualElements()
        setupPhysics(playerSize: playerSize)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupVisualElements() {
        // Add rounded corners effect
        let cornerRadius: CGFloat = 8
        let roundedRect = SKShapeNode(rectOf: size, cornerRadius: cornerRadius)
        roundedRect.fillColor = .systemGreen
        roundedRect.strokeColor = .white
        roundedRect.lineWidth = 2
        addChild(roundedRect)
        
        // Add direction indicator (small arrow)
        directionIndicator = SKSpriteNode(color: .white, size: CGSize(width: 8, height: 12))
        directionIndicator.position = CGPoint(x: size.width/4, y: 0)
        addChild(directionIndicator)
        
        // Add a subtle glow effect
        let glowNode = SKShapeNode(rectOf: CGSize(width: size.width + 4, height: size.height + 4), cornerRadius: 10)
        glowNode.fillColor = .clear
        glowNode.strokeColor = .systemGreen
        glowNode.lineWidth = 1
        glowNode.alpha = 0.3
        glowNode.zPosition = -1
        addChild(glowNode)
    }
    
    private func setupPhysics(playerSize: CGSize) {
        physicsBody = SKPhysicsBody(rectangleOf: playerSize)
        physicsBody?.affectedByGravity = false
        physicsBody?.isDynamic = true
        physicsBody?.allowsRotation = false
        
        // Updated physics categories
        physicsBody?.categoryBitMask = PlayerNode.category // Player category
        physicsBody?.collisionBitMask = 2 // Collide with walls (category 2)
        physicsBody?.contactTestBitMask = 2 | ItemNode.categoryBitMask // Test contact with walls and items
        
        print("Player physics setup: categoryBitMask = \(PlayerNode.category), contactTestBitMask = \(2 | ItemNode.categoryBitMask)")
    }
    
    func move(to targetPosition: CGPoint, completion: @escaping () -> Void) {
        moveWithCustomDuration(to: targetPosition, duration: moveDuration, completion: completion)
    }
    
    func moveWithCustomDuration(to targetPosition: CGPoint, duration: TimeInterval, completion: @escaping () -> Void) {
        // Remove any existing actions first
        removeAllActions()
        
        // Update direction indicator
        updateDirectionIndicator(to: targetPosition)
        
        // Create smooth movement with better easing
        let moveAction = SKAction.move(to: targetPosition, duration: duration)
        moveAction.timingMode = .easeInEaseOut
        
        // Add a slight scale effect for juice
        let scaleUp = SKAction.scale(to: 1.1, duration: duration/2)
        let scaleDown = SKAction.scale(to: 1.0, duration: duration/2)
        let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
        
        let doneAction = SKAction.run(completion)
        let moveSequence = SKAction.sequence([moveAction, doneAction])
        
        // Run both actions in parallel
        run(SKAction.group([moveSequence, scaleSequence]))
    }
    
    private func updateDirectionIndicator(to targetPosition: CGPoint) {
        let currentPos = position
        let deltaX = targetPosition.x - currentPos.x
        let deltaY = targetPosition.y - currentPos.y
        
        // Calculate angle for direction indicator
        let angle = atan2(deltaY, deltaX)
        
        // Rotate direction indicator
        let rotateAction = SKAction.rotate(toAngle: angle, duration: 0.1)
        directionIndicator.run(rotateAction)
        
        // Position indicator based on direction
        let indicatorDistance: CGFloat = size.width/3
        let indicatorX = cos(angle) * indicatorDistance
        let indicatorY = sin(angle) * indicatorDistance
        
        let moveIndicator = SKAction.move(to: CGPoint(x: indicatorX, y: indicatorY), duration: 0.1)
        directionIndicator.run(moveIndicator)
    }
    
    func showDirectionChange() {
        // Brief flash effect when direction changes
        let flash = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.7, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])
        run(flash)
    }
}
