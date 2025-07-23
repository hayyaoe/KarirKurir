//
//  KarirKurirApp.swift
//  KarirKurir
//

import SwiftUI

@main
struct KarirKurirApp: App {
    init() {
        UserDefaults.standard.register(defaults: [
            "sfxEnabled": true,
            "hapticsEnabled": true,
            "musicEnabled": true
        ])
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
