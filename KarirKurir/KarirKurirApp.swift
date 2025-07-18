//
//  KarirKurirApp.swift
//  KarirKurir
//

import SwiftUI

@main
struct KarirKurirApp: App {
    init() {
        GameCenterManager.shared.authenticateGameCenter()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
