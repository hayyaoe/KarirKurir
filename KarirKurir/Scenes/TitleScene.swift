//
//  TitleScene.swift - FIXED Initialization Order
//  KarirKurir
//
//  Created by Mahardika Putra Wardhana on 16/07/25.
//

import GameKit
import SpriteKit

class TitleScene: SKScene, GKGameCenterControllerDelegate {
    var player: SKSpriteNode
    var cat: SKSpriteNode
    var bakso: SKSpriteNode
    var leaderboardButton: SKSpriteNode
    var titleImage: SKSpriteNode
    let tileSize: CGFloat = 40
    let scrollSpeed: CGFloat = 100.0
    let playButton: SKSpriteNode

    var isIpad: Bool = false

    var pathTiles: [SKSpriteNode] = []
    var wallTiles: [SKSpriteNode] = []

    private var settingNode: SettingNode!

    // Store texture variants for animated sprites
    private let catTextureVariant: Int
    private let wagonTextureVariant: Int

    override init(size: CGSize) {
        // STEP 1: Initialize all stored properties FIRST
        catTextureVariant = Int.random(in: 1...4)
        wagonTextureVariant = Int.random(in: 1...2)

        // Create sprites with basic textures (no animations yet)
        player = SKSpriteNode(imageNamed: "courierRight1")
        cat = SKSpriteNode(imageNamed: "obstacleCatRight1_\(catTextureVariant)")
        bakso = SKSpriteNode(imageNamed: "obstacleWagonRight1_\(wagonTextureVariant)")
        titleImage = SKSpriteNode(imageNamed: "KarirKurirLogo")
        playButton = SKSpriteNode(imageNamed: "PlayButton")
        leaderboardButton = SKSpriteNode(imageNamed: "LeaderboardButton")

        // STEP 2: Call super.init() BEFORE any self references
        super.init(size: size)

        // STEP 3: Now we can safely setup everything that uses 'self'
        setupSprites()
        setupButtons()
        setupScrollingBackground()

        playMusicIfEnabled(named: "HeatleyBros - HeatleyBros I - 06 8 Bit Love", on: self)

        print("TitleScene created with cat variant \(catTextureVariant) and wagon variant \(wagonTextureVariant)")
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // STEP 4: Setup methods that can safely use 'self'
    private func setupSprites() {
        // Setup player
        player.scale(to: CGSize(width: tileSize * 4, height: tileSize * 4))
        player.position = CGPoint(x: size.width / 2 + 25, y: size.height / 2)
        player.zPosition = 2

        // Setup player animation
        let frames = (1...4).map { SKTexture(imageNamed: "courierRight\($0)") }
        let walk = SKAction.animate(with: frames, timePerFrame: 0.15)
        player.run(SKAction.repeatForever(walk))

        // Setup cat
        cat.scale(to: CGSize(width: tileSize * 2, height: tileSize * 2))
        cat.position = CGPoint(x: size.width / 2 + 5, y: size.height / 2 - 50)
        cat.zPosition = 3

        // Setup cat animation with randomized texture variant
        let framesCat = (1...4).map { SKTexture(imageNamed: "obstacleCatRight\($0)_\(catTextureVariant)") }
        let walkCat = SKAction.animate(with: framesCat, timePerFrame: 0.15)
        cat.run(SKAction.repeatForever(walkCat))

        // Setup wagon (bakso)
        bakso.scale(to: CGSize(width: tileSize * 4, height: tileSize * 4))
        bakso.position = CGPoint(x: size.width / 2 - 120, y: size.height / 2)
        bakso.zPosition = 2

        // Setup wagon animation with randomized texture variant
        let framesBakso = (1...4).map { SKTexture(imageNamed: "obstacleWagonRight\($0)_\(wagonTextureVariant)") }
        let walkBakso = SKAction.animate(with: framesBakso, timePerFrame: 0.15)
        bakso.run(SKAction.repeatForever(walkBakso))

        // Setup title image
        titleImage.position = CGPoint(x: size.width / 2, y: size.height / 1.3)
        titleImage.zPosition = 5
        titleImage.setScale(1.5)

        // Add title pulsing effect
        let scaleUp = SKAction.scale(to: 1.5, duration: 3.0)
        let scaleDown = SKAction.scale(to: 1.2, duration: 3.0)
        let pulse = SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown]))
        titleImage.run(pulse)

        // Add all sprites to scene
        addChild(player)
        addChild(cat)
        addChild(bakso)
    }

    private func setupButtons() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            isIpad = true
        }

        // Setup play button
        playButton.name = "playButton"
        playButton.zPosition = 101
        playButton.position = CGPoint(x: size.width / 2, y: isIpad ? size.height / 5 : size.height / 6)
        playButton.setScale(isIpad ? 0.7 : 0.45)

        // Setup setting button
        let settingButton = SKSpriteNode(imageNamed: "SettingButton")
        settingButton.name = "settingButton"
        settingButton.position = CGPoint(x: size.width - 60, y: size.height - 40)
        settingButton.zPosition = 100
        settingButton.setScale(isIpad ? 1.5 : 1.0)

        // Setup leaderboard button
        leaderboardButton.name = "leaderboardButton"
        leaderboardButton.zPosition = 5
        leaderboardButton.scale(to: CGSize(width: 42, height: 42))
        leaderboardButton.position = CGPoint(x: settingButton.position.x - (isIpad ? 80 : 50), y: settingButton.position.y)
        leaderboardButton.setScale(isIpad ? 1.5 : 1.0)

        // Setup title image
        titleImage.position = CGPoint(x: size.width / 2, y: size.height / 1.3)
        titleImage.zPosition = 5
        titleImage.setScale(isIpad ? 1.5 : 1.0)

        // Add title pulsing effect
        let scaleUp = SKAction.scale(to: isIpad ? 1.5 : 1.0, duration: 3.0)
        let scaleDown = SKAction.scale(to: isIpad ? 1.3 : 0.8, duration: 3.0)
        let pulse = SKAction.repeatForever(SKAction.sequence([scaleUp, scaleDown]))
        titleImage.run(pulse)

        // Add buttons to scene
        addChild(titleImage)
        addChild(playButton)
        addChild(settingButton)
        addChild(leaderboardButton)
    }

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true, completion: nil)
    }

    func setupScrollingBackground() {
        let numberOfTiles = Int(ceil(size.width / (tileSize * 2))) + 2
        for i in 0 ..< numberOfTiles {
            let treeVariant = Int.random(in: 1...6)
            let options = [
                "pathTree\(treeVariant)",
                "pathGrass1",
                "pathGrass1",
            ]

            // Path (jalan utama)
            let pathTile = SKSpriteNode(imageNamed: "pathHorizontal")
            pathTile.scale(to: CGSize(width: tileSize * 2, height: tileSize * 2))
            pathTile.position = CGPoint(x: CGFloat(i) * pathTile.size.width, y: player.position.y - 30)
            pathTile.zPosition = 1
            addChild(pathTile)
            pathTiles.append(pathTile)

            // --- Wall Tiles di atas Path ---
            let upperTileCount = 8
            var lastY = pathTile.position.y + tileSize * 2
            for _ in 0 ..< upperTileCount {
                let upperTile = SKSpriteNode(imageNamed: options.randomElement()!)
                upperTile.scale(to: CGSize(width: tileSize * 2, height: tileSize * 2))
                upperTile.position = CGPoint(x: CGFloat(i) * upperTile.size.width, y: lastY)
                upperTile.zPosition = 1
                addChild(upperTile)
                wallTiles.append(upperTile)
                lastY += tileSize * 2
            }

            // --- Wall Tiles di bawah Path ---
            let lowerTileCount = 8
            var lowerY = pathTile.position.y - tileSize * 2
            for j in 0 ..< lowerTileCount {
                let imageName = (j == 0) ? "pathGrass" : options.randomElement()!
                let lowerTile = SKSpriteNode(imageNamed: imageName)
                lowerTile.scale(to: CGSize(width: tileSize * 2, height: tileSize * 2))
                lowerTile.position = CGPoint(x: CGFloat(i) * lowerTile.size.width, y: lowerY)
                lowerTile.zPosition = 1
                addChild(lowerTile)
                wallTiles.append(lowerTile)
                lowerY -= tileSize * 2
            }
        }

        print("TitleScene background setup with more wall tiles above")
    }

    override func update(_ currentTime: TimeInterval) {
        let deltaX = scrollSpeed * CGFloat(1.0 / 60.0) // asumsi 60 FPS

        for tile in pathTiles + wallTiles {
            tile.position.x -= deltaX

            // Reset posisi tile jika keluar dari kiri layar
            if tile.position.x < -tile.size.width {
                tile.position.x += tile.size.width * CGFloat(pathTiles.count)

                // Randomize the texture when tile resets position
                if let spriteNode = tile as? SKSpriteNode {
                    // Check if this is a wall tile that should be randomized
                    if wallTiles.contains(spriteNode) {
                        let treeVariant = Int.random(in: 1...6)

                        let newTextures = [
                            "pathTree\(treeVariant)",
                            "pathGrass1",
                            "pathGrass1",
                        ]

                        let newTextureName = newTextures.randomElement()!
                        spriteNode.texture = SKTexture(imageNamed: newTextureName)
                    }
                }
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
                let pressDown = SKAction.scale(to: isIpad ? 0.7 : 0.35, duration: 0.1)
                let pressUp = SKAction.scale(to: isIpad ? 0.6 : 0.45, duration: 0.1)
                let sequence = SKAction.sequence([pressDown, pressUp])

                playSoundIfEnabled(named: "select.wav", on: self)

                playButton.run(sequence) {
                    // Navigate to game scene after animation
                    self.navigateToGameScene()
                }
                return
            }

            if node.name == "leaderboardButton" || node.parent?.name == "leaderboardButton" {
                leaderboardButton.removeAllActions()
                guard GKLocalPlayer.local.isAuthenticated else {
                    print("Player belum login ke Game Center")
                    return
                }

                let leaderboardID = "karirKurirHighScore"
                let gcViewController = GKGameCenterViewController(leaderboardID: leaderboardID, playerScope: .global, timeScope: .allTime)
                gcViewController.gameCenterDelegate = self

                if let viewController = view?.window?.rootViewController {
                    viewController.present(gcViewController, animated: true, completion: nil)
                }
            }

            // Setting Button
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
                run(sound)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.settingNode?.toggleSetting(named: "soundEffectsEnabled")
                }
                return
            }

            // Toggle Haptics
            if node.name == "hapticsToggle" || node.parent?.name == "hapticsToggle" {
                let sound = SKAction.playSoundFileNamed("select.wav", waitForCompletion: false)
                run(sound)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.settingNode?.toggleSetting(named: "hapticsEnabled")
                }
                return
            }

            // Toggle Music
            if node.name == "musicToggle" || node.parent?.name == "musicToggle" {
                let sound = SKAction.playSoundFileNamed("select.wav", waitForCompletion: false)
                run(sound)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.settingNode?.toggleSetting(named: "musicEnabled")
                    self.toggleMusic(on: self, fileName: "HeatleyBros - HeatleyBros I - 06 8 Bit Love")
                }

                return
            }

            // Close Settings
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
        view?.presentScene(gameScene, transition: transition)
    }
}
