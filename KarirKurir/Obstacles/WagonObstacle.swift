//
//  WagonObstacle.swift - SIMPLIFIED VERSION
//  KarirKurir
//
//  Created by Willas Daniel Rorrong Lumban Tobing on 16/07/25.
//

import SpriteKit

class WagonObstacle: SKSpriteNode {
    static let categoryBitMask: UInt32 = 0x1 << 4
    
    private var currentDirection: MoveDirection = .right
    private var animationFrames: [MoveDirection: [SKTexture]] = [:]
    private var isOnRoad: Bool = false
    private var isMoving: Bool = false
    private var gridSize: CGFloat
    private var maze: [[Int]] = []
    private var mazeOffset: CGPoint = .zero
    
    // Store the randomized variant number for this wagon (1-4)
    private let textureVariant: Int
    
    // States - same as CatObstacle
    private var idleTimer: Timer?
    private var moveTimer: Timer?
    private let roadIdleTime: TimeInterval = 2.0 // 2-4 seconds idle on road
    private let grassIdleTime: TimeInterval = 3.0 // 3-5 seconds idle on grass
    private let moveSpeed: TimeInterval = 0.8 // Wagon moves slower than cat
    
    // Reference to game scene for checking accessible positions
    private weak var gameScene: GameScene?
    
