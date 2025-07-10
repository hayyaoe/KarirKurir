//
//  GameViewRepresentable.swift
//  KarirKurir
//

import SwiftUI
import UIKit

struct GameViewRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> GameViewController {
        return GameViewController()
    }
    
    func updateUIViewController(_ uiViewController: GameViewController, context: Context) {
        // No updates needed
    }
}
