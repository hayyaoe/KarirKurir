//
//  MazeGenerator.swift
//  KarirKurir
//
//  Created by Willas Daniel Rorrong Lumban Tobing on 11/07/25.
//

import Foundation
import GameplayKit

// Enum to represent the type of each cell in the maze grid
enum MazeCellType {
    case wall
    case path
}

class MazeGenerator {
    let width: Int
    let height: Int
    private(set) var grid: [[MazeCellType]]

    init(width: Int, height: Int) {
        // Ensure dimensions are odd to create proper walls around paths
        self.width = width % 2 == 0 ? width + 1 : width
        self.height = height % 2 == 0 ? height + 1 : height
        self.grid = Array(repeating: Array(repeating: .wall, count: self.height), count: self.width)
        generate()
    }

    /// Returns a list of all points that are valid paths for spawning items.
    func getPathableLocations() -> [CGPoint] {
        var locations: [CGPoint] = []
        for x in 0..<width {
            for y in 0..<height {
                if grid[x][y] == .path {
                    locations.append(CGPoint(x: x, y: y))
                }
            }
        }
        return locations
    }
    
    /// Returns a list of all wall locations that are adjacent to at least one path.
    /// This ensures items on walls can be collected by the player.
    func getAccessibleWallLocations() -> [CGPoint] {
        var locations: [CGPoint] = []
        
        for x in 0..<width {
            for y in 0..<height {
                // Check if this is a wall
                if grid[x][y] == .wall {
                    // Check if there's at least one adjacent path
                    let adjacentPositions = [
                        (x: x+1, y: y),
                        (x: x-1, y: y),
                        (x: x, y: y+1),
                        (x: x, y: y-1)
                    ]
                    
                    var hasAdjacentPath = false
                    for pos in adjacentPositions {
                        if pos.x >= 0 && pos.x < width && pos.y >= 0 && pos.y < height {
                            if grid[pos.x][pos.y] == .path {
                                hasAdjacentPath = true
                                break
                            }
                        }
                    }
                    
                    if hasAdjacentPath {
                        locations.append(CGPoint(x: x, y: y))
                    }
                }
            }
        }
        return locations
    }

    private func generate() {
        // Start the maze generation from a random odd-numbered cell
        let startX = Int.random(in: 0..<(width / 2)) * 2 + 1
        let startY = Int.random(in: 0..<(height / 2)) * 2 + 1
        carve(atX: startX, atY: startY)
    }

    private func carve(atX x: Int, atY y: Int) {
        grid[x][y] = .path
        
        // Get neighbors in a random order
        var directions = [MoveDirection.up, .down, .left, .right].shuffled()
        
        for direction in directions {
            let (nextX, nextY, wallX, wallY) = getNextPosition(fromX: x, fromY: y, direction: direction)
            
            // Check if the next cell is within bounds and is a wall
            if nextX > 0 && nextX < width - 1 && nextY > 0 && nextY < height - 1 && grid[nextX][nextY] == .wall {
                // Carve path to the wall and the next cell
                grid[wallX][wallY] = .path
                carve(atX: nextX, atY: nextY)
            }
        }
    }

    private func getNextPosition(fromX x: Int, fromY y: Int, direction: MoveDirection) -> (Int, Int, Int, Int) {
        var nextX = x, nextY = y
        var wallX = x, wallY = y
        
        switch direction {
        case .up:
            nextY += 2
            wallY += 1
        case .down:
            nextY -= 2
            wallY -= 1
        case .right:
            nextX += 2
            wallX += 1
        case .left:
            nextX -= 2
            wallX -= 1
        }
        return (nextX, nextY, wallX, wallY)
    }
}
