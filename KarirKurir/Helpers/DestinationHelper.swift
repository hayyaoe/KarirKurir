//
//  DestinationHelper.swift
//  KarirKurir
//
//  Created by Mahardika Putra Wardhana on 14/07/25.
//

import Foundation
import SpriteKit

// MARK: - Pathfinding & Poisson Disk

func findReachablePositions(from start: CGPoint, gridSize: CGFloat, maze: [[Int]]) -> [CGPoint] {
    let width = maze[0].count
    let height = maze.count
    var visited = Array(repeating: Array(repeating: false, count: width), count: height)
    var result: [CGPoint] = []
    var queue: [(Int, Int)] = []

    // Convert start position to maze grid coordinates
    let col = Int(start.x)
    let row = Int(start.y)
    
    // Add bounds checking to prevent crash
    guard row >= 0, row < height, col >= 0, col < width else {
        print("Start position is out of maze bounds: row=\(row), col=\(col), maze size=\(height)x\(width)")
        return []
    }

    queue.append((row, col))
    visited[row][col] = true
    let directions = [(0, 1), (1, 0), (0, -1), (-1, 0)]

    while !queue.isEmpty {
        let (r, c) = queue.removeFirst()
        if maze[r][c] == 0 {
            result.append(CGPoint(
                x: CGFloat(c) + 0.5,
                y: CGFloat(height - r - 1) + 0.5
            ))
        }

        for (dr, dc) in directions {
            let nr = r + dr
            let nc = c + dc
            if nr >= 0, nr < height, nc >= 0, nc < width,
               !visited[nr][nc], maze[nr][nc] == 0
            {
                visited[nr][nc] = true
                queue.append((nr, nc))
            }
        }
    }

    return result
}

func generatePoissonDiskPoints(from positions: [CGPoint], minDistance: CGFloat, maxPoints: Int) -> [CGPoint] {
    var selected: [CGPoint] = []
    for point in positions.shuffled() {
        if selected.allSatisfy({ hypot($0.x - point.x, $0.y - point.y) >= minDistance }) {
            selected.append(point)
        }
        if selected.count >= maxPoints { break }
    }
    return selected
}
