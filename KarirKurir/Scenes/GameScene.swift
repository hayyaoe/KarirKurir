//
//  GameScene.swift
//  KarirKurir
//
//  Created by Mahardika Putra Wardhana on 09/07/25.
//

import SpriteKit

class GameScene: SKScene {
    // MARK: - Game Elements

    var player: PlayerNode!

    // get current maze -> render walls -> render destinations
    var currentMaze: [[Int]] = []
    var walls: [SKSpriteNode] = []
    var items: [ItemNode] = [] // Changed from destinations to items
    var itemGridPositions: [(row: Int, col: Int)] = [] // Changed from destinationGridPositions
    var pathTiles: [SKSpriteNode] = []
    var collectedItems: Int = 0
    var expiredItems: Int = 0
    var holes: [SKSpriteNode] = [] // Add holes array

    // Next Object
    var nextMaze: [[Int]] = []
    var nextWalls: [[SKSpriteNode]] = []
    var nextItems: [[ItemNode]] = [] // Changed from nextDestinations

    // MARK: - Game State

    var currentDirection: Direction = .right
    var nextDirection: Direction?
    var score: Int = 0
    var level: Int = 1
    var health: Int = 3
    var isTransitioning: Bool = false // Add transition state flag
    var isGameOver: Bool = false
    var isCollecting: Bool = false // Add collecting state flag
    var isOnHole: Bool = false // Track if player is on a hole

    // MARK: - UI

    var scoreLabel: SKLabelNode!
    var levelLabel: SKLabelNode!
    var healthLabel: SKLabelNode!

    // MARK: - Constants

    let playerSpeed: CGFloat = 100.0
    var gridSize: CGFloat = 30.0 // This will be calculated dynamically

    // MARK: - Maze dimensions
    let mazeWidth: Int = 20
    let mazeHeight: Int = 11

    // MARK: - Direction Enum

    enum Direction {
        case up, down, left, right

        var vector: CGVector {
            switch self {
            case .up: return CGVector(dx: 0, dy: 1)
            case .down: return CGVector(dx: 0, dy: -1)
            case .left: return CGVector(dx: -1, dy: 0)
            case .right: return CGVector(dx: 1, dy: 0)
            }
        }
    }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        // Calculate grid size based on screen dimensions
        calculateOptimalGridSize()
        
        setupGestures()
        currentMaze = getMazeLayout(for: level)
        
        // Setup initial player position first
        setupInitialPlayerPosition()
        
        // Then setup maze with player position known
        setupMaze(maze: currentMaze)
        
