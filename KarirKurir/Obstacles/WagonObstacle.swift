//
//  WagonObstacle.swift
//  KarirKurir
//
//  Created by Willas Daniel Rorrong Lumban Tobing on 16/07/25.
//

import SpriteKit

class WagonObstacle: SKSpriteNode {
    static let categoryBitMask: UInt32 = 0x1 << 4
        
    private var currentDirection: MoveDirection = .right
    private var animationFrames: [MoveDirection: [SKTexture]] = [:]
    private var isMoving: Bool = true
    private var gridSize: CGFloat
    private var maze: [[Int]] = []
    private var mazeOffset: CGPoint = .zero
    private var playerSpeedFactor: Double = 1.0
    private let moveSpeed: TimeInterval = 0.5 // Same constant speed as cat obstacle
    
    // Movement
    private var moveTimer: Timer?
    private var isBlocked: Bool = false
    private var lastMoveDirection: MoveDirection?
    private var stuckCounter: Int = 0
    private let maxStuckAttempts: Int = 3
    private var isInEscapeMode: Bool = false
    private var escapeDirections: [MoveDirection] = []
    
    // Player interaction
    weak var player: PlayerNode?
    var onPlayerInteraction: ((WagonObstacle, PlayerInteractionType) -> Void)?
    
    enum PlayerInteractionType {
        case playerInFront      // Player in front - both stop
        case playerBehind       // Player behind - both stop
        case playerAtSide       // Player at side - player stops until wagon moves
        case playerClear        // Player clear - normal movement
    }
    
