//
//  GameScene.swift
//  KarirKurir
//

import SpriteKit

class GameScene: SKScene {
    
    // MARK: - Properties
    private var player: PlayerNode!
    private var inputController: InputController!
    private let tileSize = CGSize(width: 48, height: 48)
    private var currentDirection: MoveDirection = .right
    private var isAutoMoving = false
    private var moveTimer: Timer?
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = .darkGray
        setupPlayer()
        setupInputController()
        startAutoMovement()
    }
    
    // MARK: - Setup
    private func setupPlayer() {
        player = PlayerNode(tileSize: tileSize)
        player.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(player)
    }
    
    private func setupInputController() {
        guard let view = view else { return }
        inputController = InputController(view: view)
        inputController.onDirectionChange = { [weak self] direction in
            if let direction = direction {
                self?.changeDirection(direction)
            }
        }
    }
    
    // MARK: - Auto Movement
    private func startAutoMovement() {
        isAutoMoving = true
        moveTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.movePlayerAutomatically()
        }
    }
    
    private func stopAutoMovement() {
        isAutoMoving = false
        moveTimer?.invalidate()
        moveTimer = nil
    }
    
    private func movePlayerAutomatically() {
        guard isAutoMoving else { return }
        
        let targetPosition = getTargetPosition(for: currentDirection)
        
        // Check if the player would go out of bounds
        if !isPositionWithinBounds(targetPosition) {
            // Stop movement when hitting boundary
            stopAutoMovement()
            return
        }
        
        // Move the player
        player.move(to: targetPosition) { [weak self] in
            // Movement completed, continue if still auto-moving
        }
    }
    
    // MARK: - Input Handling
    private func changeDirection(_ direction: MoveDirection) {
        let previousDirection = currentDirection
        currentDirection = direction
        
        // Show visual feedback for direction change
        if previousDirection != direction {
            player.showDirectionChange()
        }
        
        // If not currently auto-moving, start it
        if !isAutoMoving {
            startAutoMovement()
        }
    }
    
    // MARK: - Helpers
    private func getTargetPosition(for direction: MoveDirection) -> CGPoint {
        var targetPos = player.position
        switch direction {
        case .right:
            targetPos.x += tileSize.width
        case .left:
            targetPos.x -= tileSize.width
        case .up:
            targetPos.y += tileSize.height
        case .down:
            targetPos.y -= tileSize.height
        }
        return targetPos
    }
    
    private func isPositionWithinBounds(_ position: CGPoint) -> Bool {
        let playerHalfWidth = player.size.width / 2
        let playerHalfHeight = player.size.height / 2
        let bounds = frame.insetBy(dx: playerHalfWidth, dy: playerHalfHeight)
        return bounds.contains(position)
    }
    
    deinit {
        stopAutoMovement()
    }
}
