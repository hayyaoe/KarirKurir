//
//  HepticHelper.swift
//  KarirKurir
//
//  Created by Hayya U on 17/07/25.
//

import UIKit

enum HapticType {
    case impact(UIImpactFeedbackGenerator.FeedbackStyle)
    case notification(UINotificationFeedbackGenerator.FeedbackType)
    case selection
}

struct HapticHelper {
    static func trigger(_ type: HapticType) {
        guard UserDefaults.standard.bool(forKey: "hapticsEnabled") else { return }

        switch type {
        case .impact(let style):
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred()
            
        case .notification(let type):
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(type)
            
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        }
    }
}