    init(gridSize: CGFloat, maze: [[Int]], mazeOffset: CGPoint, gameScene: GameScene) {
        self.gridSize = gridSize
        self.maze = maze
        self.mazeOffset = mazeOffset
        self.gameScene = gameScene
        
        self.textureVariant = Int.random(in: 1...2)
        
        // Load default texture
        let defaultTexture = SKTexture(imageNamed: "obstacleWagonRight1_\(textureVariant)")
        let wagonSize = CGSize(width: gridSize * 1.2, height: gridSize * 1.2)
        
        super.init(texture: defaultTexture, color: .clear, size: wagonSize)
        
        setupTextures()
        setupPhysics()
        startBehavior()
        
        print("Wagon created with texture variant \(textureVariant)")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupTextures() {
        // Load animation frames for each direction
        animationFrames[.down] = (1...4).map { SKTexture(imageNamed: "obstacleWagonDown\($0)_\(textureVariant)") }
        animationFrames[.up] = (1...4).map { SKTexture(imageNamed: "obstacleWagonUp\($0)_\(textureVariant)") }
        animationFrames[.left] = (1...4).map { SKTexture(imageNamed: "obstacleWagonLeft\($0)_\(textureVariant)") }
        animationFrames[.right] = (1...4).map { SKTexture(imageNamed: "obstacleWagonRight\($0)_\(textureVariant)") }

        print("Wagon loaded textures for variant \(textureVariant)")
    }
    
    private func setupPhysics() {
        physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: gridSize * 0.8, height: gridSize * 0.8))
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = WagonObstacle.categoryBitMask
        physicsBody?.collisionBitMask = PlayerNode.category
        physicsBody?.contactTestBitMask = PlayerNode.category
    }
    
    private func startBehavior() {
        // Start idle on grass (like cat)
        isOnRoad = false
        startIdleState()
    }
    
    private func startIdleState() {
        stopMoving()
        
        let idleTime = isOnRoad ?
        TimeInterval.random(in: 2.0...4.0) :
        TimeInterval.random(in: 3.0...5.0)
        
        idleTimer = Timer.scheduledTimer(withTimeInterval: idleTime, repeats: false) { [weak self] _ in
            self?.decideNextAction()
        }
        
        // Play idle animation
        playIdleAnimation()
    }
    
    private func decideNextAction() {
        let currentGridPos = worldToGridPosition(position)
        
        if isOnRoad {
            // If on road, always go back to accessible grass
            moveToAccessibleGrass()
        } else {
            // If on grass, randomly decide to stay or go to road
            if Bool.random() && canMoveToRoad(from: currentGridPos) {
                moveToRoad()
            } else {
                // Stay on grass, move randomly (but only to accessible grass)
                moveRandomlyOnAccessibleGrass()
            }
        }
    }
    
    private func canMoveToRoad(from gridPos: CGPoint) -> Bool {
        // Check if there's a road position adjacent to current grass position
        let directions = [
            CGPoint(x: 0, y: 1),   // up
            CGPoint(x: 0, y: -1),  // down
            CGPoint(x: -1, y: 0),  // left
            CGPoint(x: 1, y: 0)    // right
        ]
        
        for direction in directions {
            let checkPos = CGPoint(x: gridPos.x + direction.x, y: gridPos.y + direction.y)
            if isValidPosition(checkPos) && maze[Int(checkPos.y)][Int(checkPos.x)] == 0 {
                return true
            }
        }
        return false
    }
    
    private func moveToRoad() {
        let currentGridPos = worldToGridPosition(position)
        let roadPositions = findAdjacentRoadPositions(from: currentGridPos)
        
        guard let targetRoadPos = roadPositions.randomElement() else {
            print("Wagon: No adjacent road found, staying on grass")
            startIdleState()
            return
        }
        
        moveToPosition(targetRoadPos) { [weak self] in
            self?.isOnRoad = true
            self?.startIdleState()
        }
    }
    
    private func moveToAccessibleGrass() {
        let currentGridPos = worldToGridPosition(position)
        let grassPositions = findAdjacentAccessibleGrassPositions(from: currentGridPos)
        
        guard let targetGrassPos = grassPositions.randomElement() else {
            print("Wagon: No accessible grass found from road, staying on road")
            startIdleState()
            return
        }
        
        moveToPosition(targetGrassPos) { [weak self] in
            self?.isOnRoad = false
            self?.startIdleState()
        }
    }
    
    private func moveRandomlyOnAccessibleGrass() {
        let currentGridPos = worldToGridPosition(position)
        let grassPositions = findAdjacentAccessibleGrassPositions(from: currentGridPos)
        
        if let targetGrassPos = grassPositions.randomElement() {
            moveToPosition(targetGrassPos) { [weak self] in
                self?.startIdleState()
            }
        } else {
            print("Wagon: No accessible grass for random movement, staying put")
            startIdleState()
        }
    }
    
    private func findAdjacentRoadPositions(from gridPos: CGPoint) -> [CGPoint] {
        var roadPositions: [CGPoint] = []
        let directions = [
            CGPoint(x: 0, y: 1),   // up
            CGPoint(x: 0, y: -1),  // down
            CGPoint(x: -1, y: 0),  // left
            CGPoint(x: 1, y: 0)    // right
        ]
        
        for direction in directions {
            let checkPos = CGPoint(x: gridPos.x + direction.x, y: gridPos.y + direction.y)
            if isValidPosition(checkPos) && maze[Int(checkPos.y)][Int(checkPos.x)] == 0 {
                roadPositions.append(checkPos)
            }
        }
        
        return roadPositions
    }
    
    private func findAdjacentAccessibleGrassPositions(from gridPos: CGPoint) -> [CGPoint] {
        var grassPositions: [CGPoint] = []
        let directions = [
            CGPoint(x: 0, y: 1),   // up
            CGPoint(x: 0, y: -1),  // down
            CGPoint(x: -1, y: 0),  // left
            CGPoint(x: 1, y: 0)    // right
        ]
        
        for direction in directions {
            let checkPos = CGPoint(x: gridPos.x + direction.x, y: gridPos.y + direction.y)
            if isValidPosition(checkPos) &&
               maze[Int(checkPos.y)][Int(checkPos.x)] == 1 &&
               isAccessibleGrassPosition(checkPos) {
                grassPositions.append(checkPos)
            }
        }
        
        print("Wagon: Found \(grassPositions.count) accessible grass positions from \(gridPos)")
        return grassPositions
    }
    
    // SIMPLIFIED: Use GameScene to check if position is accessible
    private func isAccessibleGrassPosition(_ gridPos: CGPoint) -> Bool {
        guard let gameScene = gameScene else {
            print("Wagon: No game scene reference")
            return false
        }
        
        let row = Int(gridPos.y)
        let col = Int(gridPos.x)
        
        let isAccessible = gameScene.isPositionAccessibleToWagons(row: row, col: col)
        print("Wagon: Position (\(row),\(col)) accessible: \(isAccessible)")
        return isAccessible
    }
    
    private func moveToPosition(_ gridPos: CGPoint, completion: @escaping () -> Void) {
        let worldPos = gridToWorldPosition(gridPos)
        updateDirection(to: worldPos)
        
        isMoving = true
        playWalkAnimation()
        
        let moveAction = SKAction.move(to: worldPos, duration: moveSpeed)
        moveAction.timingMode = .easeInEaseOut
        
        let completeAction = SKAction.run {
            completion()
        }
        
        run(SKAction.sequence([moveAction, completeAction]))
        print("Wagon: Moving to position \(gridPos) (world: \(worldPos))")
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
    
    private func playWalkAnimation() {
        guard let frames = animationFrames[currentDirection] else { return }
        
        let animation = SKAction.animate(with: frames, timePerFrame: 0.15)
        let repeatAction = SKAction.repeatForever(animation)
        run(repeatAction, withKey: "walkAnimation")
    }
    
    private func playIdleAnimation() {
        removeAction(forKey: "walkAnimation")
        
        guard let frames = animationFrames[currentDirection] else { return }
        
        // Use first frame for idle or create a slower animation
        let idleAnimation = SKAction.animate(with: [frames[0], frames[1]], timePerFrame: 0.8)
        let repeatAction = SKAction.repeatForever(idleAnimation)
        run(repeatAction, withKey: "idleAnimation")
    }
    
    private func stopMoving() {
        isMoving = false
        removeAction(forKey: "walkAnimation")
        removeAction(forKey: "idleAnimation")
    }
    
    private func isValidPosition(_ gridPos: CGPoint) -> Bool {
        let row = Int(gridPos.y)
        let col = Int(gridPos.x)
        return row >= 0 && row < maze.count && col >= 0 && col < maze[0].count
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
    
    deinit {
        idleTimer?.invalidate()
        moveTimer?.invalidate()
    }
}

// MARK: - Extensions for compatibility

extension WagonObstacle {
    // Keep these methods for compatibility with existing code
    func setBlocked(_ blocked: Bool, reason: String = "") {
        print("WagonObstacle: setBlocked called but ignored (cat-like behavior)")
    }
    
    func isCurrentlyBlocked() -> Bool {
        return false // Never blocked in cat-like behavior
    }
    
    func getCurrentDirection() -> MoveDirection {
        return currentDirection
    }
    
    func getGridPosition() -> CGPoint {
        return worldToGridPosition(position)
    }
    
    func resumeNormalMovement() {
        print("WagonObstacle: resumeNormalMovement called (already in cat-like behavior)")
    }
    
    func setEscapeMode(escapeDirections: [MoveDirection]) {
        print("WagonObstacle: setEscapeMode called but ignored (cat-like behavior)")
    }
}
