//
//  GameOverNode.swift
//  KarirKurir
//
//  Created by Hayya U on 22/07/25.
//
import SpriteKit

class GameOverNode: SKNode {
    
    private var score: Int = 0
    private var level: Int = 1
    
    init(score: Int, level: Int) {
        super.init()
        self.score = score
        self.level = level
        setupGameOver()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupGameOver()
    }


    private func setupGameOver(){
        
        let overlay = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.5), size: UIScreen.main.bounds.size)
        overlay.position = CGPoint.zero
        overlay.zPosition = 99
        overlay.name = "gameOverOverlay"
        overlay.alpha = 0.8
        
        addChild(overlay)
                
        // Create modal background
        let modal = SKSpriteNode(imageNamed: "GameOverBackground")
        modal.zPosition = 100
        modal.name = "gameOverBackground"
        modal.position = CGPoint(x: 0, y: 40)
        modal.setScale(0.5)
        addChild(modal)
        
        // Final score
        let scoreText = SKLabelNode(fontNamed: "LuckiestGuy-Regular")
        scoreText.text = "Final Score: \(score)"
        scoreText.fontSize = 28
        scoreText.fontColor = .white
        scoreText.position = CGPoint(x: 0, y: 0)
        scoreText.zPosition = 102
        modal.addChild(scoreText)
        
        // Level reached
        let levelText = SKLabelNode(fontNamed: "LuckiestGuy-Regular")
        levelText.text = "Level Reached: \(level)"
        levelText.fontSize = 28
        levelText.fontColor = .white
        levelText.position = CGPoint(x: 0, y: -50)
        levelText.zPosition = 102
        modal.addChild(levelText)
        
        // Retry button
        let retryButton = SKSpriteNode(imageNamed: "RetryButton")
        retryButton.name = "retryButton"
        retryButton.position = CGPoint(x: -100, y: -120)
        retryButton.zPosition = 103
        retryButton.setScale(0.95)
        addChild(retryButton)
        
        let quitButton = SKSpriteNode(imageNamed: "QuitButtonGameOver")
        quitButton.name = "quitButton"
        quitButton.position = CGPoint(x: 100, y: -120)
        quitButton.zPosition = 103
        quitButton.setScale(0.95)
        addChild(quitButton)
        
        // Animate modal appearance
        modal.setScale(0)
        let scaleAction = SKAction.scale(to: 1.0, duration: 0.3)
        scaleAction.timingMode = .easeOut
        modal.run(scaleAction)
    }
}
