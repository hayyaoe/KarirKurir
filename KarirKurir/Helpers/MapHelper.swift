//
//  MapHelper.swift
//  KarirKurir
//
//  Created by Mahardika Putra Wardhana on 13/07/25.
//

func getMazeLayout(for level: Int) -> ([[Int]], [(row: Int, col: Int)]) {
    return generateRandomMaze(width: 20, height: 11, complexity: min(level, 5))
}

func generateRandomMaze(width: Int, height: Int, complexity: Int) -> ([[Int]], [(row: Int, col: Int)]) {
    // Initialize maze with all walls
    var maze = Array(repeating: Array(repeating: 1, count: width), count: height)
    var houseAreas: [(row: Int, col: Int)] = []

    // Ensure outer walls are always walls
    for i in 0..<height {
        maze[i][0] = 1
        maze[i][width - 1] = 1
    }
    for j in 0..<width {
        maze[0][j] = 1
        maze[height - 1][j] = 1
    }

    // Create starting area (always clear)
    maze[height - 2][1] = 0
    maze[height - 2][2] = 0
    maze[height - 3][1] = 0

    // Use recursive backtracking to create maze paths
    var visited = Array(repeating: Array(repeating: false, count: width), count: height)
    var stack: [(Int, Int)] = []

    // Start from position (1,1)
    let startRow = 1
    let startCol = 1
    stack.append((startRow, startCol))
    visited[startRow][startCol] = true
    maze[startRow][startCol] = 0

    let directions = [(0, 2), (2, 0), (0, -2), (-2, 0)] // Move by 2 to maintain wall structure

    while !stack.isEmpty {
        let (currentRow, currentCol) = stack.last!

        // Get valid neighbors
        var neighbors: [(Int, Int)] = []

        for (dr, dc) in directions {
            let newRow = currentRow + dr
            let newCol = currentCol + dc

            if newRow > 0, newRow < height - 1,
               newCol > 0, newCol < width - 1,
               !visited[newRow][newCol]
            {
                neighbors.append((newRow, newCol))
            }
        }

        if !neighbors.isEmpty {
            // Choose random neighbor
            let randomNeighbor = neighbors.randomElement()!
            let (nextRow, nextCol) = randomNeighbor

            // Remove wall between current and next
            let wallRow = currentRow + (nextRow - currentRow)/2
            let wallCol = currentCol + (nextCol - currentCol)/2

            maze[wallRow][wallCol] = 0
            maze[nextRow][nextCol] = 0

            visited[nextRow][nextCol] = true
            stack.append((nextRow, nextCol))
        } else {
            stack.removeLast()
        }
    }

    // Add some random openings based on complexity
    let openings = complexity * 3
    for _ in 0..<openings {
        let row = Int.random(in: 2..<height - 2)
        let col = Int.random(in: 2..<width - 2)

        // Only open if it creates a valid path
        if maze[row][col] == 1 {
            let adjacentOpen = (maze[row - 1][col] == 0 ? 1 : 0) +
                (maze[row + 1][col] == 0 ? 1 : 0) +
                (maze[row][col - 1] == 0 ? 1 : 0) +
                (maze[row][col + 1] == 0 ? 1 : 0)

            if adjacentOpen >= 2, adjacentOpen <= 3 {
                maze[row][col] = 0
            }
        }
    }

    // Ensure connectivity by adding some strategic openings
    addStrategicOpenings(&maze, width: width, height: height)

//        // Add some random walls to increase difficulty at higher levels
//        if level > 2 {
//            addRandomWalls(&maze, width: width, height: height, count: level * 2)
//        }
    let houseCandidates = findHouseAreas(in: maze)
    if let selectedHouse = houseCandidates.randomElement() {
        houseAreas.append(selectedHouse)
    }

    return (maze, houseAreas)
}

