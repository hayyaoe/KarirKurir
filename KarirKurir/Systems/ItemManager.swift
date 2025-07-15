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
    
//    private func spawnItem() {
//        guard let scene = scene, let mazeGenerator = mazeGenerator else { return }
//
//        // Get all possible path locations from the maze generator
//        let pathableLocations = mazeGenerator.getPathableLocations()
//        guard !pathableLocations.isEmpty else {
//            print("No pathable locations to spawn item.")
//            return
//        }
//
//        // Select a random path location
//        let randomGridPoint = pathableLocations.randomElement()!
//
//        // Convert grid point to scene coordinates
//        let finalPosition = CGPoint(
//            x: randomGridPoint.x * tileSize.width,
//            y: randomGridPoint.y * tileSize.height
//        )
//
//        // Ensure we don't spawn on top of an existing item
//        for node in scene.children {
//            if node is ItemNode && node.position == finalPosition {
//                print("Attempted to spawn item on an existing one. Skipping.")
//                return
//            }
//        }
//
//        let randomTime = Int.random(in: 16...25)
//        let item = ItemNode(size: itemSize, initialTime: randomTime)
//        item.position = finalPosition
//
//        item.onTimerExpired = { [weak item] in
//            print("Item expired and was removed.")
//            item?.removeFromParent()
//        }
//
//        scene.addChild(item)
//        print("Spawned item at grid point \(randomGridPoint) with timer \(randomTime)s")
//    }
    
    private func spawnItem() {
        guard let scene = scene, let mazeGenerator = mazeGenerator else { return }
        
        // Get all possible path locations from the maze generator
        let pathableLocations = mazeGenerator.getPathableLocations()
        guard !pathableLocations.isEmpty else {
            print("No pathable locations to spawn item.")
            return
        }
        
        // Select a random path location
        let randomGridPoint = pathableLocations.randomElement()!
        
        // Convert grid point to scene coordinates with proper centering
        // Add half tile size to center the item within the tile
        let centeredPosition = CGPoint(
            x: randomGridPoint.x * tileSize.width + (tileSize.width / 2),
            y: randomGridPoint.y * tileSize.height + (tileSize.height / 2)
        )
        
        // Convert from maze node's local coordinates to scene coordinates
        guard let mazeNode = scene.children.first(where: { $0 is MazeNode }) as? MazeNode else {
            print("Could not find maze node in scene")
            return
        }
        
        let finalPosition = scene.convert(centeredPosition, from: mazeNode)
        
        // Ensure we don't spawn on top of an existing item
        for node in scene.children {
            if let existingItem = node as? ItemNode {
                let distance = sqrt(pow(existingItem.position.x - finalPosition.x, 2) +
                                    pow(existingItem.position.y - finalPosition.y, 2))
                if distance < tileSize.width {
                    print("Attempted to spawn item too close to an existing one. Skipping.")
                    return
                }
            }
        }
        
        let randomTime = Int.random(in: 16...25)
        let item = ItemNode(size: itemSize, initialTime: randomTime)
        item.position = finalPosition
        
        item.onTimerExpired = { [weak item] in
            print("Item expired and was removed.")
            item?.removeFromParent()
        }
        
        scene.addChild(item)
        print("Spawned item at grid point \(randomGridPoint) with timer \(randomTime)s at position \(finalPosition)")
    }
}
