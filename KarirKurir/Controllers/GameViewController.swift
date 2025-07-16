//
//  GameViewController.swift
//  KarirKurir
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func loadView() {
        self.view = SKView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as? SKView {
            // Wait for the view to have its final size
            DispatchQueue.main.async {
                let scene = GameScene(size: view.bounds.size)
                scene.scaleMode = .aspectFit
                view.presentScene(scene)
                
                view.ignoresSiblingOrder = true
                view.showsFPS = true
                view.showsNodeCount = true
                
                print("View bounds: \(view.bounds)")
                print("Scene size: \(scene.size)")
            }
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
