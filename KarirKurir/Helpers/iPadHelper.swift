//
//  iPadHelper.swift
//  KarirKurir
//
//  Created by Willas Daniel Rorrong Lumban Tobing on 25/07/25.
//

import UIKit

class iPadHelper {
    static let shared = iPadHelper()
    
    // Simple iPad detection
    var isIPad: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    // Position adjustments for iPad
    func adjustPosition(_ position: CGPoint, for element: UIElement) -> CGPoint {
        guard isIPad else { return position }
        
        switch element {
        case .scoreLabel:
            return CGPoint(x: position.x + 50, y: position.y)
        case .levelLabel:
            return CGPoint(x: position.x, y: position.y)
        case .highScoreLabel:
            return CGPoint(x: position.x - 100, y: position.y)
        case .pauseButton:
            return CGPoint(x: position.x - 40, y: position.y)
        case .heartDisplay:
            return CGPoint(x: position.x + 100, y: position.y)
        case .playButton:
            return CGPoint(x: position.x + 150, y: position.y)
        case .settingButton:
            return CGPoint(x: position.x - 30, y: position.y)
        case .titleLogo:
            return CGPoint(x: position.x, y: position.y + 50)
        case .gameElements:
            return position // Keep game elements in same relative positions
        }
    }
    
    // Scale adjustments for iPad
    func adjustScale(_ scale: CGFloat, for element: UIElement) -> CGFloat {
        guard isIPad else { return scale }
        
        switch element {
        case .scoreLabel, .levelLabel, .highScoreLabel:
            return scale * 1.3
        case .pauseButton, .playButton, .settingButton:
            return scale * 1.2
        case .heartDisplay:
            return scale * 1.4
        case .titleLogo:
            return scale * 1.3
        case .gameElements:
            return scale * 1.2
        }
    }
    
    // Font size adjustments for iPad
    func adjustFontSize(_ fontSize: CGFloat) -> CGFloat {
        return isIPad ? fontSize * 1.4 : fontSize
    }
}

enum UIElement {
    case scoreLabel
    case levelLabel
    case highScoreLabel
    case pauseButton
    case heartDisplay
    case playButton
    case settingButton
    case titleLogo
    case gameElements
}
