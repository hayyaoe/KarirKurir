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

    let col = Int(start.x/gridSize)
    let row = height - 1 - Int(start.y/gridSize)

    queue.append((row, col))
    visited[row][col] = true
    let directions = [(0, 1), (1, 0), (0, -1), (-1, 0)]

    while !queue.isEmpty {
        let (r, c) = queue.removeFirst()
        if maze[r][c] == 0 {
            result.append(CGPoint(
                x: CGFloat(c) * gridSize + gridSize/2,
                y: CGFloat(height - r - 1) * gridSize + gridSize/2
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
