//
//  KarirKurirApp.swift
//  KarirKurir
//

import GameKit
import SwiftUI

@main
struct KarirKurirApp: App {
    init() {
        UserDefaults.standard.register(defaults: [
            "sfxEnabled": true,
            "hapticsEnabled": true,
            "musicEnabled": true
        ])

        GameCenterManager.shared.setupGameCenterWithScoreSync()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
