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
    
    private var pauseNode: PauseMenuNode?
    private var gameOverNode: GameOverNode?
//    private var musicNode: SKAudioNode?

    
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
    var hearts: [HeartNode] = []
    var heartGridPosition: (row: Int, col: Int)? = nil
    let maxHealth: Int = 5 // Maximum hearts allowed
    
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
    var heartSprites: [SKSpriteNode] = [] // Array to hold heart sprites
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
        let baseSpeed = 0.6
        let calculatedSpeed = baseSpeed + (Double(level) * 0.01)
        
        // Set a maximum speed, for example, 2.5
        let maxSpeed = 1.1
        
        // Return the calculated speed, but not more than the max speed
        return min(calculatedSpeed, maxSpeed)
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
            return Int.random(in: 25...32)
        } else if level <= 10 {
            return Int.random(in: 17...24)
        } else {
            return Int.random(in: 9...16)
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
        setupBackground()
        
        currentMaze = getMazeLayout(for: level)
        
        // Setup initial player position first
        setupInitialPlayerPosition()
        
        // Setup maze but don't show items yet
        setupMaze(maze: currentMaze)
        
        // Setup UI and instruction screen
        debugFonts()
        setupUIWithFixedFonts()
        showSwipeInstruction()
        
        playMusicIfEnabled(named: "HeatleyBros - HeatleyBros I - 13 8 Bit Summer", on: self)
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
        swipeInstructionNode.size = CGSize(width: 278, height: 233)
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
    
    func setupBackground() {
            let tileSize = CGSize(width: gridSize, height: gridSize)

            let mazePixelWidth = CGFloat(mazeWidth) * gridSize
            let mazePixelHeight = CGFloat(mazeHeight) * gridSize
            let offsetX = (size.width - mazePixelWidth)/2
            let offsetY = (size.height - mazePixelHeight)/2

            let extraTiles: CGFloat = 3

            let minX = offsetX - extraTiles * gridSize
            let maxX = offsetX + mazePixelWidth + extraTiles * gridSize
            let minY = offsetY - extraTiles * gridSize
            let maxY = offsetY + mazePixelHeight + extraTiles * gridSize

            let columns = Int((maxX - minX)/gridSize)
            let rows = Int((maxY - minY)/gridSize)

            for row in 0 ..< rows {
                for col in 0 ..< columns {
                    let pos = CGPoint(
                        x: minX + CGFloat(col) * gridSize + gridSize/2,
                        y: minY + CGFloat(row) * gridSize + gridSize/2
                    )

                    let grass = SKSpriteNode(texture: SKTexture(imageNamed: "pathGrass"), size: tileSize)
                    grass.position = pos
                    grass.zPosition = -100
                    addChild(grass)

                    if Int.random(in: 0 ..< 10) == 0 {
                        let tree = SKSpriteNode(texture: SKTexture(imageNamed: "pathTree"), size: tileSize)
                        tree.position = pos
                        tree.zPosition = -90
                        addChild(tree)
                    }
                }
            }
        }
    
    func setupUI() {
        // Calculate positions for space-between layout
        let margin: CGFloat = 40
        let availableWidth = size.width - (margin * 2)
        let yPosition = size.height - 50
        
        // Create high score label
        var highScoreLabel: SKLabelNode!
        
        // Calculate positions for 4 elements with space-between
        let scoreX = margin
        let highScoreX = margin + (availableWidth * 0.33)
        let levelX = margin + (availableWidth * 0.66)
        let healthX = size.width - margin - 80 // Leave space for health icon
        
        // Create all labels with LuckiestGuy font
        scoreLabel = createLabel(text: "Score: 0", position: CGPoint(x: scoreX, y: yPosition))
        highScoreLabel = createLabel(text: "Best: \(ScoreManager.shared.highScore)", position: CGPoint(x: highScoreX, y: yPosition))
        levelLabel = createLabel(text: "Level: 1", position: CGPoint(x: levelX, y: yPosition))
        healthLabel = createLabel(text: "\(health)", position: CGPoint(x: healthX, y: yPosition))
        
        // Store high score label for updates
        highScoreLabel.name = "highScoreLabel"
        
        // Health icon positioned next to health label
        let healthSprite = SKSpriteNode(imageNamed: "HealthIcon")
        healthSprite.zPosition = 100
        healthSprite.position = CGPoint(x: healthX + 25, y: yPosition + 8)
        healthSprite.setScale(0.2)
        
        // Set z-positions based on game state
        if !gameStarted {
            scoreLabel.zPosition = 1001
            highScoreLabel.zPosition = 1001
            levelLabel.zPosition = 1001
            healthLabel.zPosition = 1001
            healthSprite.zPosition = 1001
        } else {
            scoreLabel.zPosition = 100
            highScoreLabel.zPosition = 100
            levelLabel.zPosition = 100
            healthLabel.zPosition = 100
            healthSprite.zPosition = 100
        }
        
        addChild(healthSprite)
        addChild(scoreLabel)
        addChild(highScoreLabel)
        addChild(levelLabel)
        addChild(healthLabel)
        
        // Pause button remains in top right
        let pauseButton = SKSpriteNode(imageNamed: "PauseButton")
        pauseButton.name = "pauseButton"
        pauseButton.position = CGPoint(x: size.width - 120, y: size.height - 50)
        pauseButton.zPosition = 100
        addChild(pauseButton)
    }
    
    func createLabel(text: String, position: CGPoint) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "LuckiestGuy-Regular")
        label.text = text
        label.fontSize = 20
        label.fontColor = .white
        label.position = position
        
        return label
    }
    
    func updateHighScoreDisplay() {
        if let highScoreLabel = childNode(withName: "highScoreLabel") as? SKLabelNode {
            highScoreLabel.text = "Best: \(ScoreManager.shared.highScore)"
        }
    }
    
    func setupMaze(maze: [[Int]]) {
        walls.forEach { $0.removeFromParent() }
        items.forEach { $0.removeFromParent() }
        pathTiles.forEach { $0.removeFromParent() }
        holes.forEach { $0.removeFromParent() }
        cats.forEach { $0.removeFromParent() }
        wagons.forEach { $0.removeFromParent() }
        hearts.forEach { $0.removeFromParent() } // Add heart cleanup
        
        walls.removeAll()
        items.removeAll()
        pathTiles.removeAll()
        holes.removeAll()
        cats.removeAll()
        wagons.removeAll()
        hearts.removeAll() // Add heart cleanup
        
        let wallColor = [UIColor.blue, .purple, .red, .green, .orange, .cyan][(level - 1) % 6]
        
        // Center the maze on screen
        let mazePixelWidth = CGFloat(mazeWidth) * gridSize
        let mazePixelHeight = CGFloat(mazeHeight) * gridSize
        let offsetX = (size.width - mazePixelWidth) / 2
        let offsetY = (size.height - mazePixelHeight) / 2
        
        determineItemPositions(maze: maze)
        
        // Determine heart position if this is a heart level
        if shouldSpawnHeart() {
            determineHeartPosition(maze: maze)
        }
        
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
    
    // MARK: - Add heart-related helper methods
    
    func shouldSpawnHeart() -> Bool {
        return level % 10 == 0 && level > 0 // Every 10 levels
    }
    
    func determineHeartPosition(maze: [[Int]]) {
        heartGridPosition = nil
        
        var availablePathPositions: [CGPoint] = []
        
        // Pre-calculate maze offset for hole position calculations
        let mazePixelWidth = CGFloat(mazeWidth) * gridSize
        let mazePixelHeight = CGFloat(mazeHeight) * gridSize
        let offsetX = (size.width - mazePixelWidth) / 2
        let offsetY = (size.height - mazePixelHeight) / 2
        
        // Look for path/road positions (0 = path, 1 = wall)
        for row in 2..<maze.count - 2 {
            for col in 2..<maze[row].count - 2 {
                guard maze[row][col] == 0 else { continue } // This is a path/road
                
                // Check if this position is far enough from player starting area (bottom-left)
                let isNearStart = row >= maze.count - 4 && col <= 4
                guard !isNearStart else { continue }
                
                // Check if this position is too close to any item
                let isTooCloseToItems = itemGridPositions.contains { itemPos in
                    let deltaRow = abs(itemPos.row - row)
                    let deltaCol = abs(itemPos.col - col)
                    return deltaRow <= 2 && deltaCol <= 2
                }
                guard !isTooCloseToItems else { continue }
                
                // Check if too close to holes (if any exist)
                var isTooCloseToHoles = false
                for hole in holes {
                    let holeWorldX = hole.position.x - offsetX
                    let holeWorldY = hole.position.y - offsetY
                    let holeGridX = Int(holeWorldX / gridSize)
                    let holeGridY = Int(holeWorldY / gridSize)
                    let holeGridRow = maze.count - holeGridY - 1
                    
                    let deltaRow = abs(row - holeGridRow)
                    let deltaCol = abs(col - holeGridX)
                    
                    if deltaRow <= 1 && deltaCol <= 1 {
                        isTooCloseToHoles = true
                        break
                    }
                }
                guard !isTooCloseToHoles else { continue }
                
                // Make sure it's not in a dead-end (has multiple path connections)
                let adjacentPositions = [
                    (row - 1, col),
                    (row + 1, col),
                    (row, col - 1),
                    (row, col + 1)
                ]
                
                var pathCount = 0
                for (adjRow, adjCol) in adjacentPositions {
                    let isInBounds = adjRow >= 0 && adjRow < maze.count && adjCol >= 0 && adjCol < maze[adjRow].count
                    if isInBounds && maze[adjRow][adjCol] == 0 {
                        pathCount += 1
                    }
                }
                
                let hasGoodConnectivity = pathCount >= 2
                guard hasGoodConnectivity else { continue }
                
                // All checks passed, add this position
                availablePathPositions.append(CGPoint(x: col, y: row))
            }
        }
        
        if let selectedPosition = availablePathPositions.randomElement() {
            heartGridPosition = (row: Int(selectedPosition.y), col: Int(selectedPosition.x))
            print("Heart will spawn on road at row: \(heartGridPosition!.row), col: \(heartGridPosition!.col)")
        } else {
            print("No suitable road position found for heart spawn")
        }
    }
    
    func spawnHeart() {
        guard let heartPos = heartGridPosition, gameStarted else { return }
        
        let mazePixelWidth = CGFloat(mazeWidth) * gridSize
        let mazePixelHeight = CGFloat(mazeHeight) * gridSize
        let offsetX = (size.width - mazePixelWidth) / 2
        let offsetY = (size.height - mazePixelHeight) / 2
        
        let heartSize = CGSize(width: gridSize * 0.5, height: gridSize * 0.5)
        let heart = HeartNode(size: heartSize)
        
        let heartPosition = CGPoint(
            x: offsetX + CGFloat(heartPos.col) * gridSize + gridSize/2,
            y: offsetY + CGFloat(currentMaze.count - heartPos.row - 1) * gridSize + gridSize/2
        )
        heart.position = heartPosition
        heart.zPosition = 11 // Above path tiles but below player
        
        addChild(heart)
        hearts.append(heart)
        
        print("Spawned heart on road at level \(level) at position \(heartPosition)")
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
        
        // Spawn regular items
        for (row, col) in itemGridPositions {
            let randomTime = getItemTimer()
            let itemSize = CGSize(width: gridSize * 0.6, height: gridSize * 0.6)
            let item = ItemNode(size: itemSize, initialTime: randomTime)
            
            let itemPosition = CGPoint(
                x: offsetX + CGFloat(col) * gridSize + gridSize/2,
                y: offsetY + CGFloat(currentMaze.count - row - 1) * gridSize + gridSize/2
            )
            item.position = itemPosition
            item.zPosition = 101
            
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
        
        // Spawn heart if this is a heart level
        if shouldSpawnHeart() {
            spawnHeart()
        }
        
        // Also spawn obstacles
        setupObstacles(maze: currentMaze,
                       offsetX: offsetX,
                       offsetY: offsetY)
        
        print("Spawned \(items.count) items and \(hearts.count) hearts after game started")
    }
    
    // MARK: - Add heart collection method
    
    func collectHeart(_ heart: HeartNode) {
        guard let index = hearts.firstIndex(of: heart) else { return }
        
        // Remove heart from array and scene
        hearts.remove(at: index)
        heart.removeFromParent()
        
        // Create collection effect
        let collectEffect = SKShapeNode(circleOfRadius: gridSize * 0.5)
        collectEffect.strokeColor = .systemRed
        collectEffect.lineWidth = 3
        collectEffect.fillColor = .clear
        collectEffect.position = heart.position
        collectEffect.zPosition = 20
        addChild(collectEffect)
        
        let expandAction = SKAction.scale(to: 2.0, duration: 0.3)
        let fadeAction = SKAction.fadeOut(withDuration: 0.3)
        let removeEffect = SKAction.removeFromParent()
        let effectSequence = SKAction.sequence([SKAction.group([expandAction, fadeAction]), removeEffect])
        collectEffect.run(effectSequence)
        
        // Check if player has max health
        if health >= maxHealth {
            // Give score instead - twice the green category points
            let greenCategoryPoints = ItemCategory.green.points
            let bonusScore = greenCategoryPoints * 2 * 10 * level
            score += bonusScore
            scoreLabel.text = "Score: \(score)"
            updateHighScoreDisplay()

            // Show bonus score message
            let label = SKLabelNode(fontNamed: "LuckiestGuy-Regular")
            label.text = "+\(bonusScore) (Max Hearts!)"
            label.fontSize = 20
            label.fontColor = .systemYellow
            label.position = CGPoint(x: heart.position.x, y: heart.position.y + 40)
            addChild(label)
            
            let moveUp = SKAction.moveBy(x: 0, y: 30, duration: 0.8)
            let fadeOut = SKAction.fadeOut(withDuration: 0.8)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([SKAction.group([moveUp, fadeOut]), remove])
            label.run(sequence)
            
            print("Player at max health, gave \(bonusScore) points instead")
            
        } else {
            // Increase health
            health += 1
            updateHeartDisplay() // Update visual hearts instead of text
            
            // Show health gain message
            let label = SKLabelNode(fontNamed: "LuckiestGuy-Regular")
            label.text = "+1 Life! ❤️"
            label.fontSize = 22
            label.fontColor = .systemRed
            label.position = CGPoint(x: heart.position.x, y: heart.position.y + 40)
            addChild(label)
            
            // Animate the health gain message
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.2)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
            let moveUp = SKAction.moveBy(x: 0, y: 30, duration: 0.8)
            let fadeOut = SKAction.fadeOut(withDuration: 0.8)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([
                SKAction.group([scaleUp, moveUp]),
                scaleDown,
                SKAction.group([fadeOut]),
                remove
            ])
            label.run(sequence)
            
            print("Health increased to \(health)")
        }
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
            // Player in front - wagon stops, player can still change direction
            if playerInFrontOfWagon != wagon {
                clearOtherWagonInteractions(except: wagon)
                
                playerInFrontOfWagon = wagon
                playerBehindWagon = nil
                playerAtSideOfWagon = nil
                playerBlockedBySide = false
                playerFollowingWagon = false
                
                wagon.setBlocked(true, reason: "Player in front")
                print("Player in front of wagon - wagon stopped, player can change direction")
            }
            
        case .playerBehind:
            // Player behind - wagon NEVER stops, continues moving and avoids player direction
            if playerBehindWagon != wagon {
                clearOtherWagonInteractions(except: wagon)
                
                playerBehindWagon = wagon
                playerInFrontOfWagon = nil
                playerAtSideOfWagon = nil
                playerBlockedBySide = false
                playerFollowingWagon = true
                
                // CRITICAL: Wagon must NEVER be blocked when player is behind
                // Ensure wagon continues moving normally
                wagon.setBlocked(false, reason: "Player behind - wagon must continue moving")
                wagon.resumeNormalMovement()
                
                print("Player behind wagon - wagon continues moving freely, player will follow")
            }
            
            // Double-check: if wagon was previously blocked, unblock it immediately
            if wagon.isCurrentlyBlocked() {
                wagon.setBlocked(false, reason: "Player behind - force unblock wagon")
                print("Forced wagon unblock - player is behind")
            }
            
        case .playerAtSide:
            // Player at side - only temporary stop when directly hitting wagon
            if playerAtSideOfWagon != wagon {
                clearOtherWagonInteractions(except: wagon)
                
                playerAtSideOfWagon = wagon
                playerInFrontOfWagon = nil
                playerBehindWagon = nil
                playerBlockedBySide = false // Player can move freely
                playerFollowingWagon = false
                
                // Wagon tries to escape, but player is not heavily restricted
                makeWagonEscapeFromPlayer(wagon, playerPosition: .side)
                print("Player at side of wagon - temporary interaction")
            }
            
        case .playerClear:
            // Player clear - normal movement
            var clearedInteraction = false
            
            if playerInFrontOfWagon == wagon {
                playerInFrontOfWagon = nil
                wagon.setBlocked(false, reason: "Player moved away from front")
                wagon.resumeNormalMovement()
                clearedInteraction = true
                print("Player no longer in front of wagon")
            }
            
            if playerBehindWagon == wagon {
                playerBehindWagon = nil
                playerFollowingWagon = false
                wagon.resumeNormalMovement()
                clearedInteraction = true
                print("Player no longer behind wagon")
            }
            
            if playerAtSideOfWagon == wagon {
                playerAtSideOfWagon = nil
                playerBlockedBySide = false
                wagon.resumeNormalMovement()
                clearedInteraction = true
                print("Player no longer at side of wagon")
            }
            
            if clearedInteraction {
                print("Wagon interaction cleared - normal movement resumed")
            }
        }
    }
    
    private func makeWagonEscapeFromPlayer(_ wagon: WagonObstacle, playerPosition: PlayerRelativePosition) {
        let wagonGridPos = wagon.getGridPosition()
        let playerGridPos = worldToGridPosition(player.position)
        
        // For side interactions, wagon only needs to move if directly blocked
        // Less aggressive escape behavior since player has more freedom
        let escapeDirections = findEscapeDirections(
            from: wagonGridPos,
            avoiding: playerGridPos,
            currentDirection: wagon.getCurrentDirection(),
            playerPosition: playerPosition
        )
        
        if escapeDirections.isEmpty {
            // No immediate escape needed - wagon can continue normal movement
            wagon.setBlocked(false, reason: "No escape needed - continuing normal movement")
            wagon.resumeNormalMovement()
            print("Wagon continuing normal movement - player has freedom to move")
        } else {
            // Gentle escape - wagon prefers escape directions but isn't forced
            wagon.setEscapeMode(escapeDirections: escapeDirections)
            print("Wagon gently adjusting path - escape directions: \(escapeDirections.map { $0.description })")
        }
    }

    
    // Helper method to find escape directions for wagon
    private func findEscapeDirections(from wagonPos: CGPoint, avoiding playerPos: CGPoint, currentDirection: MoveDirection, playerPosition: PlayerRelativePosition) -> [MoveDirection] {
        let allDirections: [MoveDirection] = [.up, .down, .left, .right]
        var escapeDirections: [MoveDirection] = []
        var secondaryDirections: [MoveDirection] = []
        
        for direction in allDirections {
            let nextPos = getNextPosition(from: wagonPos, direction: direction)
            
            // Check if this direction is valid (not wall, within bounds)
            if isValidRoadPosition(nextPos) {
                let currentDistanceToPlayer = hypot(wagonPos.x - playerPos.x, wagonPos.y - playerPos.y)
                let futureDistanceToPlayer = hypot(nextPos.x - playerPos.x, nextPos.y - playerPos.y)
                
                // For side interactions, be less aggressive - any direction that doesn't get closer is fine
                if futureDistanceToPlayer >= currentDistanceToPlayer - 0.3 {
                    escapeDirections.append(direction)
                } else {
                    // Still allow directions that get slightly closer as backup
                    secondaryDirections.append(direction)
                }
            }
        }
        
        // If no good escape directions, use any available direction
        if escapeDirections.isEmpty {
            escapeDirections = secondaryDirections
        }
        
        // For side interactions, don't force specific movement patterns
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
        
        // Start continuous collision checking with slightly less frequent updates for stability
        let checkAction = SKAction.repeatForever(.sequence([
            .run { [weak self] in self?.checkAllWagonCollisions() },
            .wait(forDuration: 0.15) // Slightly longer interval for more stability
        ]))
        run(checkAction, withKey: "wagonCollisionCheck")
    }
    
    func stopContinuousWagonCollisionCheck() {
        removeAction(forKey: "wagonCollisionCheck")
    }
    
    private func checkAllWagonCollisions() {
        guard gameStarted && !isTransitioning && !isGameOver && !isMoving else { return }
        
        var anyInteractionFound = false
        
        for wagon in wagons {
            let interactionType = checkIndividualWagonCollision(wagon)
            if interactionType != .playerClear {
                // Only handle interaction if it's different from current state
                if !isInteractionAlreadySet(wagon, interactionType) {
                    handleWagonInteraction(wagon, interactionType)
                }
                anyInteractionFound = true
            }
        }
        
        // Clear interactions that are no longer active, but only after a short delay
        // to prevent flickering between states
        if !anyInteractionFound {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.clearStaleWagonInteractions()
            }
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
        
        // Check each active interaction to see if it's still valid
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
        
        // FIXED: Calculate the difference correctly (player position - wagon position)
        let deltaX = playerGridPos.x - wagonGridPos.x
        let deltaY = playerGridPos.y - wagonGridPos.y
        
        // Debug output to help diagnose
        print("DEBUG: Player grid pos: (\(playerGridPos.x), \(playerGridPos.y))")
        print("DEBUG: Wagon grid pos: (\(wagonGridPos.x), \(wagonGridPos.y))")
        print("DEBUG: Delta (player - wagon): (\(deltaX), \(deltaY))")
        
        // Check if player is adjacent to wagon or on same position
        let isAdjacent = (abs(deltaX) == 1 && deltaY == 0) || (deltaX == 0 && abs(deltaY) == 1)
        let isOnSamePosition = deltaX == 0 && deltaY == 0
        let distance = hypot(deltaX, deltaY)
        
        print("DEBUG: Is adjacent: \(isAdjacent), same position: \(isOnSamePosition), distance: \(distance)")
        
        if isOnSamePosition || isAdjacent || distance <= 1.5 {
            // Determine the relative position based on wagon's current direction
            let interactionType = determineWagonInteractionType(deltaX: deltaX, deltaY: deltaY, wagon: wagon)
            print("DEBUG: Interaction type determined: \(interactionType)")
            return interactionType
        } else {
            print("DEBUG: Player too far from wagon")
            return .playerClear
        }
    }
    
    private func debugCoordinateConversion() {
        if let playerPos = player?.position,
           let wagon = wagons.first {
            let playerGrid = worldToGridPosition(playerPos)
            let wagonGrid = wagon.getGridPosition()
            
            print("DEBUG COORDINATES:")
            print("Player world: (\(playerPos.x), \(playerPos.y)) -> grid: (\(playerGrid.x), \(playerGrid.y))")
            print("Wagon world: (\(wagon.position.x), \(wagon.position.y)) -> grid: (\(wagonGrid.x), \(wagonGrid.y))")
            print("Wagon direction: \(wagon.getCurrentDirection().description)")
        }
    }
    
    private func determineWagonInteractionType(deltaX: CGFloat, deltaY: CGFloat, wagon: WagonObstacle) -> WagonObstacle.PlayerInteractionType {
        let directionVector = wagon.getCurrentDirection().vector
        
        // FIXED: More precise detection with correct coordinate system
        let threshold: CGFloat = 0.8
        
        // Calculate where "in front" and "behind" positions would be relative to wagon
        let frontX = directionVector.dx
        let frontY = directionVector.dy
        let behindX = -directionVector.dx
        let behindY = -directionVector.dy
        
        // Debug output to help diagnose the issue
        print("DEBUG: Wagon direction: \(wagon.getCurrentDirection().description)")
        print("DEBUG: Direction vector: dx=\(directionVector.dx), dy=\(directionVector.dy)")
        print("DEBUG: Player delta from wagon: dx=\(deltaX), dy=\(deltaY)")
        print("DEBUG: Front position would be: dx=\(frontX), dy=\(frontY)")
        print("DEBUG: Behind position would be: dx=\(behindX), dy=\(behindY)")
        
        // Check if player is behind wagon (more lenient detection)
        let behindDistance = hypot(deltaX - behindX, deltaY - behindY)
        if behindDistance < threshold {
            print("DEBUG: Player detected as BEHIND wagon (distance: \(behindDistance))")
            return .playerBehind
        }
        
        // Check if player is in front of wagon
        let frontDistance = hypot(deltaX - frontX, deltaY - frontY)
        if frontDistance < threshold {
            print("DEBUG: Player detected as IN FRONT of wagon (distance: \(frontDistance))")
            return .playerInFront
        }
        
        // Check if player is at the same position as wagon
        if abs(deltaX) < 0.5 && abs(deltaY) < 0.5 {
            print("DEBUG: Player at SAME POSITION as wagon")
            return .playerInFront // Treat as front collision
        }
        
        // Player is at the side of wagon
        let overallDistance = hypot(deltaX, deltaY)
        if overallDistance <= 1.2 {
            print("DEBUG: Player detected as AT SIDE of wagon (distance: \(overallDistance))")
            return .playerAtSide
        }
        
        print("DEBUG: Player detected as CLEAR from wagon")
        return .playerClear
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
        
        // Handle special case: player behind wagon with stop-and-follow behavior
        if playerFollowingWagon, let wagon = playerBehindWagon {
            handleStopAndFollowMovement(wagon)
            return
        }
        
        // SPECIAL CASE: Player in front of wagon - both stop, no auto movement
        if playerInFrontOfWagon != nil {
            // Player in front of wagon - only move if user manually swipes
            if let next = nextDirection, canMove(in: next) {
                currentDirection = next
                nextDirection = nil
                print("Player in front of wagon - manual direction change to: \(currentDirection.description)")
                
                let targetPosition = getTargetPosition(for: currentDirection)
                movePlayerToPosition(targetPosition)
            }
            // NO automatic forward movement when in front of wagon
            return
        }
        
        // NORMAL: Automatic forward movement for regular gameplay
        if let next = nextDirection, canMove(in: next) {
            currentDirection = next
            nextDirection = nil
            print("Direction changed to: \(currentDirection.description)")
        }
        
        // Try to move in current direction (automatic forward movement)
        if canMove(in: currentDirection) {
            let targetPosition = getTargetPosition(for: currentDirection)
            movePlayerToPosition(targetPosition)
        }
    }
    
    func handleStopAndFollowMovement(_ wagon: WagonObstacle) {
        // Check if player wants to break away from following
        if let next = nextDirection {
            let wagonGridPos = wagon.getGridPosition()
            let playerGridPos = worldToGridPosition(player.position)
            let wagonDirection = wagon.getCurrentDirection()
            
            // SPECIAL CASE: If player wants to turn around (opposite to wagon direction)
            let wagonOpposite = getOppositeDirection(wagonDirection)
            if next == wagonOpposite {
                // Player wants to turn around - check if they can move
                if canMove(in: next) {
                    currentDirection = next
                    nextDirection = nil
                    playerFollowingWagon = false
                    print("Player turning around - breaking away from wagon following")
                    
                    let targetPosition = getTargetPosition(for: currentDirection)
                    movePlayerToPosition(targetPosition)
                    return
                } else {
                    // Can't turn around - clear the direction and stay following
                    nextDirection = nil
                    print("Player can't turn around - staying behind wagon")
                    return
                }
            }
            
            // Regular break away logic for other directions
            let nextPlayerPos = getGridPositionInDirection(from: playerGridPos, direction: next)
            let distanceToWagonCurrent = hypot(playerGridPos.x - wagonGridPos.x, playerGridPos.y - wagonGridPos.y)
            let distanceToWagonNext = hypot(nextPlayerPos.x - wagonGridPos.x, nextPlayerPos.y - wagonGridPos.y)
            
            // Allow break away if moving away from or parallel to wagon
            if distanceToWagonNext >= distanceToWagonCurrent - 0.2 && canMove(in: next) {
                currentDirection = next
                nextDirection = nil
                playerFollowingWagon = false
                print("Player breaking away from following wagon")
                
                let targetPosition = getTargetPosition(for: currentDirection)
                movePlayerToPosition(targetPosition)
                return
            } else {
                // Can't break away in that direction - clear the queued direction
                nextDirection = nil
                print("Can't break away in that direction - staying behind wagon")
            }
        }
        
        // STOP-AND-FOLLOW LOGIC: Player only moves when wagon moves
        let wagonDirection = wagon.getCurrentDirection()
        
        // Only try to follow if:
        // 1. Wagon is not blocked (it's actually moving)
        // 2. Player can move in wagon's direction
        // 3. Player isn't already moving
        
        if !wagon.isCurrentlyBlocked() && !isMoving {
            if canMove(in: wagonDirection) {
                // Follow wagon with same timing
                currentDirection = wagonDirection
                
                let targetPosition = getTargetPosition(for: currentDirection)
                
                // Move with wagon's exact timing to create synchronized stop-and-follow
                isMoving = true
                let moveDuration = 0.8 // Match wagon's move duration exactly
                
                player.moveWithCustomDuration(to: targetPosition, duration: moveDuration) { [weak self] in
                    self?.isMoving = false
                    self?.updateHoleStatus()
                    self?.checkForItemCollection()
                    
                    // After following, player stops and waits for wagon's next move
                    print("Player completed follow movement - waiting for wagon's next move")
                }
                
                print("Player following wagon's movement in direction: \(wagonDirection.description)")
            } else {
                // Can't follow wagon in its direction - player stays stopped
                print("Player can't follow wagon - staying stopped until wagon moves to a followable direction")
            }
        } else if wagon.isCurrentlyBlocked() {
            // Wagon is stopped, player should also stay stopped
            print("Player waiting - wagon is stopped")
        } else {
            // Player is currently moving, let the movement complete
            print("Player currently moving - will check again after movement completes")
        }
    }

    
    func handleFollowingWagonMovement(_ wagon: WagonObstacle) {
        let wagonDirection = wagon.getCurrentDirection()
        
        // Check if player wants to change direction away from wagon
        if let next = nextDirection {
            // Allow player to break away if they're not moving toward the wagon
            let wagonGridPos = wagon.getGridPosition()
            let playerGridPos = worldToGridPosition(player.position)
            
            let nextPlayerPos = getGridPositionInDirection(from: playerGridPos, direction: next)
            let distanceToWagonCurrent = hypot(playerGridPos.x - wagonGridPos.x, playerGridPos.y - wagonGridPos.y)
            let distanceToWagonNext = hypot(nextPlayerPos.x - wagonGridPos.x, nextPlayerPos.y - wagonGridPos.y)
            
            // Allow break away if not moving closer to wagon
            if distanceToWagonNext >= distanceToWagonCurrent && canMove(in: next) {
                currentDirection = next
                nextDirection = nil
                playerFollowingWagon = false
                print("Player breaking away from wagon - direction changed to: \(currentDirection.description)")
                
                let targetPosition = getTargetPosition(for: currentDirection)
                movePlayerToPosition(targetPosition)
                return
            }
        }
        
        // Continue following wagon in wagon's direction
        if canMove(in: wagonDirection) {
            currentDirection = wagonDirection
            nextDirection = nil // Clear queued direction that can't be executed
            
            let targetPosition = getTargetPosition(for: currentDirection)
            movePlayerToPosition(targetPosition)
            print("Player following wagon in direction: \(wagonDirection.description)")
        } else {
            // Can't follow wagon - try to move in any safe direction
            let safeMoveDirections: [MoveDirection] = [.up, .down, .left, .right]
            for direction in safeMoveDirections {
                if canMove(in: direction) {
                    currentDirection = direction
                    let targetPosition = getTargetPosition(for: currentDirection)
                    movePlayerToPosition(targetPosition)
                    print("Player can't follow wagon, moving in safe direction: \(direction.description)")
                    break
                }
            }
        }
    }
    
    // Helper method to get grid position in a direction
    private func getGridPositionInDirection(from gridPos: CGPoint, direction: MoveDirection) -> CGPoint {
        let vector = direction.vector
        return CGPoint(x: gridPos.x + vector.dx, y: gridPos.y + vector.dy)
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
                
                playSoundIfEnabled(named: "padhole.wav", on: self)
                HapticHelper.trigger(.impact(.heavy))
                
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
                // Clear each type of interaction if it's with this wagon
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
            wagon.resumeNormalMovement()
        }
        
        print("All wagon interactions cleared")
    }

    
    private func isPositionWithinBounds(_ position: CGPoint) -> Bool {
        let mazePixelWidth = CGFloat(mazeWidth) * gridSize
        let mazePixelHeight = CGFloat(mazeHeight) * gridSize
        let offsetX = (size.width - mazePixelWidth) / 2
        let offsetY = (size.height - mazePixelHeight) / 2
        
        let mazeMinX = offsetX + gridSize/2
        let mazeMaxX = offsetX + mazePixelWidth - gridSize/2
        let mazeMinY = offsetY + gridSize/2
        let mazeMaxY = offsetY + mazePixelHeight - gridSize/2
        
        return position.x >= mazeMinX && position.x <= mazeMaxX &&
               position.y >= mazeMinY && position.y <= mazeMaxY
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
        
        let mazeMinX = offsetX + gridSize/2 // Add buffer to prevent going out of bounds
        let mazeMaxX = offsetX + mazePixelWidth - gridSize/2
        let mazeMinY = offsetY + gridSize/2
        let mazeMaxY = offsetY + mazePixelHeight - gridSize/2
        
        // ENHANCED BOUNDARY CHECK - prevent player from being pushed out of map
        if future.x < mazeMinX || future.x > mazeMaxX || future.y < mazeMinY || future.y > mazeMaxY {
            print("Movement blocked: would go out of bounds")
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
        
        // UPDATED WAGON INTERACTION HANDLING - Player in front = both stop completely
        
        // 1. Player in front of wagon - both entities stop completely
        if let wagon = playerInFrontOfWagon {
            // Block any movement that would maintain the front collision
            let wagonPos = wagon.position
            let distance = hypot(future.x - wagonPos.x, future.y - wagonPos.y)
            
            // Only allow movement that significantly increases distance (moving away)
            let currentDistance = hypot(player.position.x - wagonPos.x, player.position.y - wagonPos.y)
            
            if distance >= currentDistance + gridSize * 0.3 {
                // Moving away from wagon - allow
                print("Player in front can move \(direction.description) - moving away from wagon")
                return true
            } else {
                // Not moving away enough - block movement
                print("Movement blocked: player in front of wagon, not moving away enough")
                return false
            }
        }
        
        // 2. Player behind wagon - allow free movement (following is handled separately)
        if playerBehindWagon != nil {
            // Only check for direct collision
            if wagons.contains(where: { w in
                let distance = hypot(future.x - w.position.x, future.y - w.position.y)
                return distance < gridSize * 0.6 // Slightly smaller collision radius
            }) {
                return false
            }
            return true
        }
        
        // 3. Player at side of wagon - only block direct collision
        if let wagon = playerAtSideOfWagon {
            // Only block if movement would cause direct collision
            let distance = hypot(future.x - wagon.position.x, future.y - wagon.position.y)
            if distance < gridSize * 0.7 {
                print("Movement blocked: direct collision with wagon at side")
                return false
            }
            return true // Allow movement away from wagon
        }
        
        // 4. Check for new collisions with wagons (general case)
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
        
        // Calculate current and future distances from wagon
        let currentDistance = hypot(
            currentPlayerGridPos.x - wagonGridPos.x,
            currentPlayerGridPos.y - wagonGridPos.y
        )
        
        let futureDistance = hypot(
            futurePlayerGridPos.x - wagonGridPos.x,
            futurePlayerGridPos.y - wagonGridPos.y
        )
        
        // Allow movement if it increases distance from wagon (moving away)
        if futureDistance > currentDistance + 0.1 {
            print("Player can move \(direction.description) - moving away from wagon")
            return true
        }
        
        // Allow parallel movement (maintaining distance)
        if abs(futureDistance - currentDistance) <= 0.3 {
            print("Player can move \(direction.description) - parallel to wagon")
            return true
        }
        
        // For side interactions, be more permissive
        let distanceReduction = currentDistance - futureDistance
        if distanceReduction < 0.8 { // Allow slight approach
            print("Player can move \(direction.description) - minimal approach to wagon")
            return true
        }
        
        print("Player cannot move \(direction.description) - would get too close to wagon")
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
        var heartsToCollect: [HeartNode] = []
        
        // Check for item collection (items are on walls, so check adjacent positions)
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
        
        // Check for heart collection (hearts are on roads, so check same position or very close)
        for heart in hearts {
            let heartGridX = Int((heart.position.x - offsetX) / gridSize)
            let heartGridY = Int((heart.position.y - offsetY) / gridSize)
            
            let deltaX = playerGridX - heartGridX
            let deltaY = playerGridY - heartGridY
            
            // Check if player is on the same grid position as the heart or very close
            let isOnSamePosition = abs(deltaX) <= 0 && abs(deltaY) <= 0
            let isVeryClose = hypot(player.position.x - heart.position.x, player.position.y - heart.position.y) < gridSize * 0.7
            
            if isOnSamePosition || isVeryClose {
                heartsToCollect.append(heart)
            }
        }
        
        // Collect items
        if !itemsToCollect.isEmpty {
            collectMultipleItems(at: itemsToCollect)
        }
        
        // Collect hearts
        for heart in heartsToCollect {
            collectHeart(heart)
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

        // Show level complete message
        let label = SKLabelNode(fontNamed: "LuckiestGuy-Regular")
        label.text = "Level Complete!"
        label.fontSize = 25
        label.fontColor = .yellow
        label.position = CGPoint(x: size.width/2, y: size.height/2 + 100)
        addChild(label)
        label.run(.sequence([.fadeOut(withDuration: 1.5), .removeFromParent()]))
        
        // Play sound on Level Complete
        playSoundIfEnabled(named: "levelup.wav", on: label)
        
        // Run Haptic
        HapticHelper.trigger(.impact(.heavy))
        HapticHelper.trigger(.impact(.heavy))

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
        heartGridPosition = nil // Clear heart position
        
        // Clear hole effect for level transition
        player.hideSlowdownEffect()
        
        // Clear all wagon interactions properly
        clearAllWagonInteractions()
        
        currentMaze = nextMaze.isEmpty ? getMazeLayout(for: level) : nextMaze
        setupMaze(maze: currentMaze)
        spawnItems() // This will now also spawn hearts if needed
        findSafeStartingPosition()
        
        // Update obstacle references to new maze
        updateObstacleReferences()
        
        run(.sequence([
            .wait(forDuration: 0.1),
            .run { [weak self] in
                self?.startPlayerMovement() // This will also restart collision checking
                self?.isTransitioning = false
                print("Level transition complete - input and movement re-enabled")
                print("Level \(self?.level ?? 0) stats: Speed factor: \(self?.getPlayerSpeedFactor() ?? 0), Items: \(self?.getItemCount() ?? 0), Holes: \(self?.getHoleCount() ?? 0), Hearts: \(self?.hearts.count ?? 0)")
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
            updateHeartDisplay() // Update visual hearts instead of text
            
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
        let label = SKLabelNode(fontNamed: "LuckiestGuy-Regular")
        label.text = "Health Lost!"
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
        
//         Play sound on Game Over
        playSoundIfEnabled(named: "lose.wav", on: self)
        
//         Run Heptics
        HapticHelper.trigger(.impact(.heavy))
//         Create game over modal
        showGameOver()
        
//        print("Game Over!")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isGameOver == false else {
            for touch in touches {
                let location = touch.location(in: self)
                let node = atPoint(location)
                if node.name == "retryButton" || node.parent?.name == "retryButton" {
                    playSoundIfEnabled(named: "select.wav", on: self)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.hideGameOver()
                        self.restartGame()
                    }
                }
                
                if node.name == "quitButton" || node.parent?.name == "quitButton" {
                    playSoundIfEnabled(named: "select.wav", on: self)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.goToTitleScene()
                    }
                    return
                }
            }
            return
        }
        
        for touch in touches {
            let location = touch.location(in: self)
            let node = atPoint(location)
            
            // Pause Button
            if node.name == "pauseButton" || node.parent?.name == "pauseButton" {
                playSoundIfEnabled(named: "select.wav", on: self)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.showPauseMenu()
                }
                return
            }
            
            // Toggle SFX - Special handling needed
            if node.name == "sfxToggle" || node.parent?.name == "sfxToggle" {
                let sound = SKAction.playSoundFileNamed("select.wav", waitForCompletion: false)
                self.run(sound)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.pauseNode?.toggleSetting(named: "soundEffectsEnabled")
                }
                return
            }
            
            // Toggle Haptics
            if node.name == "hapticsToggle" || node.parent?.name == "hapticsToggle" {
                let sound = SKAction.playSoundFileNamed("select.wav", waitForCompletion: false)
                self.run(sound)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.pauseNode?.toggleSetting(named: "hapticsEnabled")
                }
                return
            }
            
            // Toggle Music
            if node.name == "musicToggle" || node.parent?.name == "musicToggle" {
                let sound = SKAction.playSoundFileNamed("select.wav", waitForCompletion: false)
                self.run(sound)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.pauseNode?.toggleSetting(named: "musicEnabled")
                    self.toggleMusic(on: self, fileName: "HeatleyBros - HeatleyBros I - 13 8 Bit Summer")
                }

                return
            }
            
            // Resume Game
            if node.name == "resumeButton" || node.parent?.name == "resumeButton" {
                playSoundIfEnabled(named: "select.wav", on: self)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.hidePauseMenu()
                }
                return
            }
            
            //
            if node.name == "quitButton" || node.parent?.name == "quitButton" {
                playSoundIfEnabled(named: "select.wav", on: self)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.goToTitleScene()
                }
                return
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
        health = 3 // Start with 3 hearts
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
        heartGridPosition = nil
        
        // Clear heart sprites
        heartSprites.forEach { $0.removeFromParent() }
        heartSprites.removeAll()
        
        // Remove all children and start fresh
        removeAllChildren()
        
        // Clear arrays
        walls.removeAll()
        items.removeAll()
        pathTiles.removeAll()
        holes.removeAll()
        cats.removeAll()
        wagons.removeAll()
        hearts.removeAll()
        itemGridPositions.removeAll()
        
        // Restart the game
        didMove(to: view!)
    }
    
    private func addItemToGame(_ item: ItemNode) {
        addChild(item)
        items.append(item)
        
        // If game is currently paused, pause this new item too
        if isPaused {
            item.pauseTimer()
        }
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

            // Remove the item and track collection
            item.removeFromParent()
            items.remove(at: index)
            collectedItems += 1
        }
        
        score += totalPoints
        scoreLabel.text = "Score: \(score)"
        
        // Play sound on collection
        playSoundIfEnabled(named: "packagesent.wav", on: self)
        
        // Play Haptic
        HapticHelper.trigger(.impact(.medium))
        HapticHelper.trigger(.impact(.medium))
        
        // Show combined score feedback
        let label = SKLabelNode(fontNamed: "LuckiestGuy-Regular")
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
    
    func showPauseMenu() {
        isPaused = true
        
        pauseAllItems()
        
        if pauseNode == nil {
            pauseNode = PauseMenuNode()
            pauseNode?.position = CGPoint(x: frame.midX, y: frame.midY)
            pauseNode?.zPosition = 100
            addChild(pauseNode!)
        }
    }


    func hidePauseMenu() {
        pauseNode?.removeFromParent()
        pauseNode = nil
        isPaused = false
        
        resumeAllItems()
    }
    
    // MARK: - Item Pause/Resume Methods

    private func pauseAllItems() {
        for item in items {
            item.pauseTimer()
        }
        print("Paused \(items.count) item timers")
    }

    private func resumeAllItems() {
        for item in items {
            item.resumeTimer()
        }
        print("Resumed \(items.count) item timers")
    }
    
    func showGameOver() {
        if gameOverNode == nil {
            gameOverNode = GameOverNode(score: score, level: level)
            gameOverNode?.position = CGPoint(x: frame.midX, y: frame.midY)
            gameOverNode?.zPosition = 100
            addChild(gameOverNode!)
        }
    }


    func hideGameOver() {
        gameOverNode?.removeFromParent()
        gameOverNode = nil
        isGameOver = false
    }
    
    func goToTitleScene() {
        if let view = self.view {
            let transition = SKTransition.fade(withDuration: 0.5)
            let mainMenuScene = TitleScene(size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
            mainMenuScene.scaleMode = .aspectFill
            view.presentScene(mainMenuScene, transition: transition)
        }
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
        
        // Check for player-heart collision
        if a.categoryBitMask == PlayerNode.category && b.categoryBitMask == HeartNode.categoryBitMask {
            if let heartNode = b.node as? HeartNode {
                collectHeart(heartNode)
            }
        } else if b.categoryBitMask == PlayerNode.category && a.categoryBitMask == HeartNode.categoryBitMask {
            if let heartNode = a.node as? HeartNode {
                collectHeart(heartNode)
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

// MARK: - Immediate Font Fix Extension
// Add this to fix all your font issues at once

extension SKLabelNode {
    
    // Helper to set LuckiestGuy font with automatic fallback
    func setLuckiestGuyFont(size: CGFloat) {
        // Try multiple possible font names for LuckiestGuy
        let possibleFontNames = [
            "LuckiestGuy-Regular",
            "LuckiestGuy",
            "Luckiest Guy",
            "LuckiestGuyRegular"
        ]
        
        var fontFound = false
        
        for fontName in possibleFontNames {
            if UIFont(name: fontName, size: size) != nil {
                self.fontName = fontName
                self.fontSize = size
                fontFound = true
                print("✅ Using font: \(fontName)")
                break
            }
        }
        
        if !fontFound {
            // Fallback to system font
            self.fontName = "Helvetica-Bold"
            self.fontSize = size
            print("❌ LuckiestGuy not found, using Helvetica-Bold fallback")
        }
    }
}

// MARK: - Quick Fix for GameScene
// Replace your font usage with these:

extension GameScene {
    
    func createLabelFixed(text: String, position: CGPoint, fontSize: CGFloat = 20) -> SKLabelNode {
        let label = SKLabelNode()
        label.text = text
        label.setLuckiestGuyFont(size: fontSize)
        label.position = position
        label.fontColor = .white
        return label
    }
    
    // Fix your current setupUI method by replacing it with this:
    func setupUIWithFixedFonts() {
        // Calculate positions for space-between layout
        let margin: CGFloat = 40
        let availableWidth = size.width - (margin * 2)
        let yPosition = size.height - 35
        
        // Create high score label
        var highScoreLabel: SKLabelNode!
        
        // Calculate positions for 3 elements (removed health from text labels)
        let scoreX = margin + 100
        let levelX = margin + (availableWidth * (0.5 -  0.075))
        let highScoreX = margin + (availableWidth * 0.85)
        
        // Create labels with LuckiestGuy font
        scoreLabel = createLabel(text: "Score: 0", position: CGPoint(x: scoreX, y: yPosition))
        highScoreLabel = createLabel(text: "High Score: \(ScoreManager.shared.highScore)", position: CGPoint(x: highScoreX, y: yPosition))
        levelLabel = createLabel(text: "Level: 1", position: CGPoint(x: levelX, y: yPosition))
        
        // Store high score label for updates
        highScoreLabel.name = "highScoreLabel"
        
        // Setup heart-based health display
        setupHeartHealthDisplay()
        
        // Set z-positions based on game state
        if !gameStarted {
            scoreLabel.zPosition = 1001
            highScoreLabel.zPosition = 1001
            levelLabel.zPosition = 1001
        } else {
            scoreLabel.zPosition = 100
            highScoreLabel.zPosition = 100
            levelLabel.zPosition = 100
        }
        
        addChild(scoreLabel)
        addChild(highScoreLabel)
        addChild(levelLabel)
        
        // Pause button remains in top right
        let pauseButton = SKSpriteNode(imageNamed: "PauseButton")
        pauseButton.name = "pauseButton"
        pauseButton.position = CGPoint(x: size.width - 60, y: size.height - 40)
        pauseButton.zPosition = 100
        addChild(pauseButton)
    }
    
    func setupHeartHealthDisplay() {
        // Clear existing heart sprites
        heartSprites.forEach { $0.removeFromParent() }
        heartSprites.removeAll()
        
        let heartSize: CGFloat = 24 // Size of each heart
        let heartSpacing: CGFloat = 26 // Space between hearts
        let totalWidth = CGFloat(maxHealth) * heartSpacing - (heartSpacing - heartSize)
        let startX = size.width - 280 - totalWidth // Position from right side
        let heartY = size.height - 27
        
        // Create heart sprites for max health
        for i in 0..<maxHealth {
            let heartSprite = SKSpriteNode(imageNamed: "HealthIcon")
            heartSprite.size = CGSize(width: heartSize, height: heartSize)
            heartSprite.position = CGPoint(x: startX + (CGFloat(i) * heartSpacing), y: heartY)
            
            // Set z-position based on game state
            if !gameStarted {
                heartSprite.zPosition = 1001
            } else {
                heartSprite.zPosition = 100
            }
            
            heartSprites.append(heartSprite)
            addChild(heartSprite)
        }
        
        // Update display to show current health
        updateHeartDisplay()
    }
    
    func updateHeartDisplay() {
        for (index, heartSprite) in heartSprites.enumerated() {
            if index < health {
                // Show filled heart (red)
                heartSprite.texture = SKTexture(imageNamed: "HealthIcon")
                heartSprite.alpha = 1.0
            } else {
                // Show empty heart (gray) - replace "HealthIconGray" with your gray heart image name
                heartSprite.texture = SKTexture(imageNamed: "HealthGrayIcon")
                heartSprite.alpha = 1.0
            }
        }
    }
}

// MARK: - Fix Existing Labels (call this after creating labels)
extension GameScene {
    
    func fixAllExistingFonts() {
        // Fix any existing labels that aren't showing correct font
        for child in children {
            if let label = child as? SKLabelNode {
                let currentText = label.text
                let currentSize = label.fontSize
                let currentPosition = label.position
                let currentColor = label.fontColor
                
                // Re-apply the font
                label.setLuckiestGuyFont(size: currentSize)
                label.fontColor = currentColor
                
                print("Fixed font for label: \(currentText ?? "NO TEXT")")
            }
        }
    }
}

// MARK: - Font Debugging Helper
// Add this to your GameScene or any view controller to debug fonts

extension GameScene {
    
    // Call this in didMove(to view:) to debug font issues
    func debugFonts() {
        print("=== FONT DEBUGGING ===")
        
        // 1. Check if font file is loaded
        let fontNames = UIFont.familyNames.sorted()
        print("All available font families:")
        for family in fontNames {
            let fonts = UIFont.fontNames(forFamilyName: family)
            if family.lowercased().contains("luckiest") || !fonts.isEmpty {
                print("Family: \(family)")
                for font in fonts {
                    print("  - \(font)")
                }
            }
        }
        
        // 2. Test font loading
        if let font = UIFont(name: "LuckiestGuy-Regular", size: 20) {
            print("✅ LuckiestGuy-Regular loaded successfully")
            print("Font family name: \(font.familyName)")
            print("Font display name: \(font.fontName)")
        } else {
            print("❌ LuckiestGuy-Regular failed to load")
            
            // Try alternative names
            let alternativeNames = [
                "LuckiestGuy",
                "Luckiest Guy",
                "LuckiestGuyRegular",
                "luckiest-guy",
                "luckiest_guy"
            ]
            
            for name in alternativeNames {
                if let font = UIFont(name: name, size: 20) {
                    print("✅ Found font with name: \(name)")
                    print("Real font name: \(font.fontName)")
                    break
                }
            }
        }
        
        print("=== END FONT DEBUG ===")
    }
    
    // Helper method to create labels with proper font fallback
    func createLabelWithFont(text: String, fontSize: CGFloat, position: CGPoint) -> SKLabelNode {
        let label = SKLabelNode()
        label.text = text
        label.fontSize = fontSize
        label.position = position
        
        // Try to set the custom font, fallback to system font
        if UIFont(name: "LuckiestGuy-Regular", size: fontSize) != nil {
            label.fontName = "LuckiestGuy-Regular"
            print("✅ Using LuckiestGuy-Regular for: \(text)")
        } else {
            // Fallback to bold system font
            label.fontName = "Helvetica-Bold"
            label.fontColor = .yellow // Make it obvious it's using fallback
            print("❌ Fallback font used for: \(text)")
        }
        
        return label
    }
}

// MARK: - Fixed Label Creation Methods
extension GameScene {
    
//    func createLabel(text: String, position: CGPoint) -> SKLabelNode {
//        return createLabelWithFont(text: text, fontSize: 20, position: position)
//    }
    
    // Update your existing setupUI method
    func setupUIFixed() {
        // Position UI elements relative to screen size
        let margin: CGFloat = 20
        
        // Use the fixed font method
        scoreLabel = createLabelWithFont(text: "Score: 0", fontSize: 20, position: CGPoint(x: margin + 120, y: size.height - 50))
        scoreLabel.fontColor = .white
        
        levelLabel = createLabelWithFont(text: "Level: 1", fontSize: 20, position: CGPoint(x: margin + 300, y: size.height - 50))
        levelLabel.fontColor = .white
        
        healthLabel = createLabelWithFont(text: "3", fontSize: 20, position: CGPoint(x: margin + 400, y: size.height - 50))
        healthLabel.fontColor = .white
        
        let healthSprite = SKSpriteNode(imageNamed: "HealthIcon")
        healthSprite.zPosition = 100
        healthSprite.position = CGPoint(x: margin + 418, y: size.height - 42)
        healthSprite.setScale(0.2)
        
        if !gameStarted {
            scoreLabel.zPosition = 1001
            healthLabel.zPosition = 1001
            levelLabel.zPosition = 1001
        } else {
            scoreLabel.zPosition = 10
            healthLabel.zPosition = 10
            levelLabel.zPosition = 10
        }
        
        addChild(healthSprite)
        addChild(scoreLabel)
        addChild(levelLabel)
        addChild(healthLabel)
        
        let pauseButton = SKSpriteNode(imageNamed: "PauseButton")
        pauseButton.name = "pauseButton"
        pauseButton.position = CGPoint(x: size.width - 120, y: size.height - 50)
        pauseButton.zPosition = 100
        addChild(pauseButton)
    }
}
