//
//  GameScene.swift
//  KarirKurir
//

import SpriteKit

class GameScene: SKScene {
    
    // MARK: - Properties
    private var player: PlayerNode!
    private var inputController: InputController!
    private var itemManager: ItemManager!
    private var mazeNode: MazeNode!
    private var mazeGenerator: MazeGenerator!
    
    private let tileSize = CGSize(width: 48, height: 48)
    private var currentDirection: MoveDirection = .right
    private var isAutoMoving = false
    private var moveTimer: Timer?
    
    // Collection pause properties
    private var isProcessingCollection = false
    private let collectionPauseDuration: TimeInterval = 0.5 // 0.5 seconds pause
    
    private var score = 0
    private var scoreLabel: SKLabelNode!
    
    //    // Physics Categories
    //    private let playerCategory: UInt32 = 0x1 << 0
    //    private let itemCategory: UInt32 = 0x1 << 1
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        backgroundColor = .darkGray
        setupPhysics()
        setupMaze() // Generate and display the maze first
        setupPlayer()
        setupUI()
        setupInputController()
        setupItemManager() // Must be after maze setup
        startAutoMovement()
    }
    
    // MARK: - Setup
    private func setupPhysics() {
        physicsWorld.gravity = .zero
    }
    
    private func setupMaze() {
        // Calculate maze dimensions based on scene size and tile size
        let mazeWidth = Int(frame.width / tileSize.width)
        let mazeHeight = Int(frame.height / tileSize.height)
        
        mazeGenerator = MazeGenerator(width: mazeWidth, height: mazeHeight)
        mazeNode = MazeNode(mazeGrid: mazeGenerator.grid, tileSize: tileSize)
        
        // Center the maze in the scene
        let mazeTotalWidth = CGFloat(mazeGenerator.width) * tileSize.width
        let mazeTotalHeight = CGFloat(mazeGenerator.height) * tileSize.height
        mazeNode.position = CGPoint(
            x: (frame.width - mazeTotalWidth) / 2,
            y: (frame.height - mazeTotalHeight) / 2
        )
        
        addChild(mazeNode)
    }
    
    private func setupPlayer() {
        player = PlayerNode(tileSize: tileSize)
        // Start player at a valid path, e.g., (1, 1) in grid coordinates
        let startGridPos = CGPoint(x: 1, y: 1)
        player.position = convertGridToScene(gridPoint: startGridPos)
        addChild(player)
    }
    
    private func setupUI() {
        scoreLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: frame.midX, y: frame.maxY - 80)
        updateScore(by: 0)
        addChild(scoreLabel)
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
    
    private func setupItemManager() {
        // Pass the generator and tile size to the manager
        itemManager = ItemManager(scene: self, mazeGenerator: mazeGenerator, tileSize: tileSize)
        itemManager.startSpawningItems(interval: 5.0)
    }
    
    // MARK: - Auto Movement
    private func startAutoMovement() {
        // Don't start if we're processing a collection
        guard !isProcessingCollection else { return }
        
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
        // Don't move if we're processing a collection
        guard isAutoMoving, !isProcessingCollection,
              let playerGridPos = convertSceneToGrid(scenePoint: player.position) else { return }
        
        // Check if the next tile in the current direction is a path
        let nextGridPos = getNextGridPosition(from: playerGridPos, for: currentDirection)
        
        if isPath(at: nextGridPos) {
            let targetScenePos = convertGridToScene(gridPoint: nextGridPos)
            player.move(to: targetScenePos) { [weak self] in
                self?.checkForNearbyItems()
            }
        } else {
            // Hit a wall, stop moving
            stopAutoMovement()
        }
    }
    
    // MARK: - Input Handling
    private func changeDirection(_ direction: MoveDirection) {
        // Don't accept input while processing collection
        guard !isProcessingCollection else { return }
        
        // Only change direction if the new direction is not a wall
        guard let playerGridPos = convertSceneToGrid(scenePoint: player.position) else { return }
        let nextGridPos = getNextGridPosition(from: playerGridPos, for: direction)
        
        if isPath(at: nextGridPos) {
            if currentDirection != direction {
                currentDirection = direction
                player.showDirectionChange()
            }
            
            if !isAutoMoving {
                startAutoMovement()
            }
        }
    }
    
    // MARK: - Collection Logic
    private func checkForNearbyItems() {
        // Don't check for items if already processing a collection
        guard !isProcessingCollection else { return }
        
        guard let playerGridPos = convertSceneToGrid(scenePoint: player.position) else { return }
        
        let adjacentGridPoints = [
            getNextGridPosition(from: playerGridPos, for: .up),
            getNextGridPosition(from: playerGridPos, for: .down),
            getNextGridPosition(from: playerGridPos, for: .left),
            getNextGridPosition(from: playerGridPos, for: .right)
        ]
        
        for node in children {
            guard let item = node as? ItemNode, let itemGridPos = convertSceneToGrid(scenePoint: item.position) else { continue }
            
            if adjacentGridPoints.contains(where: { $0 == itemGridPos }) {
                collect(item: item)
                return
            }
        }
    }
    
    private func collect(item: ItemNode) {
        // Set processing flag to prevent movement and further collections
        isProcessingCollection = true
        
        // Stop current movement
        stopAutoMovement()
        
        print("Collected an item by proximity! Processing collection...")
        updateScore(by: item.category.points)
        
        // Add collection feedback animations
        showCollectionFeedback(at: item.position, points: item.category.points)
        
        // Remove the item
        item.removeFromParent()
        
        // Create a slight pulse effect on the player to show collection
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let pulseSequence = SKAction.sequence([scaleUp, scaleDown])
        player.run(pulseSequence)
        
        // Wait for the pause duration, then resume movement
        DispatchQueue.main.asyncAfter(deadline: .now() + collectionPauseDuration) { [weak self] in
            self?.resumeAfterCollection()
        }
    }
    
    private func resumeAfterCollection() {
        print("Collection processing complete. Resuming movement...")
        isProcessingCollection = false
        
        // Resume automatic movement
        startAutoMovement()
    }
    
    private func showCollectionFeedback(at position: CGPoint, points: Int) {
        // Create a floating points label
        let pointsLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        pointsLabel.text = "+\(points)"
        pointsLabel.fontSize = 20
        pointsLabel.fontColor = .systemGreen
        pointsLabel.position = position
        pointsLabel.zPosition = 100
        addChild(pointsLabel)
        
        // Animate the label floating up and fading out
        let moveUp = SKAction.moveBy(x: 0, y: 40, duration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.8)
        
        let animations = SKAction.group([
            moveUp,
            fadeOut,
            SKAction.sequence([scaleUp, scaleDown])
        ])
        
        pointsLabel.run(animations) {
            pointsLabel.removeFromParent()
        }
        
        // Add a brief screen flash effect
        let flashNode = SKSpriteNode(color: .white, size: frame.size)
        flashNode.alpha = 0.0
        flashNode.position = CGPoint(x: frame.midX, y: frame.midY)
        flashNode.zPosition = 99
        addChild(flashNode)
        
        let flashIn = SKAction.fadeAlpha(to: 0.3, duration: 0.1)
        let flashOut = SKAction.fadeOut(withDuration: 0.2)
        let flashSequence = SKAction.sequence([flashIn, flashOut])
        
        flashNode.run(flashSequence) {
            flashNode.removeFromParent()
        }
    }
    
    private func updateScore(by points: Int) {
        score += points
        scoreLabel.text = "Score: \(score)"
        
        // Add a brief scale animation to the score label
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
        scoreLabel.run(scaleSequence)
    }
    
    //    // MARK: - Collision Handling
    //    func didBegin(_ contact: SKPhysicsContact) {
    //        let firstBody: SKPhysicsBody
    //        let secondBody: SKPhysicsBody
    //
    //        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
    //            firstBody = contact.bodyA
    //            secondBody = contact.bodyB
    //        } else {
    //            firstBody = contact.bodyB
    //            secondBody = contact.bodyA
    //        }
    //
    //        if (firstBody.categoryBitMask == playerCategory) && (secondBody.categoryBitMask == itemCategory) {
    //            if let itemNode = secondBody.node as? ItemNode {
    //                collect(item: itemNode)
    //            }
    //        }
    //    }
    
    // MARK: - Maze and Coordinate Helpers
    
    /// Converts a scene point (pixels) to maze grid coordinates (integers).
    private func convertSceneToGrid(scenePoint: CGPoint) -> CGPoint? {
        guard let mazeNode = mazeNode else { return nil }
        let localPoint = self.convert(scenePoint, to: mazeNode)
        let gridX = Int(round(localPoint.x / tileSize.width))
        let gridY = Int(round(localPoint.y / tileSize.height))
        return CGPoint(x: gridX, y: gridY)
    }
    
    /// Converts maze grid coordinates (integers) to a scene point (pixels).
    private func convertGridToScene(gridPoint: CGPoint) -> CGPoint {
        let localPoint = CGPoint(
            x: gridPoint.x * tileSize.width,
            y: gridPoint.y * tileSize.height
        )
        return self.convert(localPoint, from: mazeNode)
    }
    
    /// Checks if a given grid coordinate is a valid path.
    private func isPath(at gridPoint: CGPoint) -> Bool {
        let x = Int(gridPoint.x)
        let y = Int(gridPoint.y)
        guard x >= 0, x < mazeGenerator.width, y >= 0, y < mazeGenerator.height else {
            return false // Out of bounds
        }
        return mazeGenerator.grid[x][y] == .path
    }
    
    /// Calculates the next grid position based on a direction.
    private func getNextGridPosition(from gridPos: CGPoint, for direction: MoveDirection) -> CGPoint {
        var nextPos = gridPos
        switch direction {
        case .up:    nextPos.y += 1
        case .down:  nextPos.y -= 1
        case .left:  nextPos.x -= 1
        case .right: nextPos.x += 1
        }
        return nextPos
    }
    
    deinit {
        stopAutoMovement()
        itemManager.stopSpawning()
    }
}
