//
//  CatObstacle.swift
//  KarirKurir
//
//  Created by Willas Daniel Rorrong Lumban Tobing on 16/07/25.
//

import SpriteKit

class CatObstacle: SKSpriteNode {
    static let categoryBitMask: UInt32 = 0x1 << 3
    
    private var currentDirection: MoveDirection = .right
    private var animationFrames: [MoveDirection: [SKTexture]] = [:]
    private var isOnRoad: Bool = false
    private var isMoving: Bool = false
    private var gridSize: CGFloat
    private var maze: [[Int]] = []
    private var mazeOffset: CGPoint = .zero
    
    // States
    private var idleTimer: Timer?
    private var moveTimer: Timer?
    private let roadIdleTime: TimeInterval = 2.0 // 2-4 seconds idle on road
    private let grassIdleTime: TimeInterval = 3.0 // 3-5 seconds idle on grass
    private let moveSpeed: TimeInterval = 0.5 // Cat moves slower than player
    
    init(gridSize: CGFloat, maze: [[Int]], mazeOffset: CGPoint) {
        self.gridSize = gridSize
        self.maze = maze
        self.mazeOffset = mazeOffset
        
        // Load default texture
        let defaultTexture = SKTexture(imageNamed: "obstacleCatRight1")
        let catSize = CGSize(width: gridSize * 0.8, height: gridSize * 0.8)
        
        super.init(texture: defaultTexture, color: .clear, size: catSize)
        
        setupTextures()
        setupPhysics()
        startBehavior()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupTextures() {
        // Load animation frames for each direction
        animationFrames[.down] = (1...4).map { SKTexture(imageNamed: "obstacleCatDown\($0)") }
        animationFrames[.up] = (1...4).map { SKTexture(imageNamed: "obstacleCatUp\($0)") }
        animationFrames[.left] = (1...4).map { SKTexture(imageNamed: "obstacleCatLeft\($0)") }
        animationFrames[.right] = (1...4).map { SKTexture(imageNamed: "obstacleCatRight\($0)") }
    }
    
    private func setupPhysics() {
        physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: gridSize * 0.6, height: gridSize * 0.6))
        physicsBody?.isDynamic = false
        physicsBody?.categoryBitMask = CatObstacle.categoryBitMask
        physicsBody?.collisionBitMask = PlayerNode.category
        physicsBody?.contactTestBitMask = PlayerNode.category
    }
    
    private func startBehavior() {
        // Start idle on grass
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
            // If on road, always go back to grass
            moveToGrass()
        } else {
            // If on grass, randomly decide to stay or go to road
            if Bool.random() && canMoveToRoad(from: currentGridPos) {
                moveToRoad()
            } else {
                // Stay on grass, move randomly
                moveRandomlyOnGrass()
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
            startIdleState()
            return
        }
        
        moveToPosition(targetRoadPos) { [weak self] in
            self?.isOnRoad = true
            self?.startIdleState()
        }
    }
    
    private func moveToGrass() {
        let currentGridPos = worldToGridPosition(position)
        let grassPositions = findAdjacentGrassPositions(from: currentGridPos)
        
        guard let targetGrassPos = grassPositions.randomElement() else {
            startIdleState()
            return
        }
        
        moveToPosition(targetGrassPos) { [weak self] in
            self?.isOnRoad = false
            self?.startIdleState()
        }
    }
    
    private func moveRandomlyOnGrass() {
        let currentGridPos = worldToGridPosition(position)
        let grassPositions = findAdjacentGrassPositions(from: currentGridPos)
        
        if let targetGrassPos = grassPositions.randomElement() {
            moveToPosition(targetGrassPos) { [weak self] in
                self?.startIdleState()
            }
        } else {
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
    
    private func findAdjacentGrassPositions(from gridPos: CGPoint) -> [CGPoint] {
        var grassPositions: [CGPoint] = []
        let directions = [
            CGPoint(x: 0, y: 1),   // up
            CGPoint(x: 0, y: -1),  // down
            CGPoint(x: -1, y: 0),  // left
            CGPoint(x: 1, y: 0)    // right
        ]
        
        for direction in directions {
            let checkPos = CGPoint(x: gridPos.x + direction.x, y: gridPos.y + direction.y)
            if isValidPosition(checkPos) && maze[Int(checkPos.y)][Int(checkPos.x)] == 1 {
                grassPositions.append(checkPos)
            }
        }
        
        return grassPositions
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
