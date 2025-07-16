//
//  ItemCategory.swift
//  KarirKurir
//
//  Created by Willas Daniel Rorrong Lumban Tobing on 11/07/25.
//

import SpriteKit

// Enum to define the different item categories, their points, and colors.
enum ItemCategory{
    case green, yellow, red
    
    var points: Int {
        switch self {
        case .green:
            return 5
        case .yellow:
            return 3
        case .red:
            return 1
        }
    }
    
    var color: SKColor {
        switch self {
        case .green:
            return .systemGreen
        case .yellow:
            return .systemYellow
        case .red:
            return .systemRed
        }
    }
    
    static func category(for time: Int) -> ItemCategory {
        if time >= 16 {
            return .green
        } else if time >= 8 {
            return .yellow
        } else {
            return .red
        }
    }
}
