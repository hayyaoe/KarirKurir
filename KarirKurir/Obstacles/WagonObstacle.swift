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
    private let moveSpeed: TimeInterval = 0.8 // Slower than before for better player interaction
    
    // Movement
    private var moveTimer: Timer?
    private var isBlocked: Bool = false
    private var lastMoveDirection: MoveDirection?
    private var stuckCounter: Int = 0
    private let maxStuckAttempts: Int = 3
    private var isInEscapeMode: Bool = false
    private var escapeDirections: [MoveDirection] = []
    private var deadEndCounter: Int = 0
    private let maxDeadEndAttempts: Int = 2
    
    // Player interaction
    weak var player: PlayerNode?
    var onPlayerInteraction: ((WagonObstacle, PlayerInteractionType) -> Void)?
    
    enum PlayerInteractionType {
        case playerInFront      // Player in front - both stop
        case playerBehind       // Player behind - wagon moves away, player can follow
        case playerAtSide       // Player at side - wagon tries to escape
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
        physicsBody?.collisionBitMask = PlayerNode.category
        physicsBody?.contactTestBitMask = PlayerNode.category
    }
    
    private func startMovement() {
        scheduleNextMove()
    }
    
    private func scheduleNextMove() {
        // IMPORTANT: If player is behind, wagon should NEVER be blocked
        if isBlocked && !isPlayerCurrentlyBehind() {
            // Only check again later if blocked and player is NOT behind
            moveTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { [weak self] _ in
                self?.scheduleNextMove()
            }
            return
        }
        
        // If player is behind, force unblock and continue moving
        if isPlayerCurrentlyBehind() && isBlocked {
            isBlocked = false
            print("Wagon: Unblocking because player is behind - must keep moving")
        }
        
        moveTimer = Timer.scheduledTimer(withTimeInterval: moveSpeed, repeats: false) { [weak self] _ in
            self?.moveToNextPosition()
        }
    }
    
    private func isPlayerCurrentlyBehind() -> Bool {
        guard let playerPos = getPlayerGridPosition() else { return false }
        let wagonPos = worldToGridPosition(position)
        return isPlayerBehind(playerPos, wagonPos: wagonPos)
    }
    
    private func moveToNextPosition() {
        // IMPORTANT: Never stop moving if player is behind
        let playerBehind = isPlayerCurrentlyBehind()
        
        if isBlocked && !playerBehind {
            print("Wagon attempted to move while blocked - stopping")
            return
        }
        
        // If player is behind, force continue moving even if blocked
        if playerBehind && isBlocked {
            isBlocked = false
            print("Wagon: Player behind - forcing movement to continue")
        }
        
        let currentGridPos = worldToGridPosition(position)
        let nextPosition = findNextRoadPosition(from: currentGridPos)
        
        if let nextPos = nextPosition {
            let worldPos = gridToWorldPosition(nextPos)
            updateDirection(to: worldPos)
            
            // Double check - if player is behind, never block
            if playerBehind && isBlocked {
                isBlocked = false
                print("Wagon: Double-check unblock for player behind")
            }
            
            let moveAction = SKAction.move(to: worldPos, duration: moveSpeed)
            moveAction.timingMode = .linear
            
            let completionAction = SKAction.run { [weak self] in
                guard let self = self else { return }
                
                // Important: Even after movement, don't block if player is behind
                let stillBehind = self.isPlayerCurrentlyBehind()
                if stillBehind && self.isBlocked {
                    self.isBlocked = false
                    print("Wagon: Post-movement unblock - player still behind")
                }
                
                self.checkPlayerInteraction()
                self.scheduleNextMove()
                
                // Reset dead end counter on successful move
                self.deadEndCounter = 0
            }
            
            let sequence = SKAction.sequence([moveAction, completionAction])
            playWalkAnimation()
            
            // Reset stuck counter on successful move
            stuckCounter = 0
            lastMoveDirection = currentDirection
            
            run(sequence, withKey: "wagonMovement")
        } else {
            // No valid next position found - but if player is behind, try harder to find a path
            if playerBehind {
                print("Wagon: Player behind but no path found - trying alternative directions")
                // Try any available direction, even if not optimal
                let allDirections: [MoveDirection] = [.up, .down, .left, .right]
                for direction in allDirections {
                    if let nextPos = getNextPositionInDirection(from: currentGridPos, direction: direction) {
                        if isValidRoadPosition(nextPos) {
                            currentDirection = direction
                            print("Wagon: Using fallback direction \(direction.description) to avoid stopping")
                            scheduleNextMove()
                            return
                        }
                    }
                }
            }
            
            // Handle dead end normally
            handleDeadEnd()
        }
    }
    
    private func findNextRoadPosition(from gridPos: CGPoint) -> CGPoint? {
        // If in escape mode, use escape directions
        if isInEscapeMode && !escapeDirections.isEmpty {
            return findEscapePosition(from: gridPos)
        }
        
        // Normal movement logic with strict player avoidance
        let allDirections: [MoveDirection] = [.up, .down, .left, .right]
        var availableDirections: [MoveDirection] = []
        
        // Find all valid directions (not walls, within bounds)
        for direction in allDirections {
            if let nextPos = getNextPositionInDirection(from: gridPos, direction: direction) {
                if isValidRoadPosition(nextPos) {
                    availableDirections.append(direction)
                }
            }
        }
        
        if availableDirections.isEmpty {
            print("Wagon: No available directions at all")
            return nil
        }
        
        // FIXED: Strict player avoidance when player is behind
        var preferredDirections = availableDirections
        
        if let playerPos = getPlayerGridPosition() {
            if isPlayerBehind(playerPos, wagonPos: gridPos) {
                // Get the direction toward player (we want to AVOID this)
                let directionToPlayer = getDirectionToPlayer(from: gridPos, to: playerPos)
                
                // ALSO avoid the opposite of current direction (don't turn around toward player)
                let currentOpposite = getOppositeDirection(currentDirection)
                
                // Filter out BOTH the direction to player AND turning around
                let safeDirections = availableDirections.filter { direction in
                    return direction != directionToPlayer && direction != currentOpposite
                }
                
                if !safeDirections.isEmpty {
                    preferredDirections = safeDirections
                    print("Wagon: Player behind, avoiding direction to player (\(directionToPlayer.description)) and turning around (\(currentOpposite.description))")
                    print("Wagon: Safe directions: \(safeDirections.map { $0.description })")
                } else {
                    // If no safe directions, at least avoid moving directly toward player
                    let notTowardPlayer = availableDirections.filter { $0 != directionToPlayer }
                    if !notTowardPlayer.isEmpty {
                        preferredDirections = notTowardPlayer
                        print("Wagon: No fully safe directions, at least avoiding direct path to player")
                    } else {
                        // Last resort - any available direction
                        preferredDirections = availableDirections
                        print("Wagon: All directions problematic, using any available")
                    }
                }
            } else {
                // Player not behind - move freely but still prefer not reversing
                if availableDirections.count > 1, let lastDirection = lastMoveDirection {
                    let oppositeDirection = getOppositeDirection(lastDirection)
                    let nonReverseDirections = availableDirections.filter { $0 != oppositeDirection }
                    if !nonReverseDirections.isEmpty {
                        preferredDirections = nonReverseDirections
                    }
                }
            }
        } else {
            // No player detected - avoid reversals
            if availableDirections.count > 1, let lastDirection = lastMoveDirection {
                let oppositeDirection = getOppositeDirection(lastDirection)
                let nonReverseDirections = availableDirections.filter { $0 != oppositeDirection }
                if !nonReverseDirections.isEmpty {
                    preferredDirections = nonReverseDirections
                }
            }
        }
        
        // Choose direction - prefer continuing forward if it's safe
        if preferredDirections.contains(currentDirection) && Double.random(in: 0...1) < 0.7 {
            print("Wagon: Continuing forward in safe direction \(currentDirection.description)")
            // Keep current direction
        } else {
            let newDirection = preferredDirections.randomElement() ?? currentDirection
            currentDirection = newDirection
            print("Wagon: Changing to safe direction \(currentDirection.description)")
        }
        
        return getNextPositionInDirection(from: gridPos, direction: currentDirection)
    }
    
    private func isDeadEnd(_ gridPos: CGPoint) -> Bool {
        let allDirections: [MoveDirection] = [.up, .down, .left, .right]
        var validDirections = 0
        
        for direction in allDirections {
            if let nextPos = getNextPositionInDirection(from: gridPos, direction: direction) {
                if isValidRoadPosition(nextPos) {
                    validDirections += 1
                }
            }
        }
        
        return validDirections <= 1 // Dead end if only one or no valid directions
    }
    
    private func getPlayerGridPosition() -> CGPoint? {
        guard let player = player else { return nil }
        return worldToGridPosition(player.position)
    }
    
    private func isPlayerBehind(_ playerPos: CGPoint, wagonPos: CGPoint) -> Bool {
        // Calculate which direction the wagon is currently moving
        let wagonDirection = currentDirection
        
        // Get the position that would be "behind" the wagon (opposite to its movement direction)
        let oppositeVector = getOppositeDirection(wagonDirection).vector
        let behindPos = CGPoint(
            x: wagonPos.x + oppositeVector.dx,
            y: wagonPos.y + oppositeVector.dy
        )
        
        // Check if player is in the "behind" area (within reasonable distance)
        let distance = hypot(playerPos.x - behindPos.x, playerPos.y - behindPos.y)
        let isDirectlyBehind = distance <= 1.0
        
        // Also check if player is generally in the opposite direction of wagon's movement
        let deltaX = playerPos.x - wagonPos.x
        let deltaY = playerPos.y - wagonPos.y
        let wagonDirectionVector = wagonDirection.vector
        
        // Check if player is in the opposite direction of wagon movement
        let isInOppositeDirection = (deltaX * (-wagonDirectionVector.dx) + deltaY * (-wagonDirectionVector.dy)) > 0
        
        let result = isDirectlyBehind || (isInOppositeDirection && hypot(deltaX, deltaY) <= 2.0)
        
        if result {
            print("Player is behind wagon - wagon direction: \(wagonDirection.description), player at: \(playerPos), wagon at: \(wagonPos)")
        }
        
        return result
    }
    
    private func getDirectionToPlayer(from wagonPos: CGPoint, to playerPos: CGPoint) -> MoveDirection {
        let deltaX = playerPos.x - wagonPos.x
        let deltaY = playerPos.y - wagonPos.y
        
        // Determine the primary direction from wagon to player
        let direction: MoveDirection
        if abs(deltaX) > abs(deltaY) {
            direction = deltaX > 0 ? .right : .left
        } else {
            direction = deltaY > 0 ? .up : .down
        }
        
        print("Direction from wagon to player: \(direction.description) (wagon: \(wagonPos), player: \(playerPos))")
        return direction
    }
    
    private func handleDeadEnd() {
        deadEndCounter += 1
        print("Wagon hit dead end (attempt \(deadEndCounter))")
        
        if deadEndCounter >= maxDeadEndAttempts {
            // Force turn around - choose opposite direction or any available direction
            let currentGridPos = worldToGridPosition(position)
            let oppositeDirection = getOppositeDirection(currentDirection)
            
            if let oppositePos = getNextPositionInDirection(from: currentGridPos, direction: oppositeDirection),
               isValidRoadPosition(oppositePos) {
                currentDirection = oppositeDirection
                print("Wagon turning around due to dead end")
            } else {
                // Find any available direction
                let allDirections: [MoveDirection] = [.up, .down, .left, .right]
                for direction in allDirections {
                    if let nextPos = getNextPositionInDirection(from: currentGridPos, direction: direction),
                       isValidRoadPosition(nextPos) {
                        currentDirection = direction
                        print("Wagon changing to direction \(direction) due to dead end")
                        break
                    }
                }
            }
            deadEndCounter = 0
        }
        
        // Try again shortly
        moveTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [weak self] _ in
            guard let self = self, !self.isBlocked else { return }
            self.scheduleNextMove()
        }
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
        
        return nil
    }
    
    private func handleStuckSituation() {
        guard !isBlocked else {
            print("Wagon stuck but blocked - not attempting recovery")
            return
        }
        
        stuckCounter += 1
        
        if stuckCounter >= maxStuckAttempts {
            print("Wagon stuck, forcing direction change")
            let allDirections: [MoveDirection] = [.up, .down, .left, .right]
            currentDirection = allDirections.randomElement() ?? .right
            stuckCounter = 0
        }
        
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
        
        // Check if player is at side of wagon
        let sidePositions = getSidePositions(wagonGridPos)
        for sidePos in sidePositions {
            if playerGridPos.x == sidePos.x && playerGridPos.y == sidePos.y {
                onPlayerInteraction?(self, .playerAtSide)
                return
            }
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
    
    private func getSidePositions(_ wagonPos: CGPoint) -> [CGPoint] {
        let perpendicular = getPerpendicularDirections(to: currentDirection)
        return perpendicular.map { direction in
            let vector = direction.vector
            return CGPoint(
                x: wagonPos.x + vector.dx,
                y: wagonPos.y + vector.dy
            )
        }
    }
    
    private func getPerpendicularDirections(to direction: MoveDirection) -> [MoveDirection] {
        switch direction {
        case .up, .down:
            return [.left, .right]
        case .left, .right:
            return [.up, .down]
        }
    }
    
    func setEscapeMode(escapeDirections: [MoveDirection]) {
        self.isInEscapeMode = true
        self.escapeDirections = escapeDirections
        self.isBlocked = false
        
        scheduleNextMove()
        print("Wagon entering escape mode with directions: \(escapeDirections.map { $0.description })")
    }
    
    func resumeNormalMovement() {
        self.isInEscapeMode = false
        self.escapeDirections = []
        self.isBlocked = false
        
        scheduleNextMove()
        print("Wagon resuming normal movement")
    }
    
    func setBlocked(_ blocked: Bool, reason: String = "") {
        isBlocked = blocked
        if blocked {
            print("Wagon blocked: \(reason)")
            stopAnimation()
            removeAction(forKey: "wagonMovement")
            removeAllActions()
            moveTimer?.invalidate()
            moveTimer = nil
            
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
        // Keeping method for compatibility
    }
    
    deinit {
        moveTimer?.invalidate()
    }
}
