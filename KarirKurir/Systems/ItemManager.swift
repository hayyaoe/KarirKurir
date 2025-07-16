//
//  ItemManager.swift
//  KarirKurir
//
//  Created by Willas Daniel Rorrong Lumban Tobing on 11/07/25.
//

import SpriteKit

class ItemManager {
    
    private weak var scene: SKScene?
    private var mazeGenerator: MazeGenerator?
    private let tileSize: CGSize
    private let itemSize = CGSize(width: 40, height: 40)
    private var spawnTimer: Timer?
    
    init(scene: SKScene, mazeGenerator: MazeGenerator, tileSize: CGSize) {
        self.scene = scene
        self.mazeGenerator = mazeGenerator
        self.tileSize = tileSize
    }
    
    func startSpawningItems(interval: TimeInterval) {
        spawnTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.spawnItem()
        }
        
        spawnItem()
    }
    
    func stopSpawning() {
        spawnTimer?.invalidate()
    }
    
    private func spawnItem() {
        guard let scene = scene, let mazeGenerator = mazeGenerator else { return }
        
        // Get all accessible wall locations from the maze generator
        let wallLocations = mazeGenerator.getAccessibleWallLocations()
        guard !wallLocations.isEmpty else {
            print("No accessible wall locations to spawn item.")
            return
        }
        
        // Select a random wall location
        let randomGridPoint = wallLocations.randomElement()!
        
        // Convert grid point to scene coordinates
        // The item will be centered on the wall tile
        let localPosition = CGPoint(
            x: randomGridPoint.x * tileSize.width,
            y: randomGridPoint.y * tileSize.height
        )
        
        // Find the maze node to convert coordinates properly
        guard let mazeNode = scene.children.first(where: { $0 is MazeNode }) as? MazeNode else {
            print("Could not find maze node in scene")
            return
        }
        
        // Convert from maze node's local coordinates to scene coordinates
        let finalPosition = scene.convert(localPosition, from: mazeNode)
        
        // Check if there's already an item at this exact position
        for node in scene.children {
            if let existingItem = node as? ItemNode {
                // Check for exact tile position match
                if abs(existingItem.position.x - finalPosition.x) < 1 &&
                    abs(existingItem.position.y - finalPosition.y) < 1 {
                    print("Attempted to spawn item on an existing one. Skipping.")
                    return
                }
            }
        }
        
        let randomTime = Int.random(in: 16...25)
        let item = ItemNode(size: itemSize, initialTime: randomTime)
        item.position = finalPosition
        
        // Set a higher z-position so items appear on top of walls
        item.zPosition = 10
        
        item.onTimerExpired = { [weak item] in
            print("Item expired and was removed.")
            item?.removeFromParent()
        }
        
        scene.addChild(item)
        print("Spawned item on wall at grid point \(randomGridPoint) with timer \(randomTime)s at position \(finalPosition)")
    }
}