        startPlayerMovement()
        setupUI()
        physicsWorld.contactDelegate = self
    }

    func setupInitialPlayerPosition() {
        let mazePixelWidth = CGFloat(mazeWidth) * gridSize
        let mazePixelHeight = CGFloat(mazeHeight) * gridSize
        let offsetX = (size.width - mazePixelWidth) / 2
        let offsetY = (size.height - mazePixelHeight) / 2
        
        // Ensure maze is not empty
        guard !currentMaze.isEmpty, !currentMaze[0].isEmpty else {
            print("Maze is empty, using fallback position")
            let fallbackPos = CGPoint(x: offsetX + gridSize * 1.5, y: offsetY + gridSize * 1.5)
            setupPlayer(position: fallbackPos)
            return
        }
        
        // Find the first open path position from the bottom-left area
        for row in stride(from: currentMaze.count - 2, to: 0, by: -1) {
            for col in 1 ..< min(5, currentMaze[row].count) { // Check only first few columns
                if row >= 0 && row < currentMaze.count &&
                   col >= 0 && col < currentMaze[row].count &&
                   currentMaze[row][col] == 0 {
                    let pos = CGPoint(
                        x: offsetX + CGFloat(col) * gridSize + gridSize/2,
                        y: offsetY + CGFloat(currentMaze.count - row - 1) * gridSize + gridSize/2
                    )
                    setupPlayer(position: pos)
                    return
                }
            }
        }
        
        // Fallback to a safe default position
        let fallbackPos = CGPoint(x: offsetX + gridSize * 1.5, y: offsetY + gridSize * 1.5)
        setupPlayer(position: fallbackPos)
    }

    // MARK: - Dynamic Sizing
    
    func calculateOptimalGridSize() {
        // For landscape orientation, ensure we use the correct dimensions
        let sceneWidth = size.width
        let sceneHeight = size.height
        
        print("Scene size in calculateOptimalGridSize: \(sceneWidth) x \(sceneHeight)")
        
        // Calculate grid size to fit the screen optimally
        let availableWidth = sceneWidth * 0.90 // Leave 10% margin
        let availableHeight = sceneHeight * 0.80 // Leave 20% margin for UI
        
        let gridSizeByWidth = availableWidth / CGFloat(mazeWidth)
        let gridSizeByHeight = availableHeight / CGFloat(mazeHeight)
        
        // Use the smaller value to ensure the maze fits on screen
        gridSize = min(gridSizeByWidth, gridSizeByHeight)
        
        // Ensure minimum grid size for playability
        gridSize = max(gridSize, 35.0)
        
        print("Available size: \(availableWidth) x \(availableHeight)")
        print("Grid size by width: \(gridSizeByWidth), by height: \(gridSizeByHeight)")
        print("Final grid size: \(gridSize)")
    }

    // MARK: - Setup Functions

    func setupPlayer(position: CGPoint) {
        // Remove existing player if it exists
        player?.removeFromParent()
        
        player = PlayerNode(tileSize: CGSize(width: gridSize, height: gridSize))
        player.position = position
        addChild(player)
        
        print("Player setup at position: \(position)")
    }

    func setupUI() {
        // Position UI elements relative to screen size
        let margin: CGFloat = 20
        scoreLabel = createLabel(text: "Score: 0", position: CGPoint(x: margin + 100, y: size.height - 50))
        levelLabel = createLabel(text: "Level: 1", position: CGPoint(x: margin + 250, y: size.height - 50))
        healthLabel = createLabel(text: "❤️ \(health)", position: CGPoint(x: margin + 400, y: size.height - 50))
        addChild(scoreLabel)
        addChild(levelLabel)
        addChild(healthLabel)
    }

    func createLabel(text: String, position: CGPoint) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Arial-BoldMT")
        label.text = text
        label.fontSize = 20
        label.fontColor = .white
        label.position = position
        return label
    }

    func setupGestures() {
        let directions: [UISwipeGestureRecognizer.Direction] = [.up, .down, .left, .right]
        for dir in directions {
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
            swipe.direction = dir
            view?.addGestureRecognizer(swipe)
        }
    }

    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        // Ignore input during level transitions, game over, or collecting
        guard !isTransitioning && !isGameOver && !isCollecting else {
            print("Input ignored during transition, game over, or collecting")
            return
        }
        
        switch gesture.direction {
        case .up: nextDirection = .up
        case .down: nextDirection = .down
        case .left: nextDirection = .left
        case .right: nextDirection = .right
        default: break
        }
    }

    func setupMaze(maze: [[Int]]) {
        walls.forEach { $0.removeFromParent() }
        items.forEach { $0.removeFromParent() } // Changed from destinations
        pathTiles.forEach { $0.removeFromParent() }
        holes.forEach { $0.removeFromParent() } // Remove holes

        walls.removeAll()
        items.removeAll() // Changed from destinations
        pathTiles.removeAll()
        holes.removeAll() // Clear holes array

        let wallColor = [UIColor.blue, .purple, .red, .green, .orange, .cyan][(level - 1) % 6]
        
        // Center the maze on screen
        let mazePixelWidth = CGFloat(mazeWidth) * gridSize
        let mazePixelHeight = CGFloat(mazeHeight) * gridSize
        let offsetX = (size.width - mazePixelWidth) / 2
        let offsetY = (size.height - mazePixelHeight) / 2

        // First, determine item positions on walls
        setupItemsOnWalls(maze: maze, offsetX: offsetX, offsetY: offsetY)

        for (row, rowData) in maze.enumerated() {
            for (col, cell) in rowData.enumerated() {
                let position = CGPoint(
                    x: offsetX + CGFloat(col) * gridSize + gridSize/2,
                    y: offsetY + CGFloat(maze.count - row - 1) * gridSize + gridSize/2
                )

                if cell == 1 {
                    let isOverDestination = itemGridPositions.contains { $0.row == row && $0.col == col }

                    let textureName: String
                    if isOverDestination {
                        textureName = randomHouseAsset() // Use house textures for walls with items
                    } else {
                        textureName = randomWallAsset()
                    }

                    let wallTexture = SKTexture(imageNamed: textureName)
                    let wall = SKSpriteNode(texture: wallTexture, size: CGSize(width: gridSize, height: gridSize))
                    wall.position = position
                    
                    // Fix black background issue for house textures
                    if isOverDestination {
                        wall.colorBlendFactor = 0.0
                        wall.color = .clear
                        // Try to remove black backgrounds by setting blend mode
                        wall.blendMode = .alpha
                        
                    }
                    
                    wall.physicsBody = SKPhysicsBody(rectangleOf: wall.size)
                    wall.physicsBody?.categoryBitMask = 2
                    wall.physicsBody?.isDynamic = false
                    walls.append(wall)
                    addChild(wall)
                }
            }
        }
        setupPathTiles(maze: maze, offsetX: offsetX, offsetY: offsetY)
        
        // Add holes based on level
        setupHoles(maze: maze, offsetX: offsetX, offsetY: offsetY)

        nextMaze = getMazeLayout(for: level + 1)
    }

    func setupItemsOnWalls(maze: [[Int]], offsetX: CGFloat, offsetY: CGFloat, count: Int = 10) {
        itemGridPositions.removeAll()
        
        // Find all wall positions that are accessible (adjacent to paths)
        var accessibleWallPositions: [CGPoint] = []
        
        for row in 1..<maze.count - 1 {
            for col in 1..<maze[row].count - 1 {
                if maze[row][col] == 1 { // This is a wall
                    // Check if this wall is adjacent to at least one path
                    let adjacentPositions = [
                        (row - 1, col), // up
                        (row + 1, col), // down
                        (row, col - 1), // left
                        (row, col + 1)  // right
                    ]
                    
                    var hasAdjacentPath = false
                    for (adjRow, adjCol) in adjacentPositions {
                        if adjRow >= 0 && adjRow < maze.count &&
                           adjCol >= 0 && adjCol < maze[adjRow].count &&
                           maze[adjRow][adjCol] == 0 { // Adjacent cell is a path
                            hasAdjacentPath = true
                            break
                        }
                    }
                    
                    if hasAdjacentPath {
                        accessibleWallPositions.append(CGPoint(x: col, y: row))
                    }
                }
            }
        }
        
        // Select random wall positions for items
        let selectedPositions = Array(accessibleWallPositions.shuffled().prefix(count))
        
        for wallPos in selectedPositions {
            let row = Int(wallPos.y)
            let col = Int(wallPos.x)
            itemGridPositions.append((row: row, col: col))
            
            // Create ItemNode
            let randomTime = Int.random(in: 16...25)
            let itemSize = CGSize(width: gridSize * 0.6, height: gridSize * 0.6)
            let item = ItemNode(size: itemSize, initialTime: randomTime)
            
            // Position item on top of the wall
            let itemPosition = CGPoint(
                x: offsetX + CGFloat(col) * gridSize + gridSize/2,
                y: offsetY + CGFloat(maze.count - row - 1) * gridSize + gridSize/2
            )
            item.position = itemPosition
            item.zPosition = 15 // Higher than walls to appear on top
            
            // Set up physics for item collection
            item.physicsBody?.categoryBitMask = ItemNode.categoryBitMask
            item.physicsBody?.contactTestBitMask = PlayerNode.category
            item.physicsBody?.collisionBitMask = 0
            
            // Handle item expiration
            item.onTimerExpired = { [weak self, weak item] in
                guard let self = self, let item = item, !self.isTransitioning, !self.isGameOver else { return }
                if let index = self.items.firstIndex(of: item) {
                    self.items.remove(at: index)
                }
                item.removeFromParent()
                self.expiredItems += 1
                
                print("Item expired, \(self.items.count) items remaining, \(self.expiredItems) expired")
                
                // Check if all items are gone (collected or expired)
                if self.items.isEmpty && !self.isTransitioning {
                    self.checkLevelCompletion()
                }
            }
            
            addChild(item)
            items.append(item)
        }
        
        print("Setup \(items.count) items on walls")
    }

    func setupPathTiles(maze: [[Int]], offsetX: CGFloat, offsetY: CGFloat) {
        for row in 1 ..< maze.count - 1 {
            for col in 1 ..< maze[row].count - 1 {
                if let tileType = detectPathTileType(row: row, col: col, in: maze) {
                    let spriteName = spriteNameFor(tileType: tileType)
                    let tileTexture = SKTexture(imageNamed: spriteName)
                    let tileNode = SKSpriteNode(texture: tileTexture, size: CGSize(width: gridSize, height: gridSize))
                    tileNode.position = CGPoint(
                        x: offsetX + CGFloat(col) * gridSize + gridSize/2,
                        y: offsetY + CGFloat(maze.count - row - 1) * gridSize + gridSize/2
                    )
                    tileNode.zPosition = -1
                    addChild(tileNode)
                    pathTiles.append(tileNode)
                }
            }
        }
    }

    // MARK: - Player Movement

    func startPlayerMovement() {
        removeAction(forKey: "playerMovement")
        let movementAction = SKAction.repeatForever(.sequence([
            .run { [weak self] in self?.updatePlayerMovement() },
            .wait(forDuration: 0.02)
        ]))
        run(movementAction, withKey: "playerMovement")
    }

    var isMoving = false

    func updatePlayerMovement() {
        // Don't move during transitions, game over, collecting, or if already moving
        guard !isTransitioning && !isGameOver && !isCollecting && !isMoving else { return }

        if let next = nextDirection, canMove(in: next) {
            currentDirection = next
            nextDirection = nil
        }

        if canMove(in: currentDirection) {
            let vector = currentDirection.vector
            let targetPosition = CGPoint(
                x: player.position.x + vector.dx * gridSize,
                y: player.position.y + vector.dy * gridSize
            )

            isMoving = true
            
            // Check if player will be on a hole at target position and adjust speed
            let willBeOnHole = holes.contains { hole in
                let distance = hypot(targetPosition.x - hole.position.x, targetPosition.y - hole.position.y)
                return distance < gridSize * 0.5
            }
            
            // Adjust movement duration based on hole presence
            let moveDuration = willBeOnHole ? 0.36 : 0.18 // 2x slower on holes
            
            // Debug logging for hole status
            if willBeOnHole != isOnHole {
                print("Moving to \(targetPosition) - \(willBeOnHole ? "entering hole (slow)" : "normal speed")")
            }
            
            // Use the player's move function with custom duration
            player.moveWithCustomDuration(to: targetPosition, duration: moveDuration) { [weak self] in
                self?.isMoving = false
                self?.checkIfPlayerOnHole() // Check hole status after movement
                self?.checkForItemCollection() // Check for item collection after each move
            }
        }
    }
    
    func collectItem(at index: Int) {
        // This function is kept for backward compatibility with single item collection
        collectMultipleItems(at: [index])
    }

    func canMove(in direction: Direction) -> Bool {
        let vector = direction.vector
        let future = CGPoint(
            x: player.position.x + vector.dx * (gridSize/2 + 5),
            y: player.position.y + vector.dy * (gridSize/2 + 5)
        )

        // Calculate maze bounds
        let mazePixelWidth = CGFloat(mazeWidth) * gridSize
        let mazePixelHeight = CGFloat(mazeHeight) * gridSize
        let offsetX = (size.width - mazePixelWidth) / 2
        let offsetY = (size.height - mazePixelHeight) / 2
        
        let mazeMinX = offsetX
        let mazeMaxX = offsetX + mazePixelWidth
        let mazeMinY = offsetY
        let mazeMaxY = offsetY + mazePixelHeight

        // Check if future position is within maze bounds
        if future.x < mazeMinX || future.x > mazeMaxX || future.y < mazeMinY || future.y > mazeMaxY {
            return false
        }

        // Check collision with walls only (holes no longer block movement)
        return !walls.contains(where: { $0.frame.contains(future) })
    }
    
    func checkIfPlayerOnHole() {
        let wasOnHole = isOnHole
        isOnHole = false
        
        // Check if player is currently on any hole
        for hole in holes {
            let distance = hypot(player.position.x - hole.position.x, player.position.y - hole.position.y)
            if distance < gridSize * 0.5 {
                isOnHole = true
                break
            }
        }
        
        // Log state change for debugging
        if wasOnHole != isOnHole {
            print("Player \(isOnHole ? "entered" : "left") hole - movement speed \(isOnHole ? "slowed" : "normal")")
        }
    }

    // MARK: - Item Collection

    func checkForItemCollection() {
        guard !isGameOver && !isCollecting else { return }
        
        // Calculate maze offset for proper grid positioning
        let mazePixelWidth = CGFloat(mazeWidth) * gridSize
        let mazePixelHeight = CGFloat(mazeHeight) * gridSize
        let offsetX = (size.width - mazePixelWidth) / 2
        let offsetY = (size.height - mazePixelHeight) / 2
        
        // Convert player position to grid coordinates
        let playerGridX = Int((player.position.x - offsetX) / gridSize)
        let playerGridY = Int((player.position.y - offsetY) / gridSize)
        
        // Collect from ALL adjacent items automatically
        var itemsToCollect: [Int] = []
        
        for (index, item) in items.enumerated() {
            // Convert item position to grid coordinates
            let itemGridX = Int((item.position.x - offsetX) / gridSize)
            let itemGridY = Int((item.position.y - offsetY) / gridSize)
            
            // Check if player is EXACTLY adjacent to the item (no diagonals, direct neighbors only)
            let deltaX = playerGridX - itemGridX
            let deltaY = playerGridY - itemGridY
            
            // Only allow collection if player is directly adjacent (not diagonal)
            let isDirectlyAdjacent = (abs(deltaX) == 1 && deltaY == 0) || (deltaX == 0 && abs(deltaY) == 1)
            
            if isDirectlyAdjacent {
                itemsToCollect.append(index)
            }
        }
        
        // Collect all adjacent items automatically
        if !itemsToCollect.isEmpty {
            collectMultipleItems(at: itemsToCollect)
        }
    }

