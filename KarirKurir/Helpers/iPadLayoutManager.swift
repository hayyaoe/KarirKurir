//
//  iPadLayoutManager.swift
//  KarirKurir
//
//  Created by Willas Daniel Rorrong Lumban Tobing on 25/07/25.
//

import UIKit
import SpriteKit

class iPadLayoutManager {
    static let shared = iPadLayoutManager()
    
    // MARK: - Device Detection
    
    enum DeviceType {
        case iPhone
        case iPadPro13
        case iPadOther
        case unknown
    }
    
    var currentDevice: DeviceType {
        let screenSize = UIScreen.main.bounds.size
        let screenWidth = max(screenSize.width, screenSize.height) // Landscape width
        let screenHeight = min(screenSize.width, screenSize.height) // Landscape height
        
        // iPad Pro 13-inch: 1024 x 1366 points (landscape: 1366 x 1024)
        if UIDevice.current.userInterfaceIdiom == .pad {
            if screenWidth >= 1360 && screenWidth <= 1370 { // Allow some tolerance
                return .iPadPro13
            } else {
                return .iPadOther
            }
        } else {
            return .iPhone
        }
    }
    
    var isIPad: Bool {
        return currentDevice == .iPadPro13 || currentDevice == .iPadOther
    }
    
    var isIPadPro13: Bool {
        return currentDevice == .iPadPro13
    }
    
    // MARK: - Layout Constants
    
    struct LayoutConstants {
        // Grid and Game Area
        let gridSize: CGFloat
        let gameAreaMargin: CGFloat
        let gameAreaMaxWidth: CGFloat
        let gameAreaMaxHeight: CGFloat
        
        // UI Elements
        let buttonScale: CGFloat
        let fontSize: CGFloat
        let iconSize: CGFloat
        let UIMargin: CGFloat
        let touchTargetMinSize: CGFloat
        
        // Specific UI Measurements
        let pauseButtonSize: CGFloat
        let heartIconSize: CGFloat
        let titleScale: CGFloat
        let playerScale: CGFloat
        
        // Modal and Popup
        let modalScale: CGFloat
        let popupScale: CGFloat
        
        static func forDevice(_ device: DeviceType) -> LayoutConstants {
            switch device {
            case .iPadPro13:
                return LayoutConstants(
                    gridSize: 45.0,                    // Larger grid for iPad
                    gameAreaMargin: 80.0,             // More margin around game
                    gameAreaMaxWidth: 1200.0,         // Max game area width
                    gameAreaMaxHeight: 800.0,         // Max game area height
                    buttonScale: 0.8,                 // Larger buttons
                    fontSize: 28.0,                   // Larger fonts
                    iconSize: 40.0,                   // Larger icons
                    UIMargin: 60.0,                   // More UI spacing
                    touchTargetMinSize: 60.0,         // Minimum touch target
                    pauseButtonSize: 80.0,            // Larger pause button
                    heartIconSize: 32.0,              // Larger heart icons
                    titleScale: 1.4,                  // Larger title
                    playerScale: 1.8,                 // Larger player on title
                    modalScale: 0.25,                 // Adjusted modal size
                    popupScale: 1.3                   // Larger popups
                )
            case .iPadOther:
                return LayoutConstants(
                    gridSize: 40.0,
                    gameAreaMargin: 60.0,
                    gameAreaMaxWidth: 1000.0,
                    gameAreaMaxHeight: 700.0,
                    buttonScale: 0.7,
                    fontSize: 24.0,
                    iconSize: 35.0,
                    UIMargin: 50.0,
                    touchTargetMinSize: 55.0,
                    pauseButtonSize: 70.0,
                    heartIconSize: 28.0,
                    titleScale: 1.2,
                    playerScale: 1.5,
                    modalScale: 0.22,
                    popupScale: 1.2
                )
            case .iPhone, .unknown:
                return LayoutConstants(
                    gridSize: 30.0,
                    gameAreaMargin: 20.0,
                    gameAreaMaxWidth: 600.0,
                    gameAreaMaxHeight: 400.0,
                    buttonScale: 0.45,
                    fontSize: 20.0,
                    iconSize: 24.0,
                    UIMargin: 20.0,
                    touchTargetMinSize: 44.0,
                    pauseButtonSize: 50.0,
                    heartIconSize: 24.0,
                    titleScale: 0.9,
                    playerScale: 1.0,
                    modalScale: 0.18,
                    popupScale: 1.0
                )
            }
        }
    }
    
