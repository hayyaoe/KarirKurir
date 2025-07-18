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
    var inputController: InputController!
    
    // get current maze -> render walls -> render destinations
    var currentMaze: [[Int]] = []
    var walls: [SKSpriteNode] = []
    var items: [ItemNode] = [] // Changed from destinations to items
    var itemGridPositions: [(row: Int, col: Int)] = [] // Changed from destinationGridPositions
    var pathTiles: [SKSpriteNode] = []
    var collectedItems: Int = 0
    var expiredItems: Int = 0
    var holes: [SKSpriteNode] = [] // Add holes array
    var cats: [CatObstacle] = []
    var wagons: [WagonObstacle] = []
    
    // Next Object
    var nextMaze: [[Int]] = []
    var nextWalls: [[SKSpriteNode]] = []
    var nextItems: [[ItemNode]] = [] // Changed from nextDestinations
    
    // MARK: - Game State
    
    var currentDirection: MoveDirection = .right
    var nextDirection: MoveDirection?
    var score: Int = 0
    var level: Int = 1
    var health: Int = 3
    var isTransitioning: Bool = false // Add transition state flag
    var isGameOver: Bool = false
    var isCollecting: Bool = false // Add collecting state flag
    var isOnHole: Bool = false // Track if player is on a hole
    var holeSlowdownEndTime: TimeInterval = 0 // Track when hole slowdown effect ends
    var gameStarted: Bool = false // New state for game start
    var waitingForFirstSwipe: Bool = true // New state for first swipe
    
    // Obstacle interaction states
    var playerBehindWagon: WagonObstacle?
    var playerInFrontOfWagon: WagonObstacle?
    var playerAtSideOfWagon: WagonObstacle?
    var playerBlockedBySide: Bool = false
    var playerFollowingWagon: Bool = false // New state for following behavior

    

    // MARK: - UI
    
    var scoreLabel: SKLabelNode!
    var levelLabel: SKLabelNode!
    var healthLabel: SKLabelNode!
    var swipeInstructionNode: SKSpriteNode! // New instruction node
    
    // MARK: - Constants
    
    let playerSpeed: CGFloat = 100.0
    var gridSize: CGFloat = 30.0 // This will be calculated dynamically
    let baseMoveDeuration: TimeInterval = 0.18 // Base movement duration
    
    // MARK: - Maze dimensions
    let mazeWidth: Int = 20
    let mazeHeight: Int = 11

    
    // MARK: - Level Configuration
    
    func getPlayerSpeedFactor() -> Double {
        if level <= 5 {
            return 0.5 // 4x slower
        } else if level <= 10 {
            return 0.75  // 2x slower
        } else {
            return 1.0  // Normal speed
        }
    }
    
    func getItemCount() -> Int {
        if level <= 5 {
            return 3
        } else if level <= 10 {
            return 6
        } else {
            return 10
        }
    }
    
    func getItemTimer() -> Int {
        if level <= 5 {
            return Int.random(in: 36...45)
        } else if level <= 10 {
            return Int.random(in: 26...35)
        } else {
            return Int.random(in: 16...25)
        }
    }
    
    func getHoleCount() -> Int {
        if level <= 5 {
            return 1
        } else if level <= 10 {
            return 3
        } else {
            return 5
        }
    }
    
    func shouldHaveHoles() -> Bool {
        return true // Holes appear from level 1 now
    }
    
    private func worldToGridPosition(_ worldPos: CGPoint) -> CGPoint {
        let mazePixelWidth = CGFloat(mazeWidth) * gridSize
        let mazePixelHeight = CGFloat(mazeHeight) * gridSize
        let offsetX = (size.width - mazePixelWidth) / 2
        let offsetY = (size.height - mazePixelHeight) / 2
        
        let gridX = Int((worldPos.x - offsetX) / gridSize)
        let gridY = Int((worldPos.y - offsetY) / gridSize)
        return CGPoint(x: gridX, y: currentMaze.count - gridY - 1)
    }
    
    func getCatCount() -> Int {
        if level <= 3 {
            return 0
        } else if level <= 7 {
            return 1
        } else {
            return 2
        }
    }
    
    func getWagonCount() -> Int {
        if level <= 5 {
            return 1
        } else if level <= 10 {
            return 1
        } else {
            return 2
        }
    }
    
    // MARK: - Lifecycle
    
    override func didMove(to view: SKView) {
        backgroundColor = .black
        
        // Calculate grid size based on screen dimensions
        calculateOptimalGridSize()
        
        // Setup input controller instead of swipe gestures
        setupInputController()
        
        currentMaze = getMazeLayout(for: level)
        
        // Setup initial player position first
        setupInitialPlayerPosition()
        
        // Setup maze but don't show items yet
        setupMaze(maze: currentMaze)
        
        // Setup UI and instruction screen
        setupUI()
        showSwipeInstruction()
        
        physicsWorld.contactDelegate = self
        
        print("Game loaded - waiting for first swipe to start")
    }
    
    func setupInputController() {
        guard let view = view else { return }
        inputController = InputController(view: view)
        inputController?.onDirectionChange = { [weak self] direction in
            self?.handleDirectionChange(direction)
        }
    }
    
    func handleDirectionChange(_ direction: MoveDirection?) {
        guard let direction = direction else { return }
        
        // Start game on first swipe
        if waitingForFirstSwipe {
            startGame()
        }
        
        // Don't process direction changes during transitions or game over
        guard !isTransitioning && !isGameOver else { return }
        
        // Queue the direction change - this makes controls more responsive
        // during item collection
        self.nextDirection = direction
        
        print("Direction change queued: \(direction.description)")
    }
    
    func startGame() {
        guard waitingForFirstSwipe else { return }
        
        waitingForFirstSwipe = false
        gameStarted = true
        
        // Hide instruction Screen
        hideSwipeInstruction()
        
        // Now spawn the items
        spawnItems()
        
        // Start player movement
        startPlayerMovement()
        
        print("Game Started!")
    }
    
    func showSwipeInstruction() {
        // Create instruction background
        let instructionBackground = SKShapeNode(rectOf: CGSize(width: size.width, height: size.height), cornerRadius: 20)
        instructionBackground.fillColor = SKColor.black.withAlphaComponent(0.5)
        instructionBackground.strokeColor = SKColor.white
        instructionBackground.lineWidth = 2
        instructionBackground.position = CGPoint(x: size.width/2, y: size.height/2)
        instructionBackground.zPosition = 1000
        instructionBackground.name = "instructionBackground"
        addChild(instructionBackground)
        
        // Create the swipe instruction image
        swipeInstructionNode = SKSpriteNode(imageNamed: "swipeToRide") // Use your image name
        swipeInstructionNode.size = CGSize(width: 287, height: 168)
        swipeInstructionNode.position = CGPoint(x: size.width/2, y: size.height/2)
        swipeInstructionNode.zPosition = 1001
        swipeInstructionNode.name = "swipeInstruction"
        addChild(swipeInstructionNode)
        
        // Add pulsing animation to make it more noticeable
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.8)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.8)
        let pulse = SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown]))
        swipeInstructionNode.run(pulse)
    }
    
    func hideSwipeInstruction() {
        // Remove instruction elements with fade animation
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fadeOut, remove])
        
        childNode(withName: "instructionBackground")?.run(sequence)
        childNode(withName: "swipeInstruction")?.run(sequence)
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
        
        player = PlayerNode(tileSize: CGSize(width: gridSize * 1.5, height: gridSize * 1.5))
        player.position = position
        
        if !gameStarted {
            player.zPosition = 1001
        } else {
            player.zPosition = 10
        }
        addChild(player)
        
        print("Player setup at position: \(position)")
    }
    
    func setupUI() {
        // Position UI elements relative to screen size
        let margin: CGFloat = 20
        scoreLabel = createLabel(text: "Score: 0", position: CGPoint(x: margin + 100, y: size.height - 50))
        levelLabel = createLabel(text: "Level: 1", position: CGPoint(x: margin + 250, y: size.height - 50))
        healthLabel = createLabel(text: "❤️ \(health)", position: CGPoint(x: margin + 400, y: size.height - 50))
        if !gameStarted {
            scoreLabel.zPosition = 1001
            healthLabel.zPosition = 1001
            levelLabel.zPosition = 1001
        } else {
            scoreLabel.zPosition = 10
            healthLabel.zPosition = 10
            levelLabel.zPosition = 10
        }
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
    
    func setupMaze(maze: [[Int]]) {
        walls.forEach { $0.removeFromParent() }
        items.forEach { $0.removeFromParent() } // Changed from destinations
        pathTiles.forEach { $0.removeFromParent() }
        holes.forEach { $0.removeFromParent() } // Remove holes
        cats.forEach { $0.removeFromParent() }
        wagons.forEach { $0.removeFromParent() }
        
        walls.removeAll()
        items.removeAll() // Changed from destinations
        pathTiles.removeAll()
        holes.removeAll() // Clear holes array
        cats.removeAll()
        wagons.removeAll()
        
        let wallColor = [UIColor.blue, .purple, .red, .green, .orange, .cyan][(level - 1) % 6]
        
        // Center the maze on screen
        let mazePixelWidth = CGFloat(mazeWidth) * gridSize
        let mazePixelHeight = CGFloat(mazeHeight) * gridSize
        let offsetX = (size.width - mazePixelWidth) / 2
        let offsetY = (size.height - mazePixelHeight) / 2
        
        determineItemPositions(maze: maze)
        
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
        if shouldHaveHoles() {
            setupHoles(maze: maze, offsetX: offsetX, offsetY: offsetY)
        }
        
        // Setup obstacles after game starts
        if gameStarted {
            setupObstacles(maze: maze, offsetX: offsetX, offsetY: offsetY)
        }
        
        nextMaze = getMazeLayout(for: level + 1)
    }
    
    func determineItemPositions(maze: [[Int]]) {
        itemGridPositions.removeAll()
        
        var accessibleWallPositions: [CGPoint] = []
        
        for row in 1..<maze.count - 1 {
            for col in 1..<maze[row].count - 1 {
                if maze[row][col] == 1 {
                    let adjacentPositions = [
                        (row - 1, col),
                        (row + 1, col),
                        (row, col - 1),
                        (row, col + 1)
                    ]
                    
                    var hasAdjacentPath = false
                    for (adjRow, adjCol) in adjacentPositions {
                        if adjRow >= 0 && adjRow < maze.count &&
                            adjCol >= 0 && adjCol < maze[adjRow].count &&
                            maze[adjRow][adjCol] == 0 {
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
        
        let selectedPositions = Array(accessibleWallPositions.shuffled().prefix(getItemCount()))
        
        for wallPos in selectedPositions {
            let row = Int(wallPos.y)
            let col = Int(wallPos.x)
            itemGridPositions.append((row: row, col: col))
        }
    }
    
    func spawnItems() {
        guard gameStarted else { return }
        
        let mazePixelWidth = CGFloat(mazeWidth) * gridSize
        let mazePixelHeight = CGFloat(mazeHeight) * gridSize
        let offsetX = (size.width - mazePixelWidth) / 2
        let offsetY = (size.height - mazePixelHeight) / 2
        
        for (row, col) in itemGridPositions {
            let randomTime = Int.random(in: 16...25)
            let itemSize = CGSize(width: gridSize * 0.6, height: gridSize * 0.6)
            let item = ItemNode(size: itemSize, initialTime: randomTime)
            
            let itemPosition = CGPoint(
                x: offsetX + CGFloat(col) * gridSize + gridSize/2,
                y: offsetY + CGFloat(currentMaze.count - row - 1) * gridSize + gridSize/2
            )
            item.position = itemPosition
            item.zPosition = 15
            
            item.physicsBody?.categoryBitMask = ItemNode.categoryBitMask
            item.physicsBody?.contactTestBitMask = PlayerNode.category
            item.physicsBody?.collisionBitMask = 0
            
            item.onTimerExpired = { [weak self, weak item] in
                guard let self = self, let item = item, !self.isTransitioning, !self.isGameOver else { return }
                if let index = self.items.firstIndex(of: item) {
                    self.items.remove(at: index)
                }
                item.removeFromParent()
                self.expiredItems += 1
                
                print("Item expired, \(self.items.count) items remaining, \(self.expiredItems) expired")
                
                if self.items.isEmpty && !self.isTransitioning {
                    self.checkLevelCompletion()
                }
            }
            
            addChild(item)
            items.append(item)
        }
        
        // Also spawn obstacles
                setupObstacles(maze: currentMaze,
                              offsetX: offsetX,
                              offsetY: offsetY)
        
        print("Spawned \(items.count) items after game started")
    }
    
    func setupObstacles(maze: [[Int]], offsetX: CGFloat, offsetY: CGFloat) {
        let mazeOffset = CGPoint(x: offsetX, y: offsetY)
        
        // Setup cats
        let catCount = getCatCount()
        for _ in 0..<catCount {
            if let catPosition = findSafeGrassPosition(maze: maze, offsetX: offsetX, offsetY: offsetY) {
                let cat = CatObstacle(gridSize: gridSize, maze: maze, mazeOffset: mazeOffset)
                cat.position = catPosition
                cat.zPosition = 12
                addChild(cat)
                cats.append(cat)
            }
        }
        
        // Setup wagon
        let wagonCount = getWagonCount()
        for _ in 0..<wagonCount {
            if let wagonPosition = findSafeRoadPosition(maze: maze, offsetX: offsetX, offsetY: offsetY) {
                let wagon = WagonObstacle(gridSize: gridSize, maze: maze, mazeOffset: mazeOffset, playerSpeedFactor: getPlayerSpeedFactor())
                wagon.position = wagonPosition
                wagon.zPosition = 12
                wagon.player = player
                
                // Setup seller interaction callback
                wagon.onPlayerInteraction = { [weak self] wagon, interactionType in
                    self?.handleWagonInteraction(wagon, interactionType)
                }
                
                addChild(wagon)
                wagons.append(wagon)
            }
        }
        
        print("Spawned \(cats.count) cats and \(wagons.count) sellers for level \(level)")
    }
    
    func findSafeGrassPosition(maze: [[Int]], offsetX: CGFloat, offsetY: CGFloat) -> CGPoint? {
        var grassPositions: [CGPoint] = []
        
        for row in 1..<maze.count - 1 {
            for col in 1..<maze[row].count - 1 {
                if maze[row][col] == 1 { // grass/wall
                    let worldPos = CGPoint(
                        x: offsetX + CGFloat(col) * gridSize + gridSize/2,
                        y: offsetY + CGFloat(maze.count - row - 1) * gridSize + gridSize/2
                    )
                    
                    // Check if position is far from player start and items
                    let isFarFromPlayer = hypot(worldPos.x - player.position.x, worldPos.y - player.position.y) > gridSize * 4
                    let isFarFromItems = items.allSatisfy { item in
                        hypot(worldPos.x - item.position.x, worldPos.y - item.position.y) > gridSize * 2
                    }
                    
                    if isFarFromPlayer && isFarFromItems {
                        grassPositions.append(worldPos)
                    }
                }
            }
        }
        
        return grassPositions.randomElement()
    }
    
    func findSafeRoadPosition(maze: [[Int]], offsetX: CGFloat, offsetY: CGFloat) -> CGPoint? {
        var roadPositions: [CGPoint] = []
        
        for row in 1..<maze.count - 1 {
            for col in 1..<maze[row].count - 1 {
                if maze[row][col] == 0 { // road/path
                    let worldPos = CGPoint(
                        x: offsetX + CGFloat(col) * gridSize + gridSize/2,
                        y: offsetY + CGFloat(maze.count - row - 1) * gridSize + gridSize/2
                    )
                    
                    // Check if position is far from player start and items
                    let isFarFromPlayer = hypot(worldPos.x - player.position.x, worldPos.y - player.position.y) > gridSize * 5
                    let isFarFromItems = items.allSatisfy { item in
                        hypot(worldPos.x - item.position.x, worldPos.y - item.position.y) > gridSize * 3
                    }
                    
                    if isFarFromPlayer && isFarFromItems {
                        roadPositions.append(worldPos)
                    }
                }
            }
        }
        
        return roadPositions.randomElement()
    }
    
    // Update the handleWagonInteraction method:
    func handleWagonInteraction(_ wagon: WagonObstacle, _ interactionType: WagonObstacle.PlayerInteractionType) {
        switch interactionType {
        case .playerInFront:
            // Player in front - both stop completely
            if playerInFrontOfWagon != wagon {
                // Clear other interactions first
                clearOtherWagonInteractions(except: wagon)
                
                playerInFrontOfWagon = wagon
                playerBehindWagon = nil
                playerAtSideOfWagon = nil
                playerBlockedBySide = false
                playerFollowingWagon = false
                
                wagon.setBlocked(true, reason: "Player in front")
                print("Player in front of wagon - both stopped")
            }
            
        case .playerBehind:
            // Player behind - wagon tries to move away from player
            if playerBehindWagon != wagon {
                // Clear other interactions first
                clearOtherWagonInteractions(except: wagon)
                
                playerBehindWagon = wagon
                playerInFrontOfWagon = nil
                playerAtSideOfWagon = nil
                playerBlockedBySide = false
                playerFollowingWagon = false
                
                // Make wagon try to escape from player
                makeWagonEscapeFromPlayer(wagon, playerPosition: .behind)
                print("Player behind wagon - wagon trying to escape")
            }
            
        case .playerAtSide:
            // Player at side - wagon tries to move away from player
            if playerAtSideOfWagon != wagon {
                // Clear other interactions first
                clearOtherWagonInteractions(except: wagon)
                
                playerAtSideOfWagon = wagon
                playerInFrontOfWagon = nil
                playerBehindWagon = nil
                playerBlockedBySide = true
                playerFollowingWagon = false
                
                // Make wagon try to escape from player
                makeWagonEscapeFromPlayer(wagon, playerPosition: .side)
                print("Player at side of wagon - wagon trying to escape")
            }
            
        case .playerClear:
            // Player clear - normal movement
            if playerInFrontOfWagon == wagon {
                playerInFrontOfWagon = nil
                wagon.setBlocked(false, reason: "Player moved away from front")
                wagon.resumeNormalMovement()
                print("Player no longer in front of wagon - wagon can move normally")
            }
            if playerBehindWagon == wagon {
                playerBehindWagon = nil
                playerFollowingWagon = false
                wagon.resumeNormalMovement()
                print("Player no longer behind wagon - wagon resuming normal movement")
            }
            if playerAtSideOfWagon == wagon {
                playerAtSideOfWagon = nil
                playerBlockedBySide = false
                wagon.resumeNormalMovement()
                print("Player no longer at side of wagon - wagon resuming normal movement")
            }
        }
    }

    private func makeWagonEscapeFromPlayer(_ wagon: WagonObstacle, playerPosition: PlayerRelativePosition) {
        let wagonGridPos = wagon.getGridPosition()
        let playerGridPos = worldToGridPosition(player.position)
        
        // Find available escape directions
        let escapeDirections = findEscapeDirections(
            from: wagonGridPos,
            avoiding: playerGridPos,
            currentDirection: wagon.getCurrentDirection(),
            playerPosition: playerPosition
        )
        
        if escapeDirections.isEmpty {
            // No escape routes - wagon must stop
            wagon.setBlocked(true, reason: "Trapped by player - no escape routes")
            print("Wagon trapped by player - stopping")
        } else {
            // Set wagon to escape mode with preferred directions
            wagon.setEscapeMode(escapeDirections: escapeDirections)
            print("Wagon escaping - available directions: \(escapeDirections.map { $0.description })")
        }
    }
    
    // Helper method to find escape directions for wagon
    private func findEscapeDirections(from wagonPos: CGPoint, avoiding playerPos: CGPoint, currentDirection: MoveDirection, playerPosition: PlayerRelativePosition) -> [MoveDirection] {
        let allDirections: [MoveDirection] = [.up, .down, .left, .right]
        var escapeDirections: [MoveDirection] = []
        
        for direction in allDirections {
            let nextPos = getNextPosition(from: wagonPos, direction: direction)
            
            // Check if this direction is valid (not wall, within bounds)
            if isValidRoadPosition(nextPos) {
                // Check if this direction moves away from player
                let currentDistanceToPlayer = hypot(wagonPos.x - playerPos.x, wagonPos.y - playerPos.y)
                let futureDistanceToPlayer = hypot(nextPos.x - playerPos.x, nextPos.y - playerPos.y)
                
                // For behind position, prioritize forward movement (away from player)
                if playerPosition == .behind {
                    if direction == currentDirection {
                        // Moving forward (current direction) is highest priority
                        escapeDirections.insert(direction, at: 0)
                    } else if futureDistanceToPlayer > currentDistanceToPlayer {
                        // Any direction that increases distance from player
                        escapeDirections.append(direction)
                    }
                }
                // For side position, any direction that increases distance is good
                else if playerPosition == .side {
                    if futureDistanceToPlayer > currentDistanceToPlayer {
                        escapeDirections.append(direction)
                    }
                    // Also allow perpendicular movement
                    else if abs(futureDistanceToPlayer - currentDistanceToPlayer) < 0.5 {
                        escapeDirections.append(direction)
                    }
                }
            }
        }
        
        return escapeDirections
    }
    
    private func getNextPosition(from gridPos: CGPoint, direction: MoveDirection) -> CGPoint {
        let vector = direction.vector
        return CGPoint(x: gridPos.x + vector.dx, y: gridPos.y + vector.dy)
    }
    
    private func isValidRoadPosition(_ gridPos: CGPoint) -> Bool {
        let row = Int(gridPos.y)
        let col = Int(gridPos.x)
        
        guard row >= 0 && row < currentMaze.count && col >= 0 && col < currentMaze[0].count else {
            return false
        }
        
        return currentMaze[row][col] == 0 // 0 means road/path
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
    
    func startContinuousWagonCollisionCheck() {
        // Remove any existing collision check
        removeAction(forKey: "wagonCollisionCheck")
        
        // Start continuous collision checking - moderate frequency to avoid glitches
        let checkAction = SKAction.repeatForever(.sequence([
            .run { [weak self] in self?.checkAllWagonCollisions() },
            .wait(forDuration: 0.1) // Check every 0.1 seconds - stable frequency
        ]))
        run(checkAction, withKey: "wagonCollisionCheck")
    }

    func stopContinuousWagonCollisionCheck() {
        removeAction(forKey: "wagonCollisionCheck")
    }

    private func checkAllWagonCollisions() {
        guard gameStarted && !isTransitioning && !isGameOver && !isMoving else { return }
        
        // Only check when player is not moving to avoid glitches
        var anyInteractionFound = false
        
        for wagon in wagons {
            let interactionType = checkIndividualWagonCollision(wagon)
            if interactionType != .playerClear {
                // Only handle interaction if it's not already set
                if !isInteractionAlreadySet(wagon, interactionType) {
                    handleWagonInteraction(wagon, interactionType)
                }
                anyInteractionFound = true
            }
        }
        
        // Clear interactions that are no longer active
        if !anyInteractionFound {
            clearStaleWagonInteractions()
        }
    }
    
    private func isInteractionAlreadySet(_ wagon: WagonObstacle, _ type: WagonObstacle.PlayerInteractionType) -> Bool {
        switch type {
        case .playerInFront:
            return playerInFrontOfWagon == wagon
        case .playerBehind:
            return playerBehindWagon == wagon
        case .playerAtSide:
            return playerAtSideOfWagon == wagon
        case .playerClear:
            return false
        }
    }
    
    private func clearStaleWagonInteractions() {
        var clearedAny = false
        
        if let wagon = playerInFrontOfWagon {
            let currentInteraction = checkIndividualWagonCollision(wagon)
            if currentInteraction == .playerClear {
                handleWagonInteraction(wagon, .playerClear)
                clearedAny = true
            }
        }
        
        if let wagon = playerBehindWagon {
            let currentInteraction = checkIndividualWagonCollision(wagon)
            if currentInteraction == .playerClear {
                handleWagonInteraction(wagon, .playerClear)
                clearedAny = true
            }
        }
        
        if let wagon = playerAtSideOfWagon {
            let currentInteraction = checkIndividualWagonCollision(wagon)
            if currentInteraction == .playerClear {
                handleWagonInteraction(wagon, .playerClear)
                clearedAny = true
            }
        }
        
        if clearedAny {
            print("Cleared stale wagon interactions")
        }
    }
    
    private func checkIndividualWagonCollision(_ wagon: WagonObstacle) -> WagonObstacle.PlayerInteractionType {
        let playerGridPos = worldToGridPosition(player.position)
        let wagonGridPos = wagon.getGridPosition()
        
        // Calculate the difference between player and wagon positions
        let deltaX = playerGridPos.x - wagonGridPos.x
        let deltaY = playerGridPos.y - wagonGridPos.y
        
        // Check if player is adjacent to wagon (distance of 1 in grid) or on same position
        let isAdjacent = (abs(deltaX) == 1 && deltaY == 0) || (deltaX == 0 && abs(deltaY) == 1)
        let isOnSamePosition = deltaX == 0 && deltaY == 0
        
        if isOnSamePosition || isAdjacent {
            // Determine the relative position based on wagon's current direction
            let interactionType = determineWagonInteractionType(deltaX: deltaX, deltaY: deltaY, wagon: wagon)
            return interactionType
        } else {
            // Player is not near this wagon
            return .playerClear
        }
    }
    
    private func determineWagonInteractionType(deltaX: CGFloat, deltaY: CGFloat, wagon: WagonObstacle) -> WagonObstacle.PlayerInteractionType {
        // Get the direction vector of the wagon
        let directionVector = wagon.getCurrentDirection().vector
        
        // Check if player is in front of wagon (in the direction wagon is moving)
        if deltaX == directionVector.dx && deltaY == directionVector.dy {
            return .playerInFront
        }
        
        // Check if player is behind wagon (opposite to direction wagon is moving)
        if deltaX == -directionVector.dx && deltaY == -directionVector.dy {
            return .playerBehind
        }
        
        // Check if player is at the same position as wagon
        if deltaX == 0 && deltaY == 0 {
            // Determine based on which side the player approached from
            // For now, treat same position as front collision (both stop)
            return .playerInFront
        }
        
        // Player is at the side of wagon
        return .playerAtSide
    }
    
    // MARK: - Player Movement
    
    // Update startPlayerMovement to also start collision checking:
    func startPlayerMovement() {
        guard gameStarted else { return }
        
        removeAction(forKey: "playerMovement")
        let movementAction = SKAction.repeatForever(.sequence([
            .run { [weak self] in self?.updatePlayerMovement() },
            .wait(forDuration: 0.02)
        ]))
        run(movementAction, withKey: "playerMovement")
        
        // Start continuous wagon collision checking
        startContinuousWagonCollisionCheck()
    }
    
    var isMoving = false
    
//    func updatePlayerMovement() {
//        guard gameStarted && !isTransitioning && !isGameOver && !isMoving else { return }
//        
//        // Process queued direction changes - this makes controls more responsive
//        if let next = nextDirection, canMove(in: next) {
//            currentDirection = next
//            nextDirection = nil
//            print("Direction changed to: \(currentDirection.description)")
//        }
//        
//        if canMove(in: currentDirection) {
//            let targetPosition = getTargetPosition(for: currentDirection)
//            isMoving = true
//            
//            let willBeOnHole = holes.contains { hole in
//                let distance = hypot(targetPosition.x - hole.position.x, targetPosition.y - hole.position.y)
//                return distance < gridSize * 0.5
//            }
//            
//            let currentTime = CACurrentMediaTime()
//            let baseSpeed = getPlayerSpeedFactor()
//            let baseDuration = baseMoveDeuration / baseSpeed
//            let isUnderHoleSlowdown = currentTime < holeSlowdownEndTime
//            let moveDuration = (willBeOnHole || isUnderHoleSlowdown) ? baseDuration * 2.0 : baseDuration
//            
//            // Use smoother movement with better timing
//            player.moveWithCustomDuration(to: targetPosition, duration: moveDuration) { [weak self] in
//                self?.isMoving = false
//                self?.updateHoleStatus()
//                self?.checkForItemCollection()
//            }
//        }
//    }
    func updatePlayerMovement() {
        guard gameStarted && !isTransitioning && !isGameOver && !isMoving else { return }
        
        // Simplified movement logic to avoid glitches
        // Process queued direction changes - this makes controls more responsive
        if let next = nextDirection, canMove(in: next) {
            currentDirection = next
            nextDirection = nil
            print("Direction changed to: \(currentDirection.description)")
        }
        
        if canMove(in: currentDirection) {
            let targetPosition = getTargetPosition(for: currentDirection)
            movePlayerToPosition(targetPosition)
        }
    }
    
    func handleFollowingWagonMovement(_ wagon: WagonObstacle) {
        let wagonDirection = wagon.getCurrentDirection()
        
        // Check if player wants to change direction away from wagon
        if let next = nextDirection, next != wagonDirection {
            if canMove(in: next) {
                // Player is breaking away from following the wagon
                currentDirection = next
                nextDirection = nil
                playerFollowingWagon = false
                print("Player breaking away from wagon - direction changed to: \(currentDirection.description)")
                
                // Move with normal speed
                let targetPosition = getTargetPosition(for: currentDirection)
                movePlayerToPosition(targetPosition)
                return
            }
        }
        
        // Continue following wagon in wagon's direction
        currentDirection = wagonDirection
        nextDirection = nil // Clear any queued direction that can't be executed
        
        if canMove(in: currentDirection) {
            let targetPosition = getTargetPosition(for: currentDirection)
            // Move at wagon's speed (0.5 seconds)
            movePlayerToPosition(targetPosition)
        }
    }
    
    // Simplified method to move player
    func movePlayerToPosition(_ targetPosition: CGPoint) {
        isMoving = true
        
        let willBeOnHole = holes.contains { hole in
            let distance = hypot(targetPosition.x - hole.position.x, targetPosition.y - hole.position.y)
            return distance < gridSize * 0.5
        }
        
        let currentTime = CACurrentMediaTime()
        let isUnderHoleSlowdown = currentTime < holeSlowdownEndTime
        
        // Use normal player speed
        let baseSpeed = getPlayerSpeedFactor()
        let baseDuration = baseMoveDeuration / baseSpeed
        let moveDuration = (willBeOnHole || isUnderHoleSlowdown) ? baseDuration * 2.0 : baseDuration
        
        // Use smoother movement with calculated timing
        player.moveWithCustomDuration(to: targetPosition, duration: moveDuration) { [weak self] in
            self?.isMoving = false
            self?.updateHoleStatus()
            self?.checkForItemCollection()
        }
    }
    
    func getTargetPosition(for direction: MoveDirection) -> CGPoint {
        let vector = direction.vector
        return CGPoint(
            x: player.position.x + vector.dx * gridSize,
            y: player.position.y + vector.dy * gridSize
        )
    }
    
    func updateHoleStatus() {
        let wasOnHole = isOnHole
        let wasUnderSlowdown = CACurrentMediaTime() < holeSlowdownEndTime

        isOnHole = false
        
        for hole in holes {
            let distance = hypot(player.position.x - hole.position.x, player.position.y - hole.position.y)
            if distance < gridSize * 0.5 {
                isOnHole = true
                break
            }
        }
        
        let currentTime = CACurrentMediaTime()
        let isUnderSlowdown = isOnHole || currentTime < holeSlowdownEndTime
        
        if wasOnHole && !isOnHole {
            holeSlowdownEndTime = CACurrentMediaTime() + 2.0
            print("Player left hole - slowdown effect will last 2 more seconds")
        }
        
        // Manage flashing UI effect
        if isUnderSlowdown && !player.isShowingSlowdown() {
            player.showSlowdownEffect()
        } else if !isUnderSlowdown && player.isShowingSlowdown() {
            player.hideSlowdownEffect()
        }
        
        if wasOnHole != isOnHole {
            print("Player \(isOnHole ? "entered" : "left") hole")
        }
    }
    
    // Helper method to clear other wagon interactions
    private func clearOtherWagonInteractions(except excludedWagon: WagonObstacle) {
        for wagon in wagons {
            if wagon != excludedWagon {
                if playerInFrontOfWagon == wagon {
                    playerInFrontOfWagon = nil
                    wagon.setBlocked(false, reason: "Player moved to different wagon")
                    wagon.resumeNormalMovement()
                }
                if playerBehindWagon == wagon {
                    playerBehindWagon = nil
                    playerFollowingWagon = false
                    wagon.resumeNormalMovement()
                }
                if playerAtSideOfWagon == wagon {
                    playerAtSideOfWagon = nil
                    playerBlockedBySide = false
                    wagon.resumeNormalMovement()
                }
            }
        }
    }

    func clearAllWagonInteractions() {
        // Clear all interaction states
        playerBehindWagon = nil
        playerInFrontOfWagon = nil
        playerAtSideOfWagon = nil
        playerBlockedBySide = false
        playerFollowingWagon = false
        
        // Unblock all wagons and ensure they can move
        wagons.forEach { wagon in
            wagon.setBlocked(false, reason: "All interactions cleared")
            wagon.resumeNormalMovement() // Clear any escape modes
        }
        
        print("All wagon interactions cleared")
    }
    
    // Update the canMove method to handle wagon interactions:
    func canMove(in direction: MoveDirection) -> Bool {
        let vector = direction.vector
        let future = CGPoint(
            x: player.position.x + vector.dx * (gridSize/2 + 5),
            y: player.position.y + vector.dy * (gridSize/2 + 5)
        )
        
        let mazePixelWidth = CGFloat(mazeWidth) * gridSize
        let mazePixelHeight = CGFloat(mazeHeight) * gridSize
        let offsetX = (size.width - mazePixelWidth) / 2
        let offsetY = (size.height - mazePixelHeight) / 2
        
        let mazeMinX = offsetX
        let mazeMaxX = offsetX + mazePixelWidth
        let mazeMinY = offsetY
        let mazeMaxY = offsetY + mazePixelHeight
        
        if future.x < mazeMinX || future.x > mazeMaxX || future.y < mazeMinY || future.y > mazeMaxY {
            return false
        }
        
        // Check collision with walls
        if walls.contains(where: { $0.frame.contains(future) }) {
            return false
        }
        
        // Check collision with cats
        if cats.contains(where: { cat in
            let distance = hypot(future.x - cat.position.x, future.y - cat.position.y)
            return distance < gridSize * 0.7
        }) {
            return false
        }
        
        // Handle wagon interaction restrictions - simplified for better stability
        
        // 1. Player in front of wagon - cannot move towards wagon
        if let wagon = playerInFrontOfWagon {
            return canMoveAwayFromWagon(wagon: wagon, direction: direction, future: future)
        }
        
        // 2. Player behind wagon - can move freely (wagon will escape)
        if playerBehindWagon != nil {
            return true // Player can move freely, wagon handles escaping
        }
        
        // 3. Player at side of wagon - can move freely (wagon will escape)
        if playerAtSideOfWagon != nil {
            return true // Player can move freely, wagon handles escaping
        }
        
        // Check direct collision with wagons (for new collisions)
        if wagons.contains(where: { wagon in
            let distance = hypot(future.x - wagon.position.x, future.y - wagon.position.y)
            return distance < gridSize * 0.7
        }) {
            return false
        }
        
        return true
    }

    
    // Helper method to check if player can move away from wagon
    // Helper method to check if player can move away from wagon
    private func canMoveAwayFromWagon(wagon: WagonObstacle, direction: MoveDirection, future: CGPoint) -> Bool {
        let currentPlayerGridPos = worldToGridPosition(player.position)
        let futurePlayerGridPos = worldToGridPosition(future)
        let wagonGridPos = wagon.getGridPosition()
        
        // Calculate current distance from wagon
        let currentDistance = hypot(
            currentPlayerGridPos.x - wagonGridPos.x,
            currentPlayerGridPos.y - wagonGridPos.y
        )
        
        // Calculate future distance from wagon
        let futureDistance = hypot(
            futurePlayerGridPos.x - wagonGridPos.x,
            futurePlayerGridPos.y - wagonGridPos.y
        )
        
        // Allow movement if it increases distance from wagon (moving away)
        if futureDistance > currentDistance + 0.1 { // Small tolerance
            print("Player can move \(direction.description) - moving away from wagon")
            return true
        }
        
        // Allow movement if it maintains roughly the same distance (parallel movement)
        if abs(futureDistance - currentDistance) <= 0.2 { // Slightly more tolerance
            print("Player can move \(direction.description) - parallel to wagon")
            return true
        }
        
        // For side collisions, be more permissive - allow movement that doesn't get much closer
        if playerAtSideOfWagon == wagon {
            let distanceReduction = currentDistance - futureDistance
            if distanceReduction < 0.5 { // Allow movement that doesn't get much closer
                print("Player can move \(direction.description) - side collision with minimal approach")
                return true
            }
        }
        
        // Don't allow movement that brings player significantly closer to wagon
        print("Player cannot move \(direction.description) - would move too close to wagon")
        return false
    }
    
    // MARK: - Item Collection
    
    func checkForItemCollection() {
        guard gameStarted && !isGameOver else { return }
        
        let mazePixelWidth = CGFloat(mazeWidth) * gridSize
        let mazePixelHeight = CGFloat(mazeHeight) * gridSize
        let offsetX = (size.width - mazePixelWidth) / 2
        let offsetY = (size.height - mazePixelHeight) / 2
        
        let playerGridX = Int((player.position.x - offsetX) / gridSize)
        let playerGridY = Int((player.position.y - offsetY) / gridSize)
        
        var itemsToCollect: [Int] = []
        
        for (index, item) in items.enumerated() {
            let itemGridX = Int((item.position.x - offsetX) / gridSize)
            let itemGridY = Int((item.position.y - offsetY) / gridSize)
            
            let deltaX = playerGridX - itemGridX
            let deltaY = playerGridY - itemGridY
            
            let isDirectlyAdjacent = (abs(deltaX) == 1 && deltaY == 0) || (deltaX == 0 && abs(deltaY) == 1)
            
            if isDirectlyAdjacent {
                itemsToCollect.append(index)
            }
        }
        
        if !itemsToCollect.isEmpty {
            collectMultipleItems(at: itemsToCollect)
        }
    }
    
    // MARK: - Game Progress
    
    func nextLevel() {
        isTransitioning = true
        print("Starting level transition to level \(level + 1)")
        stopPlayerMovement()
        clearInputState()
        
        level += 1
        levelLabel.text = "Level: \(level)"
        
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
        
        // Stop collision checking during transition
        stopContinuousWagonCollisionCheck()
        
        isMoving = false
        isCollecting = false
        isOnHole = false
        holeSlowdownEndTime = 0
        currentDirection = .right
        nextDirection = nil
        collectedItems = 0
        expiredItems = 0
        playerFollowingWagon = false

        // Clear hole effect for level transition
        player.hideSlowdownEffect()
        
        // Clear all wagon interactions properly
        clearAllWagonInteractions()
        
        currentMaze = nextMaze.isEmpty ? getMazeLayout(for: level) : nextMaze
        setupMaze(maze: currentMaze)
        spawnItems() // Spawn items immediately for new level
        findSafeStartingPosition()
        
        // Update obstacle references to new maze
        updateObstacleReferences()
        
        run(.sequence([
            .wait(forDuration: 0.1),
            .run { [weak self] in
                self?.startPlayerMovement() // This will also restart collision checking
                self?.isTransitioning = false
                print("Level transition complete - input and movement re-enabled")
                print("Level \(self?.level ?? 0) stats: Speed factor: \(self?.getPlayerSpeedFactor() ?? 0), Items: \(self?.getItemCount() ?? 0), Holes: \(self?.getHoleCount() ?? 0)")
            }
        ]))
    }
    
    func updateObstacleReferences() {
        let mazePixelWidth = CGFloat(mazeWidth) * gridSize
        let mazePixelHeight = CGFloat(mazeHeight) * gridSize
        let offsetX = (size.width - mazePixelWidth) / 2
        let offsetY = (size.height - mazePixelHeight) / 2
        let mazeOffset = CGPoint(x: offsetX, y: offsetY)
        
        // Update all obstacle references
        cats.forEach { cat in
            cat.updateMaze(currentMaze, offset: mazeOffset)
        }
        
        wagons.forEach { wagon in
            wagon.updateMaze(currentMaze, offset: mazeOffset)
            wagon.updatePlayerSpeedFactor(getPlayerSpeedFactor())
        }
    }
    
    // Update stopPlayerMovement to also stop collision checking:
    func stopPlayerMovement() {
        removeAction(forKey: "playerMovement")
        player?.removeAllActions()
        isMoving = false
        
        // Stop continuous collision checking
        stopContinuousWagonCollisionCheck()
        
        print("Player movement and wagon collision checking stopped")
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
        // Use level-based hole count
        let numberOfHoles = getHoleCount()
        
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
            
            // Create hole sprite using texture
            let holeTexture = SKTexture(imageNamed: "hole\(Int.random(in: 1...2))")
            let hole = SKSpriteNode(texture: holeTexture, size: CGSize(width: gridSize * 1.2, height: gridSize * 1.2))
            hole.position = holePosition
            hole.zPosition = 2 // Above path tiles but below items and walls
            
            // No physics body - holes don't block movement
            
            holes.append(hole)
            addChild(hole)
        }
        
        print("Setup \(holes.count) holes for level \(level)")
    }
    
    func restartGame() {
        print("Restarting game...")
        
        // Stop collision checking
        stopContinuousWagonCollisionCheck()
        
        // Hide any active hole effects before restart
        player?.hideSlowdownEffect()
        
        // Clear all wagon interactions properly
        clearAllWagonInteractions()
        
        // Reset game state
        score = 0
        level = 1
        health = 3
        isGameOver = false
        isTransitioning = false
        isMoving = false
        isCollecting = false
        isOnHole = false
        holeSlowdownEndTime = 0
        currentDirection = .right
        nextDirection = nil
        collectedItems = 0
        expiredItems = 0
        gameStarted = false
        waitingForFirstSwipe = true
        playerFollowingWagon = false

        // Remove all children and start fresh
        removeAllChildren()
        
        // Clear arrays
        walls.removeAll()
        items.removeAll()
        pathTiles.removeAll()
        holes.removeAll()
        cats.removeAll()
        wagons.removeAll()
        itemGridPositions.removeAll()
        
        // Restart the game
        didMove(to: view!)
    }
    
    func collectMultipleItems(at indices: [Int]) {
        guard !indices.isEmpty, !isTransitioning, !isGameOver else { return }
        
        // Don't stop movement during collection - this makes controls more responsive
        var totalPoints = 0
        let sortedIndices = indices.sorted(by: >)
        
        for index in sortedIndices {
            guard index < items.count else { continue }
            
            let item = items[index]
            let points = item.category.points * 10 * level
            totalPoints += points
            
            let collectEffect = SKShapeNode(circleOfRadius: gridSize * 0.5)
            collectEffect.strokeColor = item.category.color
            collectEffect.lineWidth = 3
            collectEffect.fillColor = .clear
            collectEffect.position = item.position
            collectEffect.zPosition = 20
            addChild(collectEffect)
            
            let expandAction = SKAction.scale(to: 2.0, duration: 0.3)
            let fadeAction = SKAction.fadeOut(withDuration: 0.3)
            let removeEffect = SKAction.removeFromParent()
            let effectSequence = SKAction.sequence([SKAction.group([expandAction, fadeAction]), removeEffect])
            collectEffect.run(effectSequence)
            
            item.removeFromParent()
            items.remove(at: index)
            collectedItems += 1
        }
        
        score += totalPoints
        scoreLabel.text = "Score: \(score)"
        
        let label = SKLabelNode(fontNamed: "Arial-BoldMT")
        label.text = "+\(totalPoints)"
        label.fontSize = 24
        label.fontColor = sortedIndices.count > 1 ? .yellow : .green
        label.position = CGPoint(x: player.position.x, y: player.position.y + 40)
        addChild(label)
        
        let moveUp = SKAction.moveBy(x: 0, y: 30, duration: 0.8)
        let fadeOut = SKAction.fadeOut(withDuration: 0.8)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([SKAction.group([moveUp, fadeOut]), remove])
        label.run(sequence)
        
        print("Collected \(sortedIndices.count) items from houses, \(items.count) items remaining, \(collectedItems) total collected")
        
        if items.isEmpty {
            checkLevelCompletion()
        }
    }
    
    func clearInputState() {
        nextDirection = nil
        currentDirection = .right
        isCollecting = false
        isOnHole = false
        holeSlowdownEndTime = 0
        
        // Clear hole effect
        player.hideSlowdownEffect()
        
        // Clear wagon interaction states with proper cleanup
        clearAllWagonInteractions()
        
        print("Input state cleared including wagon interactions and hole effects")
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
                collectMultipleItems(at: [index])
            }
        } else if b.categoryBitMask == PlayerNode.category && a.categoryBitMask == ItemNode.categoryBitMask {
            if let itemNode = a.node as? ItemNode,
               let index = items.firstIndex(of: itemNode) {
                collectMultipleItems(at: [index])
            }
        }
        
        // Check for player-cat collision (handled by physics collision)
        if (a.categoryBitMask == PlayerNode.category && b.categoryBitMask == CatObstacle.categoryBitMask) ||
            (b.categoryBitMask == PlayerNode.category && a.categoryBitMask == CatObstacle.categoryBitMask) {
            print("Player collided with cat - movement blocked")
        }
        
        // Check for player-wagon contact (handle immediately but only when not moving)
        if !isMoving {
            if (a.categoryBitMask == PlayerNode.category && b.categoryBitMask == WagonObstacle.categoryBitMask) {
                if let wagonNode = b.node as? WagonObstacle {
                    let interactionType = checkIndividualWagonCollision(wagonNode)
                    if interactionType != .playerClear {
                        handleWagonInteraction(wagonNode, interactionType)
                    }
                }
            } else if (b.categoryBitMask == PlayerNode.category && a.categoryBitMask == WagonObstacle.categoryBitMask) {
                if let wagonNode = a.node as? WagonObstacle {
                    let interactionType = checkIndividualWagonCollision(wagonNode)
                    if interactionType != .playerClear {
                        handleWagonInteraction(wagonNode, interactionType)
                    }
                }
            }
        }
    }
}

// Helper methods:
private func getPerpendicularDirections(to direction: MoveDirection) -> [MoveDirection] {
    switch direction {
    case .up, .down:
        return [.left, .right]
    case .left, .right:
        return [.up, .down]
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
// MARK: - MoveDirection Extension

extension MoveDirection {
    var vector: CGVector {
        switch self {
        case .up: return CGVector(dx: 0, dy: 1)
        case .down: return CGVector(dx: 0, dy: -1)
        case .left: return CGVector(dx: -1, dy: 0)
        case .right: return CGVector(dx: 1, dy: 0)
        }
    }
    
    var description: String {
        switch self {
        case .up: return "up"
        case .down: return "down"
        case .left: return "left"
        case .right: return "right"
        }
    }
}

enum PlayerRelativePosition {
    case front, behind, side
}
