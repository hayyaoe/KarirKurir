////
////  GameOverModal.swift
////  KarirKurir
////
////  Game Over Modal for collection efficiency tracking
////
//
//import SpriteKit
//
//class GameOverModal: SKNode {
//    private let modalBackground: SKShapeNode
//    private let retryButton: SKShapeNode
//    private let retryLabel: SKLabelNode
//    private let titleLabel: SKLabelNode
//    private let messageLabel: SKLabelNode
//    
//    var onRetryTapped: (() -> Void)?
//    
//    override init() {
//        // Create modal background
//        modalBackground = SKShapeNode(rectOf: CGSize(width: 300, height: 200), cornerRadius: 20)
//        modalBackground.fillColor = SKColor.black.withAlphaComponent(0.9)
//        modalBackground.strokeColor = .white
//        modalBackground.lineWidth = 2
//        
//        // Create retry button
//        retryButton = SKShapeNode(rectOf: CGSize(width: 120, height: 40), cornerRadius: 10)
//        retryButton.fillColor = .systemGreen
//        retryButton.strokeColor = .white
//        retryButton.lineWidth = 2
//        
//        // Create retry label
//        retryLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
//        retryLabel.text = "RETRY"
//        retryLabel.fontSize = 18
//        retryLabel.fontColor = .white
//        
//        // Create title label
//        titleLabel = SKLabelNode(fontNamed: "Arial-BoldMT")
//        titleLabel.text = "GAME OVER"
//        titleLabel.fontSize = 24
//        titleLabel.fontColor = .red
//        
//        // Create message label
//        messageLabel = SKLabelNode(fontNamed: "Arial")
//        messageLabel.text = "Too many items expired!"
//        messageLabel.fontSize = 16
//        messageLabel.fontColor = .white
//        
//        super.init()
//        
//        setupLayout()
//        setupTouchHandling()
//    }
//    
//    required init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    private func setupLayout() {
//        // Position elements
//        titleLabel.position = CGPoint(x: 0, y: 50)
//        messageLabel.position = CGPoint(x: 0, y: 10)
//        retryButton.position = CGPoint(x: 0, y: -40)
//        retryLabel.position = CGPoint(x: 0, y: -45)
//        
//        // Add to modal
//        addChild(modalBackground)
//        addChild(titleLabel)
//        addChild(messageLabel)
//        addChild(retryButton)
//        addChild(retryLabel)
//        
//        // Set z-position to appear on top
//        zPosition = 1000
//    }
//    
//    private func setupTouchHandling() {
//        retryButton.isUserInteractionEnabled = true
//    }
//    
//    func show(in scene: SKScene) {
//        scene.addChild(self)
//        position = CGPoint(x: scene.size.width/2, y: scene.size.height/2)
//        
//        // Animation
//        alpha = 0
//        setScale(0.5)
//        
//        let fadeIn = SKAction.fadeIn(withDuration: 0.3)
//        let scaleUp = SKAction.scale(to: 1.0, duration: 0.3)
//        let appear = SKAction.group([fadeIn, scaleUp])
//        appear.timingMode = .easeOut
//        
//        run(appear)
//    }
//    
//    func hide() {
//        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
//        let scaleDown = SKAction.scale(to: 0.8, duration: 0.2)
//        let disappear = SKAction.group([fadeOut, scaleDown])
//        
//        run(disappear) {
//            self.removeFromParent()
//        }
//    }
//    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        guard let touch = touches.first else { return }
//        let location = touch.location(in: self)
//        
//        if retryButton.contains(location) {
//            // Button press animation
//            let scaleDown = SKAction.scale(to: 0.95, duration: 0.1)
//            let scaleUp = SKAction.scale(to: 1.0, duration: 0.1)
//            let press = SKAction.sequence([scaleDown, scaleUp])
//            
//            retryButton.run(press) {
//                self.onRetryTapped?()
//            }
//        }
//    }
//}
//
//// MARK: - Game Efficiency Tracking
//
//extension GameScene {
//    // Add these properties to GameScene
//    private var totalItemsSpawned: Int = 0
//    private var totalItemsCollected: Int = 0
//    private var totalItemsExpired: Int = 0
//    private var gameOverModal: GameOverModal?
//    
//    // Call this when spawning items
//    func trackItemSpawned() {
//        totalItemsSpawned += 1
//        print("Items spawned: \(totalItemsSpawned)")
//    }
//    
//    // Call this when collecting items
//    func trackItemCollected() {
//        totalItemsCollected += 1
//        print("Items collected: \(totalItemsCollected), Success rate: \(getSuccessRate())%")
//    }
//    
//    // Call this when items expire
//    func trackItemExpired() {
//        totalItemsExpired += 1
//        print("Items expired: \(totalItemsExpired), Success rate: \(getSuccessRate())%")
//        
//        // Check if game should end
//        checkGameOverCondition()
//    }
//    
//    private func getSuccessRate() -> Double {
//        guard totalItemsSpawned > 0 else { return 100.0 }
//        return Double(totalItemsCollected) / Double(totalItemsSpawned) * 100.0
//    }
//    
//    private func checkGameOverCondition() {
//        // Only check after a minimum number of items have been spawned
//        guard totalItemsSpawned >= 5 else { return }
//        
//        let successRate = getSuccessRate()
//        
//        // If success rate drops below 10% (meaning 90% or more items expired), game over
//        if successRate < 10.0 {
//            triggerGameOver()
//        }
//    }
//    
//    private func triggerGameOver() {
//        // Pause the game
//        removeAction(forKey: "playerMovement")
//        
//        // Stop all item timers
//        items.forEach { item in
//            item.removeAllActions()
//        }
//        
//        // Show game over modal
//        gameOverModal = GameOverModal()
//        gameOverModal?.onRetryTapped = { [weak self] in
//            self?.restartGame()
//        }
//        
//        gameOverModal?.show(in: self)
//        
//        print("GAME OVER! Success rate: \(getSuccessRate())%")
//    }
//    
//    private func restartGame() {
//        // Hide modal
//        gameOverModal?.hide()
//        gameOverModal = nil
//        
//        // Reset tracking variables
//        totalItemsSpawned = 0
//        totalItemsCollected = 0
//        totalItemsExpired = 0
//        
//        // Reset game state
//        score = 0
//        level = 1
//        
//        // Update UI
//        scoreLabel.text = "Score: 0"
//        levelLabel.text = "Level: 1"
//        
//        // Clear current items and walls
//        items.forEach { $0.removeFromParent() }
//        walls.forEach { $0.removeFromParent() }
//        pathTiles.forEach { $0.removeFromParent() }
//        
//        items.removeAll()
//        walls.removeAll()
//        pathTiles.removeAll()
//        
//        // Reset player position and direction
//        currentDirection = .right
//        nextDirection = nil
//        
//        // Setup new maze
//        currentMaze = getMazeLayout(for: level)
//        setupMaze(maze: currentMaze)
//        
//        // Reset player position
//        player.position = CGPoint(x: 50, y: 50)
//        
//        // Restart movement
//        startPlayerMovement()
//        
//        print("Game restarted!")
//    }
//}
//
//// MARK: - Updated ItemNode with tracking
//
//extension ItemNode {
//    func setupTimerWithTracking(gameScene: GameScene) {
//        // Replace the existing onTimerExpired logic
//        onTimerExpired = { [weak self, weak gameScene] in
//            guard let self = self, let gameScene = gameScene else { return }
//            
//            // Track expiration
//            gameScene.trackItemExpired()
//            
//            // Remove from items array
//            if let index = gameScene.items.firstIndex(of: self) {
//                gameScene.items.remove(at: index)
//            }
//            
//            // Remove from scene
//            self.removeFromParent()
//            
//            // Check if all items are collected/expired
//            if gameScene.items.isEmpty {
//                gameScene.nextLevel()
//            }
//        }
//    }
//}