    var layout: LayoutConstants {
        return LayoutConstants.forDevice(currentDevice)
    }
    
    // MARK: - Dynamic Sizing Methods
    
    func calculateOptimalGridSize(for sceneSize: CGSize, mazeWidth: Int, mazeHeight: Int) -> CGFloat {
        let constants = layout
        
        let availableWidth = sceneSize.width - (constants.gameAreaMargin * 2)
        let availableHeight = sceneSize.height - (constants.gameAreaMargin * 2) - 100 // Reserve space for UI
        
        // Limit the available area to reasonable maximums for iPad
        let constrainedWidth = min(availableWidth, constants.gameAreaMaxWidth)
        let constrainedHeight = min(availableHeight, constants.gameAreaMaxHeight)
        
        let gridSizeByWidth = constrainedWidth / CGFloat(mazeWidth)
        let gridSizeByHeight = constrainedHeight / CGFloat(mazeHeight)
        
        let calculatedSize = min(gridSizeByWidth, gridSizeByHeight)
        
        // Ensure minimum and maximum grid sizes
        let minGridSize: CGFloat = isIPad ? 35.0 : 25.0
        let maxGridSize: CGFloat = isIPad ? 60.0 : 40.0
        
        return max(minGridSize, min(maxGridSize, calculatedSize))
    }
    
    func getUIPositions(for sceneSize: CGSize) -> UIPositions {
        let constants = layout
        let margin = constants.UIMargin
        
        return UIPositions(
            scorePosition: CGPoint(x: margin + 100, y: sceneSize.height - 50),
            levelPosition: CGPoint(x: sceneSize.width * 0.5, y: sceneSize.height - 50),
            highScorePosition: CGPoint(x: sceneSize.width - margin - 200, y: sceneSize.height - 50),
            pauseButtonPosition: CGPoint(x: sceneSize.width - margin - 30, y: sceneSize.height - 50),
            heartStartPosition: CGPoint(x: margin, y: sceneSize.height - 50),
            heartSpacing: constants.heartIconSize + 5
        )
    }
    
    struct UIPositions {
        let scorePosition: CGPoint
        let levelPosition: CGPoint
        let highScorePosition: CGPoint
        let pauseButtonPosition: CGPoint
        let heartStartPosition: CGPoint
        let heartSpacing: CGFloat
    }
    
    // MARK: - Title Screen Layout
    
    func getTitleScreenLayout(for sceneSize: CGSize) -> TitleScreenLayout {
        let constants = layout
        
        return TitleScreenLayout(
            titlePosition: CGPoint(x: sceneSize.width / 2, y: sceneSize.height - 120),
            titleScale: constants.titleScale,
            playButtonPosition: CGPoint(x: sceneSize.width - 200, y: 120),
            playButtonScale: constants.buttonScale,
            settingButtonPosition: CGPoint(x: sceneSize.width - 80, y: sceneSize.height - 60),
            settingButtonScale: constants.buttonScale,
            playerPosition: CGPoint(x: sceneSize.width / 2 + 50, y: sceneSize.height / 2),
            playerScale: constants.playerScale,
            catPosition: CGPoint(x: sceneSize.width / 2 + 20, y: sceneSize.height / 2 - 80),
            catScale: constants.playerScale * 0.6,
            wagonPosition: CGPoint(x: sceneSize.width / 2 - 150, y: sceneSize.height / 2),
            wagonScale: constants.playerScale
        )
    }
    