func findHouseAreas(in maze: [[Int]]) -> [(row: Int, col: Int)] {
    var result: [(row: Int, col: Int)] = []
    let height = maze.count
    let width = maze[0].count

    for row in 1..<height - 2 {
        for col in 1..<width - 2 {
            let tiles = [
                maze[row][col],
                maze[row + 1][col],
                maze[row][col + 1],
                maze[row + 1][col + 1]
            ]

            guard tiles.allSatisfy({ $0 == 1 }) else { continue }

            let adjacent = [
                maze[row - 1][col], maze[row - 1][col + 1],
                maze[row + 2][col], maze[row + 2][col + 1],
                maze[row][col - 1], maze[row + 1][col - 1],
                maze[row][col + 2], maze[row + 1][col + 2]
            ]

            if adjacent.contains(0) {
                result.append((row: row, col: col))
            }
        }
    }

    return result
}

func addStrategicOpenings(_ maze: inout [[Int]], width: Int, height: Int) {
    // Add horizontal corridors
    for row in stride(from: 2, to: height - 2, by: 4) {
        for col in 1..<width - 1 {
            if maze[row][col] == 1,
               maze[row][col - 1] == 0, maze[row][col + 1] == 0
            {
                maze[row][col] = 0
            }
        }
    }

    // Add vertical corridors
    for col in stride(from: 2, to: width - 2, by: 4) {
        for row in 1..<height - 1 {
            if maze[row][col] == 1,
               maze[row - 1][col] == 0, maze[row + 1][col] == 0
            {
                maze[row][col] = 0
            }
        }
    }
}

func addRandomWalls(_ maze: inout [[Int]], width: Int, height: Int, count: Int) {
    for _ in 0..<count {
        let row = Int.random(in: 2..<height - 2)
        let col = Int.random(in: 2..<width - 2)

        // Only add wall if it doesn't block the path completely
        if maze[row][col] == 0 {
            // Check if adding wall would create isolated areas
            let adjacentWalls = (maze[row - 1][col] == 1 ? 1 : 0) +
                (maze[row + 1][col] == 1 ? 1 : 0) +
                (maze[row][col - 1] == 1 ? 1 : 0) +
                (maze[row][col + 1] == 1 ? 1 : 0)

            if adjacentWalls <= 2 {
                maze[row][col] = 1
            }
        }
    }
}

func detectPathTileType(row: Int, col: Int, in maze: [[Int]]) -> PathTileType? {
    guard maze[row][col] == 0 else { return nil }

    let up = maze[row - 1][col] == 0
    let down = maze[row + 1][col] == 0
    let left = maze[row][col - 1] == 0
    let right = maze[row][col + 1] == 0

    let connections = [up, down, left, right].filter { $0 }.count

    switch connections {
    case 4:
        return .cross
    case 3:
        if !up { return .tDown }
        if !down { return .tUp }
        if !left { return .tRight }
        return .tLeft
    case 2:
        if up, down { return .vertical }
        if left, right { return .horizontal }
        if up, right { return .cornerBottomLeft }
        if up, left { return .cornerBottomRight }
        if down, right { return .cornerTopLeft }
        if down, left { return .cornerTopRight }
    case 1:
        if up { return .endUp }
        if down { return .endDown }
        if left { return .endLeft }
        if right { return .endRight }
    default:
        return nil
    }

    return nil
}

func spriteNameFor(tileType: PathTileType) -> String {
    switch tileType {
    case .vertical: return "pathVertical"
    case .horizontal: return "pathHorizontal"
    case .cornerTopLeft: return "pathRightDown"
    case .cornerTopRight: return "pathLeftDown"
    case .cornerBottomLeft: return "pathRightUp"
    case .cornerBottomRight: return "pathLeftUp"
    case .tUp: return "pathHorizontalUp"
    case .tDown: return "pathHorizontalDown"
    case .tLeft: return "pathVerticalLeft"
    case .tRight: return "pathVerticalRight"
    case .cross: return "pathAllDirections"
    case .endUp: return "pathEndUp"
    case .endDown: return "pathEndDown"
    case .endLeft: return "pathEndLeft"
    case .endRight: return "pathEndRight"
    }
}

func randomWallAsset() -> String {
    let options = [
        "pathTree",
        "pathGrass"
//        "warung1",
//        "warung2",
//        "warung3",
//        "house\(Int.random(in: 1 ... 5))"
    ]
    return options.randomElement()!
}

func randomHouseAsset() -> String {
    let options = [
        "house\(Int.random(in: 1 ... 10))"
    ]
    return options.randomElement()!
}
