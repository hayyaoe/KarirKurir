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

    enum FacingDirection {
        case up, down, left, right
    }

    private var facing: FacingDirection = .right
    private var animationFrames: [FacingDirection: [SKTexture]] = [:]

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
        physicsBody?.categoryBitMask = 1 // Player
        physicsBody?.collisionBitMask = 2 // Walls
        physicsBody?.contactTestBitMask = 2 | 4 // Walls + Destination
    }

    func move(to targetPosition: CGPoint, completion: @escaping () -> Void) {
        removeAllActions()

        updateDirection(to: targetPosition)
        animateWalk()

        let moveAction = SKAction.move(to: targetPosition, duration: moveDuration)
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