    struct TitleScreenLayout {
        let titlePosition: CGPoint
        let titleScale: CGFloat
        let playButtonPosition: CGPoint
        let playButtonScale: CGFloat
        let settingButtonPosition: CGPoint
        let settingButtonScale: CGFloat
        let playerPosition: CGPoint
        let playerScale: CGFloat
        let catPosition: CGPoint
        let catScale: CGFloat
        let wagonPosition: CGPoint
        let wagonScale: CGFloat
    }
    
    // MARK: - Modal and Popup Layout
    
    func getModalLayout(for sceneSize: CGSize) -> ModalLayout {
        let constants = layout
        
        return ModalLayout(
            backgroundScale: constants.modalScale,
            buttonScale: constants.buttonScale,
            fontSize: constants.fontSize,
            spacing: constants.UIMargin / 2,
            retryButtonOffset: CGPoint(x: -120, y: -150),
            quitButtonOffset: CGPoint(x: 120, y: -150),
            resumeButtonOffset: CGPoint(x: -80, y: -120),
            toggleSpacing: 60
        )
    }
    
    struct ModalLayout {
        let backgroundScale: CGFloat
        let buttonScale: CGFloat
        let fontSize: CGFloat
        let spacing: CGFloat
        let retryButtonOffset: CGPoint
        let quitButtonOffset: CGPoint
        let resumeButtonOffset: CGPoint
        let toggleSpacing: CGFloat
    }
    
    // MARK: - Touch Target Optimization
    
    func optimizeTouchTarget(for node: SKNode, minimumSize: CGFloat? = nil) {
        let minSize = minimumSize ?? layout.touchTargetMinSize
        
        if let spriteNode = node as? SKSpriteNode {
            let currentSize = spriteNode.size
            if currentSize.width < minSize || currentSize.height < minSize {
                // Add invisible touch area
                let touchArea = SKSpriteNode(color: .clear, size: CGSize(width: minSize, height: minSize))
                touchArea.zPosition = spriteNode.zPosition + 0.1
                touchArea.name = spriteNode.name
                node.addChild(touchArea)
            }
        }
    }
    
    // MARK: - Animation Scaling
    
    func getAnimationScale() -> CGFloat {
        return isIPad ? 1.2 : 1.0
    }
    
    // MARK: - Scroll and Background Adjustments
    
    func getScrollSpeed() -> CGFloat {
        return isIPadPro13 ? 150.0 : 100.0
    }
    
    func getTileSize() -> CGFloat {
        return isIPadPro13 ? 60.0 : 40.0
    }
    
    // MARK: - Orientation Support
    
    func supportedOrientations() -> UIInterfaceOrientationMask {
        return isIPad ? .landscape : .landscape
    }
    
    // MARK: - Debug Info
    
    func printLayoutInfo(sceneSize: CGSize) {
        print("=== iPad Layout Manager Debug ===")
        print("Device: \(currentDevice)")
        print("Scene Size: \(sceneSize)")
        print("Grid Size: \(layout.gridSize)")
        print("UI Margin: \(layout.UIMargin)")
        print("Font Size: \(layout.fontSize)")
        print("Touch Target Min: \(layout.touchTargetMinSize)")
        print("================================")
    }
}

// MARK: - Extensions for Easy Access

extension SKScene {
    var layoutManager: iPadLayoutManager {
        return iPadLayoutManager.shared
    }
    
    var isIPad: Bool {
        return layoutManager.isIPad
    }
    
    var isIPadPro13: Bool {
        return layoutManager.isIPadPro13
    }
}

extension SKLabelNode {
    func setAdaptiveFont(baseSize: CGFloat) {
        let manager = iPadLayoutManager.shared
        let adaptedSize = baseSize * (manager.isIPad ? 1.4 : 1.0)
        setLuckiestGuyFont(size: adaptedSize)
    }
}

extension SKSpriteNode {
    func setAdaptiveScale(_ baseScale: CGFloat) {
        let manager = iPadLayoutManager.shared
        let adaptedScale = baseScale * (manager.isIPad ? 1.3 : 1.0)
        setScale(adaptedScale)
    }
}