    init(gridSize: CGFloat, maze: [[Int]], mazeOffset: CGPoint, playerSpeedFactor: Double) {
        self.gridSize = gridSize
        self.maze = maze
        self.mazeOffset = mazeOffset
        self.playerSpeedFactor = playerSpeedFactor
        
        // Load default texture
        let defaultTexture = SKTexture(imageNamed: "obstacleWagonRight1")
        let wagonSize = CGSize(width: gridSize * 1.2, height: gridSize * 1.2)
        
        super.init(texture: defaultTexture, color: .clear, size: wagonSize)
        
        setupTextures()
        setupPhysics()
        startMovement()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupTextures() {
        // Load animation frames for each direction
        animationFrames[.down] = (1...4).map { SKTexture(imageNamed: "obstacleWagonDown\($0)") }
        animationFrames[.up] = (1...4).map { SKTexture(imageNamed: "obstacleWagonUp\($0)") }
        animationFrames[.left] = (1...4).map { SKTexture(imageNamed: "obstacleWagonLeft\($0)") }
        animationFrames[.right] = (1...4).map { SKTexture(imageNamed: "obstacleWagonRight\($0)") }
    }
    
    private func setupPhysics() {
        physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: gridSize * 0.8, height: gridSize * 0.8))
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = WagonObstacle.categoryBitMask
        physicsBody?.collisionBitMask = PlayerNode.category // Now collides with player
        physicsBody?.contactTestBitMask = PlayerNode.category
    }
    
    private func startMovement() {
        scheduleNextMove()
    }
    
    private func scheduleNextMove() {
        guard !isBlocked else {
            // Check again later if blocked
            moveTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
                self?.scheduleNextMove()
            }
            return
        }
        
        // Use constant speed same as cat obstacle (0.5 seconds)
        moveTimer = Timer.scheduledTimer(withTimeInterval: moveSpeed, repeats: false) { [weak self] _ in
            self?.moveToNextPosition()
        }
    }
    
    private func moveToNextPosition() {
        // Check if we're blocked before attempting to move
        guard !isBlocked else {
            print("Wagon attempted to move while blocked - stopping")
            return
        }
        
        let currentGridPos = worldToGridPosition(position)
        let nextPosition = findNextRoadPosition(from: currentGridPos)
        
        if let nextPos = nextPosition {
            let worldPos = gridToWorldPosition(nextPos)
            updateDirection(to: worldPos)
            
            // Double-check we're not blocked before starting move action
            guard !isBlocked else {
                print("Wagon blocked during move setup - stopping")
                return
            }
            
            // Use constant speed same as cat obstacle
            let moveAction = SKAction.move(to: worldPos, duration: moveSpeed)
            moveAction.timingMode = .linear
            
            // Create completion action
            let completionAction = SKAction.run { [weak self] in
                // Check if we're still not blocked after movement completes
                guard let self = self, !self.isBlocked else {
                    print("Wagon blocked after movement - not scheduling next move")
                    return
                }
                self.checkPlayerInteraction()
                self.scheduleNextMove()
            }
            
            // Create sequence with move and completion
            let sequence = SKAction.sequence([moveAction, completionAction])
            
            playWalkAnimation()
            
            // Reset stuck counter on successful move
            stuckCounter = 0
            lastMoveDirection = currentDirection
            
            run(sequence, withKey: "wagonMovement")
        } else {
            // No valid next position found
            handleStuckSituation()
        }
    }
    
    private func findNextRoadPosition(from gridPos: CGPoint) -> CGPoint? {
        // If in escape mode, use escape directions
        if isInEscapeMode && !escapeDirections.isEmpty {
            return findEscapePosition(from: gridPos)
        }
        
        // Normal movement logic
        let allDirections: [MoveDirection] = [.up, .down, .left, .right]
        var availableDirections: [MoveDirection] = []
        
        // Find all valid directions
        for direction in allDirections {
            if let nextPos = getNextPositionInDirection(from: gridPos, direction: direction) {
                if isValidRoadPosition(nextPos) {
                    availableDirections.append(direction)
                }
            }
        }
        
        // Remove empty directions
        if availableDirections.isEmpty {
            return nil
        }
        
        // Improved movement logic to reduce back-and-forth
        var preferredDirections: [MoveDirection] = []
        
        if availableDirections.count > 1 {
            // Filter out the opposite direction to avoid immediate reversals
            if let lastDirection = lastMoveDirection {
                let oppositeDirection = getOppositeDirection(lastDirection)
                preferredDirections = availableDirections.filter { $0 != oppositeDirection }
            }
            
            // If we still have options after filtering, use them
            if !preferredDirections.isEmpty {
                availableDirections = preferredDirections
            }
        }
        
        // Add randomness: prefer continuing in current direction sometimes
        if availableDirections.contains(currentDirection) && Double.random(in: 0...1) < 0.4 {
            // 40% chance to continue in current direction - no assignment needed
        } else {
            // Choose a random direction from available options
            currentDirection = availableDirections.randomElement() ?? currentDirection
        }
        
        return getNextPositionInDirection(from: gridPos, direction: currentDirection)
    }
    
    private func findEscapePosition(from gridPos: CGPoint) -> CGPoint? {
        // Try escape directions in order of priority
        for direction in escapeDirections {
            if let nextPos = getNextPositionInDirection(from: gridPos, direction: direction) {
                if isValidRoadPosition(nextPos) {
                    currentDirection = direction
                    print("Wagon escaping in direction: \(direction.description)")
                    return nextPos
                }
            }
        }
        
        // If no escape directions work, try any valid direction
        let allDirections: [MoveDirection] = [.up, .down, .left, .right]
        for direction in allDirections {
            if let nextPos = getNextPositionInDirection(from: gridPos, direction: direction) {
                if isValidRoadPosition(nextPos) {
                    currentDirection = direction
                    print("Wagon escaping in fallback direction: \(direction.description)")
                    return nextPos
                }
            }
        }
        
        // No valid escape routes
        return nil
    }
    
    private func handleStuckSituation() {
        // Don't try to handle stuck situation if we're blocked
        guard !isBlocked else {
            print("Wagon stuck but blocked - not attempting recovery")
            return
        }
        
        stuckCounter += 1
        
        if stuckCounter >= maxStuckAttempts {
            // Force a random direction change after being stuck
            print("Wagon stuck, forcing random direction change")
            let allDirections: [MoveDirection] = [.up, .down, .left, .right]
            currentDirection = allDirections.randomElement() ?? .right
            stuckCounter = 0
        }
        
        // Try again shortly, but only if not blocked
        moveTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
            guard let self = self, !self.isBlocked else { return }
            self.scheduleNextMove()
        }
    }
    
    private func getNextPositionInDirection(from gridPos: CGPoint, direction: MoveDirection) -> CGPoint? {
        let vector = direction.vector
        let nextPos = CGPoint(
            x: gridPos.x + vector.dx,
            y: gridPos.y + vector.dy
        )
        return nextPos
    }
    
    private func isValidRoadPosition(_ gridPos: CGPoint) -> Bool {
        let row = Int(gridPos.y)
        let col = Int(gridPos.x)
        
        guard row >= 0 && row < maze.count && col >= 0 && col < maze[0].count else {
            return false
        }
        
        return maze[row][col] == 0 // 0 means road/path
    }
    
    private func updateDirection(to target: CGPoint) {
        let dx = target.x - position.x
        let dy = target.y - position.y
        
        if abs(dx) > abs(dy) {
            currentDirection = dx > 0 ? .right : .left
        } else {
            currentDirection = dy > 0 ? .up : .down
        }
    }
    
    private func getOppositeDirection(_ direction: MoveDirection) -> MoveDirection {
        switch direction {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }
    
    private func playWalkAnimation() {
        guard let frames = animationFrames[currentDirection] else { return }
        
        let animation = SKAction.animate(with: frames, timePerFrame: 0.15)
        let repeatAction = SKAction.repeatForever(animation)
        run(repeatAction, withKey: "walkAnimation")
    }
    
    private func stopAnimation() {
        removeAction(forKey: "walkAnimation")
    }
    
    private func checkPlayerInteraction() {
        guard let player = player else { return }
        
        let playerGridPos = worldToGridPosition(player.position)
        let wagonGridPos = worldToGridPosition(position)
        
        // Check if player is directly behind wagon
        let behindPosition = getPositionBehind(wagonGridPos)
        if playerGridPos.x == behindPosition.x && playerGridPos.y == behindPosition.y {
            onPlayerInteraction?(self, .playerBehind)
            return
        }
        
        // Check if player is directly in front of wagon
        let frontPosition = getPositionInFront(wagonGridPos)
        if playerGridPos.x == frontPosition.x && playerGridPos.y == frontPosition.y {
            onPlayerInteraction?(self, .playerInFront)
            return
        }
        
        // Player is clear
        onPlayerInteraction?(self, .playerClear)
    }
    
    private func getPositionBehind(_ wagonPos: CGPoint) -> CGPoint {
        let oppositeVector = getOppositeDirection(currentDirection).vector
        return CGPoint(
            x: wagonPos.x + oppositeVector.dx,
            y: wagonPos.y + oppositeVector.dy
        )
    }
    
    private func getPositionInFront(_ wagonPos: CGPoint) -> CGPoint {
        let currentVector = currentDirection.vector
        return CGPoint(
            x: wagonPos.x + currentVector.dx,
            y: wagonPos.y + currentVector.dy
        )
    }
    
    func setEscapeMode(escapeDirections: [MoveDirection]) {
        self.isInEscapeMode = true
        self.escapeDirections = escapeDirections
        self.isBlocked = false
        
        // Immediately try to move in escape direction
        scheduleNextMove()
        print("Wagon entering escape mode with directions: \(escapeDirections.map { $0.description })")
    }
    
    func resumeNormalMovement() {
        self.isInEscapeMode = false
        self.escapeDirections = []
        self.isBlocked = false
        
        // Resume normal movement
        scheduleNextMove()
        print("Wagon resuming normal movement")
    }
    
    func setBlocked(_ blocked: Bool, reason: String = "") {
        isBlocked = blocked
        if blocked {
            print("Wagon blocked: \(reason)")
            stopAnimation()
            removeAction(forKey: "wagonMovement") // Stop specific movement action
            removeAllActions() // Stop any other actions
            moveTimer?.invalidate() // Stop the movement timer
            moveTimer = nil
            
            // Clear escape mode when blocked
            isInEscapeMode = false
            escapeDirections = []
        } else {
            print("Wagon unblocked")
            scheduleNextMove()
        }
    }
    
    func isCurrentlyBlocked() -> Bool {
        return isBlocked
    }
    
    func getCurrentDirection() -> MoveDirection {
        return currentDirection
    }
    
    func getGridPosition() -> CGPoint {
        return worldToGridPosition(position)
    }
    
    // Method to check if wagon is about to change direction
    func isAboutToChangeDirection() -> Bool {
        let currentGridPos = worldToGridPosition(position)
        let nextPosition = findNextRoadPosition(from: currentGridPos)
        
        if let nextPos = nextPosition {
            let newDirection = getDirectionToPosition(from: currentGridPos, to: nextPos)
            return newDirection != currentDirection
        }
        return false
    }
    
    private func getDirectionToPosition(from: CGPoint, to: CGPoint) -> MoveDirection {
        let deltaX = to.x - from.x
        let deltaY = to.y - from.y
        
        if abs(deltaX) > abs(deltaY) {
            return deltaX > 0 ? .right : .left
        } else {
            return deltaY > 0 ? .up : .down
        }
    }
    
    private func worldToGridPosition(_ worldPos: CGPoint) -> CGPoint {
        let gridX = Int((worldPos.x - mazeOffset.x) / gridSize)
        let gridY = Int((worldPos.y - mazeOffset.y) / gridSize)
        return CGPoint(x: gridX, y: maze.count - gridY - 1)
    }
    
    private func gridToWorldPosition(_ gridPos: CGPoint) -> CGPoint {
        return CGPoint(
            x: mazeOffset.x + CGFloat(gridPos.x) * gridSize + gridSize/2,
            y: mazeOffset.y + CGFloat(maze.count - Int(gridPos.y) - 1) * gridSize + gridSize/2
        )
    }
    
    func updateMaze(_ newMaze: [[Int]], offset: CGPoint) {
        maze = newMaze
        mazeOffset = offset
    }
    
    func updatePlayerSpeedFactor(_ factor: Double) {
        // No longer used - wagon now uses constant speed like cat obstacle
        // Keeping method for compatibility with existing code
    }
    
    deinit {
        moveTimer?.invalidate()
    }
}
