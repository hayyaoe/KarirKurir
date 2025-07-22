//
//  TitleScene.swift
//  KarirKurir
//
//  Created by Mahardika Putra Wardhana on 16/07/25.
//

import SpriteKit

class TitleScene: SKScene {
    var player: SKSpriteNode
    var cat: SKSpriteNode
    var bakso: SKSpriteNode
    let tileSize: CGFloat = 40
    let scrollSpeed: CGFloat = 100.0
    let playButton: SKSpriteNode

    var pathTiles: [SKSpriteNode] = []
    var wallTiles: [SKSpriteNode] = []
    
    private var settingNode: SettingNode!

    override init(size: CGSize) {
        player = SKSpriteNode(imageNamed: "courierRight1")
        player.scale(to: CGSize(width: tileSize * 4, height: tileSize * 4))
        player.position = CGPoint(x: size.width / 2 + 25, y: size.height / 2)
        player.zPosition = 2
        let frames = (1 ... 4).map { SKTexture(imageNamed: "courierRight\($0)") }
        let walk = SKAction.animate(with: frames, timePerFrame: 0.15)
        player.run(SKAction.repeatForever(walk))

        cat = SKSpriteNode(imageNamed: "obstacleCatRight1")
        cat.scale(to: CGSize(width: tileSize * 2, height: tileSize * 2))
        cat.position = CGPoint(x: size.width / 2 + 5, y: size.height / 2 - 50)
        cat.zPosition = 3
        let framesCat = (1 ... 4).map { SKTexture(imageNamed: "obstacleCatRight\($0)") }
        let walkCat = SKAction.animate(with: framesCat, timePerFrame: 0.15)
        cat.run(SKAction.repeatForever(walkCat))

        bakso = SKSpriteNode(imageNamed: "obstacleWagonRight1")
        bakso.scale(to: CGSize(width: tileSize * 4, height: tileSize * 4))
        bakso.position = CGPoint(x: size.width / 2 - 120, y: size.height / 2)
        bakso.zPosition = 2
        let framesBakso = (1 ... 4).map { SKTexture(imageNamed: "obstacleWagonRight\($0)") }
        let walkBakso = SKAction.animate(with: framesBakso, timePerFrame: 0.15)
        bakso.run(SKAction.repeatForever(walkBakso))
        
        playButton = SKSpriteNode(imageNamed: "PlayButton")
        playButton.name = "playButton"
        playButton.zPosition = 101
        playButton.position = CGPoint(x: 420, y: 80)
        playButton.setScale(0.45)
        
        let pauseButton = SKSpriteNode(imageNamed: "SettingButton")
        pauseButton.name = "settingButton"
        pauseButton.position = CGPoint(x: size.width - 120, y: size.height - 50)
        pauseButton.zPosition = 100

        super.init(size: size)
        addChild(player)
        addChild(cat)
        addChild(bakso)
        addChild(playButton)
        addChild(pauseButton)
        setupScrollingBackground()
        
        playMusicIfEnabled(named: "HeatleyBros - HeatleyBros I - 06 8 Bit Love", on: self)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupScrollingBackground() {
        let numberOfTiles = Int(ceil(size.width / (tileSize * 2))) + 2
        for i in 0 ..< numberOfTiles {
            let options = [
                "pathTree",
                "pathGrass",
            ]

            // Path
            let pathTile = SKSpriteNode(imageNamed: "pathHorizontal")
            pathTile.scale(to: CGSize(width: tileSize * 2, height: tileSize * 2))
            pathTile.position = CGPoint(x: CGFloat(i) * pathTile.size.width, y: player.position.y - 30)
            pathTile.zPosition = 1
            addChild(pathTile)
            pathTiles.append(pathTile)

            let wallTile = SKSpriteNode(imageNamed: options.randomElement()!)
            wallTile.scale(to: CGSize(width: tileSize * 2, height: tileSize * 2))
            wallTile.position = CGPoint(x: CGFloat(i) * wallTile.size.width, y: pathTile.position.y + tileSize * 2)
            wallTile.zPosition = 1
            addChild(wallTile)
            wallTiles.append(wallTile)

            let wallTile2 = SKSpriteNode(imageNamed: options.randomElement()!)
            wallTile2.scale(to: CGSize(width: tileSize * 2, height: tileSize * 2))
            wallTile2.position = CGPoint(x: CGFloat(i) * wallTile2.size.width, y: wallTile.position.y + tileSize * 2)
            wallTile2.zPosition = 1
            addChild(wallTile2)
            wallTiles.append(wallTile2)

            let wallTile3 = SKSpriteNode(imageNamed: "pathGrass")
            wallTile3.scale(to: CGSize(width: tileSize * 2, height: tileSize * 2))
            wallTile3.position = CGPoint(x: CGFloat(i) * wallTile3.size.width, y: wallTile2.position.y + tileSize * 2)
            wallTile3.zPosition = 1
            addChild(wallTile3)
            wallTiles.append(wallTile3)

            // Down
            let wallTile4 = SKSpriteNode(imageNamed: "pathGrass")
            wallTile4.scale(to: CGSize(width: tileSize * 2, height: tileSize * 2))
            wallTile4.position = CGPoint(x: CGFloat(i) * wallTile4.size.width, y: pathTile.position.y - tileSize * 2)
            wallTile4.zPosition = 1
            addChild(wallTile4)
            wallTiles.append(wallTile4)

            let wallTile5 = SKSpriteNode(imageNamed: options.randomElement()!)
            wallTile5.scale(to: CGSize(width: tileSize * 2, height: tileSize * 2))
            wallTile5.position = CGPoint(x: CGFloat(i) * wallTile5.size.width, y: wallTile4.position.y - tileSize * 2)
            wallTile5.zPosition = 1
            addChild(wallTile5)
            wallTiles.append(wallTile5)

//            let wallTile6 = SKSpriteNode(imageNamed:)
//            wallTile6.scale(to: CGSize(width: tileSize * 2, height: tileSize * 2))
//            wallTile6.position = CGPoint(x: CGFloat(i) * wallTile6.size.width, y: wallTile5.position.y - tileSize * 2)
//            wallTile6.zPosition = 1
//            addChild(wallTile6)
//            wallTiles.append(wallTile6)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        let deltaX = scrollSpeed * CGFloat(1.0 / 60.0) // asumsi 60 FPS

        for tile in pathTiles + wallTiles {
            tile.position.x -= deltaX

            // Reset posisi tile jika keluar dari kiri layar
            if tile.position.x < -tile.size.width {
                tile.position.x += tile.size.width * CGFloat(pathTiles.count)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let node = atPoint(location)
            
            // Play Button
            if node.name == "playButton" || node.parent?.name == "playButton" {
                // Add button press effect
                playButton.removeAllActions()
                node.childNode(withName: "backgroundMusic")?.removeFromParent()
                let pressDown = SKAction.scale(to: 0.35, duration: 0.1)
                let pressUp = SKAction.scale(to: 0.45, duration: 0.1)
                let sequence = SKAction.sequence([pressDown, pressUp])
                
                playSoundIfEnabled(named: "select.wav", on: self)
                
                playButton.run(sequence) {
                    // Navigate to game scene after animation
                    self.navigateToGameScene()
                }
                return
            }
            
            // Pause Button
            if node.name == "settingButton" || node.parent?.name == "settingButton" {
                playSoundIfEnabled(named: "select.wav", on: self)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.showSettingMenu()
                }
                return
            }
            
            // Toggle SFX - Special handling needed
            if node.name == "sfxToggle" || node.parent?.name == "sfxToggle" {
                let sound = SKAction.playSoundFileNamed("select.wav", waitForCompletion: false)
                self.run(sound)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.settingNode?.toggleSetting(named: "soundEffectsEnabled")
                }
                return
            }
            
            // Toggle Haptics
            if node.name == "hapticsToggle" || node.parent?.name == "hapticsToggle" {
                let sound = SKAction.playSoundFileNamed("select.wav", waitForCompletion: false)
                self.run(sound)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.settingNode?.toggleSetting(named: "hapticsEnabled")
                }
                return
            }
            
            // Toggle Music
            if node.name == "musicToggle" || node.parent?.name == "musicToggle" {
                let sound = SKAction.playSoundFileNamed("select.wav", waitForCompletion: false)
                self.run(sound)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.settingNode?.toggleSetting(named: "musicEnabled")
                    self.toggleMusic(on: self, fileName: "HeatleyBros - HeatleyBros I - 06 8 Bit Love")
                }

                return
            }
            
            // Resume Game
            if node.name == "closeButton" || node.parent?.name == "closeButton" {
                playSoundIfEnabled(named: "select.wav", on: self)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.hideSettingMenu()
                }
                return
            }
            
        }
    }
    
    func showSettingMenu() {
        if settingNode == nil {
            settingNode = SettingNode()
            settingNode?.position = CGPoint(x: frame.midX, y: frame.midY)
            settingNode?.zPosition = 100
            addChild(settingNode!)
        }
    }


    func hideSettingMenu() {
        settingNode?.removeFromParent()
        settingNode = nil
    }
    
    func navigateToGameScene() {
        let gameScene = GameScene()
        let screenBounds = UIScreen.main.bounds
        let screenSize = CGSize(width: screenBounds.width, height: screenBounds.height)
        gameScene.size = screenSize
        
        let transition = SKTransition.fade(withDuration: 1.0)
        self.view?.presentScene(gameScene, transition: transition)
    }
}
