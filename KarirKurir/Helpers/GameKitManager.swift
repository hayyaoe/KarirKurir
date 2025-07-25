//
//  GameKitManager.swift
//  KarirKurir
//
//  Created by Mahardika Putra Wardhana on 17/07/25.
//
import GameKit
import SwiftUI

class GameCenterManager: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterManager()

    override private init() {
        super.init()
    }

    func authenticateGameCenter() {
        let localPlayer = GKLocalPlayer.local
        localPlayer.authenticateHandler = { vc, error in
            if let vc = vc {
                // You must present this on the top-most view controller
                if let rootVC = UIApplication.shared.connectedScenes
                    .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
                    .first?.rootViewController
                {
                    rootVC.present(vc, animated: true)
                }
            } else if localPlayer.isAuthenticated {
                print("Game Center: Authenticated")
            } else {
                print("Game Center: Authentication failed")
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                }
            }
        }
    }

    func submitScoreToLeaderboard(score: Int, leaderboardID: String) {
        guard GKLocalPlayer.local.isAuthenticated else {
            print("Game Center: Player not authenticated")
            return
        }

        let scoreReporter = GKScore(leaderboardIdentifier: leaderboardID)
        scoreReporter.value = Int64(score)

        GKScore.report([scoreReporter]) { error in
            if let error = error {
                print("Error reporting score: \(error.localizedDescription)")
            } else {
                print("Score submitted successfully!")
            }
        }
    }

    func gameOver(withScore score: Int, leaderboardID: String = "karirKurirHighScore") {
        // Update local high score
        ScoreManager.shared.updateScore(score)

        // Submit to Game Center
        submitScoreToLeaderboard(score: score, leaderboardID: leaderboardID)
    }

    func showLeaderboard(from viewController: UIViewController, leaderboardID: String = "karirKurirHighScore") {
        let gcVC = GKGameCenterViewController(leaderboardID: leaderboardID, playerScope: .global, timeScope: .allTime)
        gcVC.gameCenterDelegate = self
        viewController.present(gcVC, animated: true)
    }

    // Required delegate method
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }

    func reportAchievement(identifier: String, percentComplete: Double) {
        let achievement = GKAchievement(identifier: identifier)
        achievement.percentComplete = percentComplete
        achievement.showsCompletionBanner = true

        GKAchievement.report([achievement]) { error in
            if let error = error {
                print("Failed to report achievement: \(error.localizedDescription)")
            } else {
                print("Achievement '\(identifier)' reported successfully.")
            }
        }
    }

    func completeLevel(_ level: Int) {
        switch level {
        case 1:
            GameCenterManager.shared.reportAchievement(identifier: "karirKurirAchievement1", percentComplete: 100)
        case 10:
            GameCenterManager.shared.reportAchievement(identifier: "karirKurirAchievement2", percentComplete: 100)
        case 50:
            GameCenterManager.shared.reportAchievement(identifier: "karirKurirAchievement3", percentComplete: 100)
        case 100:
            GameCenterManager.shared.reportAchievement(identifier: "karirKurirAchievement4", percentComplete: 100)
        default:
            break
        }
    }

    func beatHighScore() {
        GameCenterManager.shared.reportAchievement(identifier: "karirKurirAchievement5", percentComplete: 100)
    }

    func gotAllGreen() {
        GameCenterManager.shared.reportAchievement(identifier: "karirKurirAchievement6", percentComplete: 100)
    }
}
