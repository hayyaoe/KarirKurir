//
//  ScoreManager.swift
//  KarirKurir
//
//  Created by Mahardika Putra Wardhana on 17/07/25.
//

import Foundation

class ScoreManager: ObservableObject {
    static let shared = ScoreManager()

    @Published var highScore: Int {
        didSet {
            UserDefaults.standard.set(highScore, forKey: "HighScore")
        }
    }

    private init() {
        self.highScore = UserDefaults.standard.integer(forKey: "HighScore")
    }

    func updateScore(_ newScore: Int) {
        if newScore > highScore {
            highScore = newScore
            GameCenterManager.shared.beatHighScore()
        }
        print(highScore)
    }

    func syncHighScoreFromGameCenter() {
        GameCenterManager.shared.fetchHighScoreFromLeaderboard(leaderboardID: "karirKurirHighScore") { [weak self] gameCenterScore in
            DispatchQueue.main.async {
                // Update high score jika Game Center score lebih tinggi
                if gameCenterScore > self?.highScore ?? 0 {
                    self?.highScore = gameCenterScore
                    print("High score updated from Game Center: \(gameCenterScore)")
                }
            }
        }
    }
}
