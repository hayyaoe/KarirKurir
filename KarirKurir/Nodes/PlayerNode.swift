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

    init(tileSize: CGSize) {
        // Load textures once for default
        let defaultTexture = SKTexture(imageNamed: "courierRight1")
        let playerSize = CGSize(width: tileSize.width, height: tileSize.height)

        super.init(texture: defaultTexture, color: .clear, size: playerSize)

        setupTextures()
        setupPhysics(size: playerSize)
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
    
    func showSlowdownEffect() {
        guard !isShowingSlowdownEffect else { return }
        
        isShowingSlowdownEffect = true
        
        // Create slowdown indicator
        slowdownIndicator = SKSpriteNode(color: .red, size: CGSize(width: size.width * 1.3, height: size.height * 1.3))
        slowdownIndicator?.alpha = 0.6
        slowdownIndicator?.zPosition = -1 // Behind player
        slowdownIndicator?.name = "slowdownIndicator"
        
        if let indicator = slowdownIndicator {
            addChild(indicator)
            
            // Create flashing animation
            let fadeOut = SKAction.fadeAlpha(to: 0.2, duration: 0.3)
            let fadeIn = SKAction.fadeAlpha(to: 0.8, duration: 0.3)
            let flash = SKAction.sequence([fadeOut, fadeIn])
            let repeatFlash = SKAction.repeatForever(flash)
            
            indicator.run(repeatFlash, withKey: "flashingEffect")
            
            print("Player slowdown effect started - red flashing indicator")
        }
    }
    
    func hideSlowdownEffect() {
        guard isShowingSlowdownEffect else { return }
        
        isShowingSlowdownEffect = false
        
        slowdownIndicator?.removeAction(forKey: "flashingEffect")
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fadeOut, remove])
        
        slowdownIndicator?.run(sequence) { [weak self] in
            self?.slowdownIndicator = nil
        }
        
        print("Player slowdown effect ended")
    }
    
    func isShowingSlowdown() -> Bool {
        return isShowingSlowdownEffect
    }
    
    func moveWithCustomDuration(to targetPosition: CGPoint, duration: TimeInterval, completion: @escaping () -> Void) {
            // Remove any existing actions first
            removeAllActions()
            
            updateDirection(to: targetPosition)
            animateWalk()

            let moveAction = SKAction.move(to: targetPosition, duration: duration)
            moveAction.timingMode = .easeInEaseOut

            let done = SKAction.run {
                completion()
            }

            run(SKAction.sequence([moveAction, done]))
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

        let animation = SKAction.animate(with: frames, timePerFrame: moveDuration / Double(frames.count))
        let repeatAction = SKAction.repeatForever(animation)
        run(repeatAction, withKey: "walkAnimation")
    }
}