//    func collectItem(at index: Int) {
//        guard index < items.count, !isTransitioning, !isGameOver, !isCollecting else { return }
//        
//        // Start collecting process - this stops player movement
//        isCollecting = true
//        stopPlayerMovement()
//        
//        let item = items[index]
//        
//        // Calculate score based on item category
//        let points = item.category.points * 10 * level
//        score += points
//        scoreLabel.text = "Score: \(score)"
//        
//        // Show collection feedback
//        let label = SKLabelNode(fontNamed: "Arial-BoldMT")
//        label.text = "+\(points)"
//        label.fontSize = 20
//        label.fontColor = item.category.color
//        label.position = CGPoint(x: item.position.x, y: item.position.y + 30)
//        addChild(label)
//        
//        // Add collection effect
//        let collectEffect = SKShapeNode(circleOfRadius: gridSize * 0.5)
//        collectEffect.strokeColor = item.category.color
//        collectEffect.lineWidth = 3
//        collectEffect.fillColor = .clear
//        collectEffect.position = item.position
//        collectEffect.zPosition = 20
//        addChild(collectEffect)
//        
//        // Player collection animation - make player "glow" during collection
//        let playerGlow = SKShapeNode(rectOf: CGSize(width: gridSize + 4, height: gridSize + 4), cornerRadius: 12)
//        playerGlow.fillColor = .clear
//        playerGlow.strokeColor = item.category.color
//        playerGlow.lineWidth = 3
//        playerGlow.position = player.position
//        playerGlow.zPosition = player.zPosition + 1
//        addChild(playerGlow)
//        
//        // Animate collection effect
//        let expandAction = SKAction.scale(to: 2.0, duration: 0.3)
//        let fadeAction = SKAction.fadeOut(withDuration: 0.3)
//        let removeEffect = SKAction.removeFromParent()
//        let effectSequence = SKAction.sequence([SKAction.group([expandAction, fadeAction]), removeEffect])
//        collectEffect.run(effectSequence)
//        
//        // Animate player glow
//        let glowPulse = SKAction.sequence([
//            SKAction.scale(to: 1.1, duration: 0.1),
//            SKAction.scale(to: 1.0, duration: 0.1)
//        ])
//        let repeatPulse = SKAction.repeat(glowPulse, count: 2)
//        let fadeGlow = SKAction.fadeOut(withDuration: 0.2)
//        let removeGlow = SKAction.removeFromParent()
//        let glowSequence = SKAction.sequence([repeatPulse, fadeGlow, removeGlow])
//        playerGlow.run(glowSequence)
//        
//        // Animate the score label
//        let moveUp = SKAction.moveBy(x: 0, y: 30, duration: 0.8)
//        let fadeOut = SKAction.fadeOut(withDuration: 0.8)
//        let remove = SKAction.removeFromParent()
//        let sequence = SKAction.sequence([SKAction.group([moveUp, fadeOut]), remove])
//        label.run(sequence)
//        
//        // Remove the item and track collection
//        item.removeFromParent()
//        items.remove(at: index)
//        collectedItems += 1
//        
//        print("Collected item from house, \(items.count) items remaining, \(collectedItems) collected")
//        
//        // Wait 0.5 seconds before allowing movement again
//        run(SKAction.sequence([
//            SKAction.wait(forDuration: 0.5),
//            SKAction.run { [weak self] in
//                self?.isCollecting = false
//                // Only restart movement if we're not transitioning or game over
//                if let self = self, !self.isTransitioning && !self.isGameOver {
//                    self.startPlayerMovement()
//                    
//                    // Check if all items are collected
//                    if self.items.isEmpty {
//                        self.checkLevelCompletion()
//                    }
//                }
//            }
//        ]))
//    }

    // MARK: - Game Progress

    func nextLevel() {
        // IMMEDIATELY stop all player movement and input processing
        isTransitioning = true
        print("Starting level transition to level \(level + 1)")
        stopPlayerMovement()
        clearInputState()
        
        level += 1
        levelLabel.text = "Level: \(level)"

        // Show level complete message
        let label = SKLabelNode(fontNamed: "Arial-BoldMT")
        label.text = "Level Complete!"
        label.fontSize = 25
        label.fontColor = .yellow
        label.position = CGPoint(x: size.width/2, y: size.height/2 + 100)
        addChild(label)
        label.run(.sequence([.fadeOut(withDuration: 1.5), .removeFromParent()]))

        run(.sequence([
            .wait(forDuration: 0.5),
            .run { [weak self] in
                self?.setupNewLevel()
            }
        ]))
    }
    
    func setupNewLevel() {
        print("Setting up new level \(level)")
        
        // Reset all movement state
        isMoving = false
        isCollecting = false
        isOnHole = false
        currentDirection = .right
        nextDirection = nil
        
        // Reset item counters for the new level
        collectedItems = 0
        expiredItems = 0
        
        // Setup new maze
        currentMaze = nextMaze.isEmpty ? getMazeLayout(for: level) : nextMaze
        setupMaze(maze: currentMaze)
        findSafeStartingPosition()
        
        // Small delay before restarting movement to ensure everything is settled
        run(.sequence([
            .wait(forDuration: 0.1),
            .run { [weak self] in
                self?.startPlayerMovement()
                self?.isTransitioning = false // Re-enable input
                print("Level transition complete - input and movement re-enabled")
            }
        ]))
    }
    
    func stopPlayerMovement() {
        removeAction(forKey: "playerMovement")
        player?.removeAllActions()
        isMoving = false
        print("Player movement stopped")
    }
    
    func checkLevelCompletion() {
        guard !isTransitioning && !isGameOver else { return }
        
        let totalItemsThisLevel = collectedItems + expiredItems
        print("Level completion check: \(collectedItems) collected, \(expiredItems) expired, total: \(totalItemsThisLevel)")
        
        // If any items expired, lose health
        if expiredItems > 0 {
            health -= 1
            healthLabel.text = "❤️ \(health)"
            
            // Show health loss feedback
            showHealthLossMessage()
            
            print("Health lost! Current health: \(health)")
            
            // Check for game over
            if health <= 0 {
                gameOver()
                return
            }
        }
        
        // Reset counters for next level
        collectedItems = 0
        expiredItems = 0
        
        // Proceed to next level
        print("Proceeding to next level")
        nextLevel()
    }
    
    func showHealthLossMessage() {
        let label = SKLabelNode(fontNamed: "Arial-BoldMT")
        label.text = "Health Lost! ❤️ \(health)"
        label.fontSize = 22
        label.fontColor = .red
        label.position = CGPoint(x: size.width/2, y: size.height/2)
        addChild(label)
        
        // Animate the health loss message
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.2)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([scaleUp, scaleDown, fadeOut, remove])
        label.run(sequence)
    }
    
    func gameOver() {
        isGameOver = true
        stopPlayerMovement()
        clearInputState()
        
        print("Game Over!")
        
        // Create game over modal
        createGameOverModal()
    }
    
    func createGameOverModal() {
        // Create semi-transparent background
        let overlay = SKShapeNode(rect: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        overlay.fillColor = SKColor.black
        overlay.alpha = 0.7
        overlay.zPosition = 100
        addChild(overlay)
        
        // Create modal background
        let modalWidth: CGFloat = 400
        let modalHeight: CGFloat = 300
        let modal = SKShapeNode(rectOf: CGSize(width: modalWidth, height: modalHeight), cornerRadius: 20)
        modal.fillColor = SKColor.darkGray
        modal.strokeColor = SKColor.white
        modal.lineWidth = 3
        modal.position = CGPoint(x: size.width/2, y: size.height/2)
        modal.zPosition = 101
        addChild(modal)
        
        // Game Over title
        let titleLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        titleLabel.text = "GAME OVER"
        titleLabel.fontSize = 32
        titleLabel.fontColor = .red
        titleLabel.position = CGPoint(x: 0, y: 60)
        titleLabel.zPosition = 102
        modal.addChild(titleLabel)
        
        // Final score
        let scoreText = SKLabelNode(fontNamed: "Arial")
        scoreText.text = "Final Score: \(score)"
        scoreText.fontSize = 20
        scoreText.fontColor = .white
        scoreText.position = CGPoint(x: 0, y: 20)
        scoreText.zPosition = 102
        modal.addChild(scoreText)
        
        // Level reached
        let levelText = SKLabelNode(fontNamed: "Arial")
        levelText.text = "Level Reached: \(level)"
        levelText.fontSize = 20
        levelText.fontColor = .white
        levelText.position = CGPoint(x: 0, y: -10)
        levelText.zPosition = 102
        modal.addChild(levelText)
        
        // Retry button
        let retryButton = SKShapeNode(rectOf: CGSize(width: 120, height: 50), cornerRadius: 10)
        retryButton.fillColor = SKColor.systemBlue
        retryButton.strokeColor = SKColor.white
        retryButton.lineWidth = 2
        retryButton.position = CGPoint(x: 0, y: -70)
        retryButton.zPosition = 102
        retryButton.name = "retryButton"
        modal.addChild(retryButton)
        
        let retryLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
        retryLabel.text = "RETRY"
        retryLabel.fontSize = 18
        retryLabel.fontColor = .white
        retryLabel.position = CGPoint(x: 0, y: -6)
        retryLabel.zPosition = 103
        retryButton.addChild(retryLabel)
        
        // Animate modal appearance
        modal.setScale(0)
        let scaleAction = SKAction.scale(to: 1.0, duration: 0.3)
        scaleAction.timingMode = .easeOut
        modal.run(scaleAction)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isGameOver else { return }
        
        for touch in touches {
            let location = touch.location(in: self)
            let node = atPoint(location)
            
            if node.name == "retryButton" || node.parent?.name == "retryButton" {
                restartGame()
            }
        }
    }
    
    func setupHoles(maze: [[Int]], offsetX: CGFloat, offsetY: CGFloat) {
        // Only add holes if level 5 or higher
        guard level >= 5 else { return }
        
        // Determine number of holes based on level
        let numberOfHoles = level >= 10 ? 3 : 1
        
        // Find all path positions that are safe for holes (not too close to player start or items)
        var availablePathPositions: [CGPoint] = []
        
        for row in 2..<maze.count - 2 {
            for col in 2..<maze[row].count - 2 {
                if maze[row][col] == 0 { // This is a path
                    // Check if this position is far enough from player starting area (bottom-left)
                    let isNearStart = row >= maze.count - 4 && col <= 4
                    
                    // Check if this position is too close to any item
                    let position = CGPoint(x: col, y: row)
                    let isTooCloseToItems = itemGridPositions.contains { itemPos in
                        let deltaX = abs(itemPos.col - col)
                        let deltaY = abs(itemPos.row - row)
                        return deltaX <= 2 && deltaY <= 2
                    }
                    
                    if !isNearStart && !isTooCloseToItems {
                        availablePathPositions.append(position)
                    }
                }
            }
        }
        
        // Select random positions for holes
        let selectedPositions = Array(availablePathPositions.shuffled().prefix(numberOfHoles))
        
        for holePos in selectedPositions {
            let row = Int(holePos.y)
            let col = Int(holePos.x)
            
            // Create hole visual
            let holePosition = CGPoint(
                x: offsetX + CGFloat(col) * gridSize + gridSize/2,
                y: offsetY + CGFloat(maze.count - row - 1) * gridSize + gridSize/2
            )
            
            // Create hole sprite using texture (replace "holeTexture" with your actual image name)
            let holeTexture = SKTexture(imageNamed: "hole\(Int.random(in: 1...2))") // Use your brown hole image here
            let hole = SKSpriteNode(texture: holeTexture, size: CGSize(width: gridSize * 0.8, height: gridSize * 0.8))
            hole.position = holePosition
            hole.zPosition = 3 // Above path tiles but below items and walls
            
            // No physics body - holes don't block movement anymore
            
            holes.append(hole)
            addChild(hole)
        }
        
        print("Setup \(holes.count) holes for level \(level)")
    }
    
    func restartGame() {
        print("Restarting game...")
        
        // Reset game state
        score = 0
        level = 1
        health = 3
        isGameOver = false
        isTransitioning = false
        isMoving = false
        isCollecting = false
        isOnHole = false
        currentDirection = .right
        nextDirection = nil
        collectedItems = 0
        expiredItems = 0
        
        // Remove all children and start fresh
        removeAllChildren()
        
        // Clear arrays
        walls.removeAll()
        items.removeAll()
        pathTiles.removeAll()
        holes.removeAll()
        itemGridPositions.removeAll()
        
        // Restart the game
        didMove(to: view!)
    }
    
    func collectMultipleItems(at indices: [Int]) {
        guard !indices.isEmpty, !isTransitioning, !isGameOver, !isCollecting else { return }
        
        // Start collecting process - this stops player movement
        isCollecting = true
        stopPlayerMovement()
        
        var totalPoints = 0
        
        // Sort indices in reverse order to remove items safely
        let sortedIndices = indices.sorted(by: >)
        
        for index in sortedIndices {
            guard index < items.count else { continue }
            
            let item = items[index]
            
            // Calculate score based on item category
            let points = item.category.points * 10 * level
            totalPoints += points
            
            // Add collection effect for each item
            let collectEffect = SKShapeNode(circleOfRadius: gridSize * 0.5)
            collectEffect.strokeColor = item.category.color
            collectEffect.lineWidth = 3
            collectEffect.fillColor = .clear
            collectEffect.position = item.position
            collectEffect.zPosition = 20
            addChild(collectEffect)
            
            // Animate collection effect
            let expandAction = SKAction.scale(to: 2.0, duration: 0.3)
            let fadeAction = SKAction.fadeOut(withDuration: 0.3)
            let removeEffect = SKAction.removeFromParent()
            let effectSequence = SKAction.sequence([SKAction.group([expandAction, fadeAction]), removeEffect])
            collectEffect.run(effectSequence)
            
            // Remove the item and track collection
            item.removeFromParent()
            items.remove(at: index)
            collectedItems += 1
        }
        
        // Update score with total points
        score += totalPoints
        scoreLabel.text = "Score: \(score)"
        
        // Show combined score feedback
        let label = SKLabelNode(fontNamed: "Arial-BoldMT")
        label.text = "+\(totalPoints)"
        label.fontSize = 24
        label.fontColor = sortedIndices.count > 1 ? .yellow : .green
        label.position = CGPoint(x: player.position.x, y: player.position.y + 40)
        addChild(label)
        
        // Player collection animation - make player "glow" during collection
        let playerGlow = SKShapeNode(rectOf: CGSize(width: gridSize + 8, height: gridSize + 8), cornerRadius: 12)
        playerGlow.fillColor = .clear
        playerGlow.strokeColor = sortedIndices.count > 1 ? .yellow : .green
        playerGlow.lineWidth = 4
        playerGlow.position = player.position
        playerGlow.zPosition = player.zPosition + 1
        addChild(playerGlow)
        
        // Animate player glow - stronger effect for multiple items
        let pulseCount = sortedIndices.count > 1 ? 3 : 2
        let glowPulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.1)
        ])
        let repeatPulse = SKAction.repeat(glowPulse, count: pulseCount)
        let fadeGlow = SKAction.fadeOut(withDuration: 0.2)
        let removeGlow = SKAction.removeFromParent()
        let glowSequence = SKAction.sequence([repeatPulse, fadeGlow, removeGlow])
        playerGlow.run(glowSequence)
        
        // Animate the score label
        let moveUp = SKAction.moveBy(x: 0, y: 30, duration: 0.8)
        let fadeOut = SKAction.fadeOut(withDuration: 0.8)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([SKAction.group([moveUp, fadeOut]), remove])
        label.run(sequence)
        
        print("Collected \(sortedIndices.count) items from houses, \(items.count) items remaining, \(collectedItems) total collected")
        
        // Wait 0.5 seconds before allowing movement again
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.run { [weak self] in
                self?.isCollecting = false
                // Only restart movement if we're not transitioning or game over
                if let self = self, !self.isTransitioning && !self.isGameOver {
                    self.startPlayerMovement()
                    
                    // Check if all items are collected
                    if self.items.isEmpty {
                        self.checkLevelCompletion()
                    }
                }
            }
        ]))
    }
    
    func clearInputState() {
        nextDirection = nil
        currentDirection = .right
        isCollecting = false
        isOnHole = false
        print("Input state cleared")
    }

    func findSafeStartingPosition() {
        // Calculate maze offset to center it
        let mazePixelWidth = CGFloat(mazeWidth) * gridSize
        let mazePixelHeight = CGFloat(mazeHeight) * gridSize
        let offsetX = (size.width - mazePixelWidth) / 2
        let offsetY = (size.height - mazePixelHeight) / 2
        
        for row in stride(from: currentMaze.count - 2, to: 0, by: -1) {
            for col in 1 ..< currentMaze[row].count {
                if currentMaze[row][col] == 0 {
                    let pos = CGPoint(
                        x: offsetX + CGFloat(col) * gridSize + gridSize/2,
                        y: offsetY + CGFloat(currentMaze.count - row - 1) * gridSize + gridSize/2
                    )
                    let safe = items.allSatisfy { // Changed from destinations
                        hypot($0.position.x - pos.x, $0.position.y - pos.y) > gridSize * 3
                    }
                    if safe {
                        // Safely remove existing player if it exists
                        player?.removeFromParent()
                        setupPlayer(position: pos)
                        return
                    }
                }
            }
        }
        // Fallback position - ensure it's within the maze bounds
        let fallbackPos = CGPoint(x: offsetX + gridSize * 1.5, y: offsetY + gridSize * 1.5)
        player?.removeFromParent()
        setupPlayer(position: fallbackPos)
    }

    override func update(_ currentTime: TimeInterval) {
        // Can be used for game timers, future AI, etc.
    }
}

// MARK: - Contact Handling

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        let (a, b) = (contact.bodyA, contact.bodyB)
        
        // Check for player-item collision
        if a.categoryBitMask == PlayerNode.category && b.categoryBitMask == ItemNode.categoryBitMask {
            if let itemNode = b.node as? ItemNode,
               let index = items.firstIndex(of: itemNode) {
                collectItem(at: index)
            }
        } else if b.categoryBitMask == PlayerNode.category && a.categoryBitMask == ItemNode.categoryBitMask {
            if let itemNode = a.node as? ItemNode,
               let index = items.firstIndex(of: itemNode) {
                collectItem(at: index)
            }
        }
    }
}
