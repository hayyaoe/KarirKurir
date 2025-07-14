//
//  GameScene.swift
//  pacman
//
//  Created by Mahardika Putra Wardhana on 09/07/25.
//

import SpriteKit

class GameScene: SKScene {
    // MARK: - Game Elements

    var player: PlayerNode!

    // get current maze -> render walls -> render destinations
    var currentMaze: [[Int]] = []
    var walls: [SKSpriteNode] = []
    var destinations: [SKSpriteNode] = []

    // Next Object
    var nextMaze: [[Int]] = []
    var nextWalls: [[SKSpriteNode]] = []
    var nextDestinations: [[SKSpriteNode]] = []

    // MARK: - Game State

    var currentDirection: Direction = .right
    var nextDirection: Direction?
    var score: Int = 0
    var level: Int = 1

    // MARK: - UI

    var scoreLabel: SKLabelNode!
    var levelLabel: SKLabelNode!

    // MARK: - Constants

    let playerSpeed: CGFloat = 100.0
    let gridSize: CGFloat = 30.0

    // MARK: - Direction Enum

    enum Direction {
        case up, down, left, right

        var vector: CGVector {
            switch self {
            case .up: return CGVector(dx: 0, dy: 1)
            case .down: return CGVector(dx: 0, dy: -1)
            case .left: return CGVector(dx: -1, dy: 0)
            case .right: return CGVector(dx: 1, dy: 0)
            }
        }
    }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupPlayer(position: CGPoint(x: 50, y: 50))
        setupGestures()
        currentMaze = getMazeLayout(for: level)
        setupMaze(maze: currentMaze)
        startPlayerMovement()
        setupUI()
        physicsWorld.contactDelegate = self
    }

    // MARK: - Setup Functions

    func setupPlayer(position: CGPoint) {
        player = PlayerNode(tileSize: CGSize(width: gridSize, height: gridSize))
        player.position = position
        addChild(player)
    }

    func setupUI() {
        scoreLabel = createLabel(text: "Score: 0", position: CGPoint(x: 100, y: size.height - 50))
        levelLabel = createLabel(text: "Level: 1", position: CGPoint(x: 250, y: size.height - 50))
        addChild(scoreLabel)
        addChild(levelLabel)
    }

    func createLabel(text: String, position: CGPoint) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Arial-BoldMT")
        label.text = text
        label.fontSize = 20
        label.fontColor = .white
        label.position = position
        return label
    }

    func setupGestures() {
        let directions: [UISwipeGestureRecognizer.Direction] = [.up, .down, .left, .right]
        for dir in directions {
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
            swipe.direction = dir
            view?.addGestureRecognizer(swipe)
        }
    }

    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .up: nextDirection = .up
        case .down: nextDirection = .down
        case .left: nextDirection = .left
        case .right: nextDirection = .right
        default: break
        }
    }

    func setupMaze(maze: [[Int]]) {
        walls.forEach { $0.removeFromParent() }
        destinations.forEach { $0.removeFromParent() }
        walls.removeAll()
        destinations.removeAll()

        let wallColor = [UIColor.blue, .purple, .red, .green, .orange, .cyan][(level - 1) % 6]

        for (row, rowData) in maze.enumerated() {
            for (col, cell) in rowData.enumerated() {
                let position = CGPoint(
                    x: CGFloat(col) * gridSize + gridSize/2,
                    y: CGFloat(maze.count - row - 1) * gridSize + gridSize/2
                )
                if cell == 1 {
                    let wall = SKSpriteNode(color: wallColor, size: CGSize(width: gridSize, height: gridSize))
                    wall.position = position
                    wall.physicsBody = SKPhysicsBody(rectangleOf: wall.size)
                    wall.physicsBody?.categoryBitMask = 2
                    wall.physicsBody?.isDynamic = false
                    walls.append(wall)
                    addChild(wall)
                }
            }
        }

        let reachablePositions = findReachablePositions(from: player.position, gridSize: gridSize, maze: maze)
        setupDestinations(fromReachable: reachablePositions)

        nextMaze = getMazeLayout(for: level + 1)
    }

    func setupDestinations(fromReachable positions: [CGPoint], count: Int = 3) {
        let selectedPositions = generatePoissonDiskPoints(from: positions, minDistance: gridSize * 4, maxPoints: count)

        for (index, pos) in selectedPositions.enumerated() {
            let color = UIColor(hue: CGFloat(index)/CGFloat(count), saturation: 1, brightness: 1, alpha: 1)
            let dest = SKSpriteNode(color: color, size: CGSize(width: 20, height: 20))
            dest.position = pos
            dest.physicsBody = SKPhysicsBody(rectangleOf: dest.size)
            dest.physicsBody?.categoryBitMask = 4
            dest.physicsBody?.contactTestBitMask = 1
            dest.physicsBody?.collisionBitMask = 0
            dest.physicsBody?.isDynamic = false
            dest.run(SKAction.repeatForever(.sequence([
                .scale(to: 1.3, duration: 0.8),
                .scale(to: 1.0, duration: 0.8)
            ])))
            addChild(dest)
            destinations.append(dest)
        }
    }

    // MARK: - Player Movement

    func startPlayerMovement() {
        removeAction(forKey: "playerMovement")
        let movementAction = SKAction.repeatForever(.sequence([
            .run { [weak self] in self?.updatePlayerMovement() },
            .wait(forDuration: 0.02)
        ]))
        run(movementAction, withKey: "playerMovement")
    }

    var isMoving = false

    func updatePlayerMovement() {
        guard !isMoving else { return }

        if let next = nextDirection, canMove(in: next) {
            currentDirection = next
            nextDirection = nil
        }

        if canMove(in: currentDirection) {
            let vector = currentDirection.vector
            let targetPosition = CGPoint(
                x: player.position.x + vector.dx * gridSize,
                y: player.position.y + vector.dy * gridSize
            )

            isMoving = true
            player.move(to: targetPosition) { [weak self] in
                self?.isMoving = false
            }
        }
    }

    func canMove(in direction: Direction) -> Bool {
        let vector = direction.vector
        let future = CGPoint(
            x: player.position.x + vector.dx * (gridSize/2 + 5),
            y: player.position.y + vector.dy * (gridSize/2 + 5)
        )

        if future.x < 0 || future.x > size.width || future.y < 0 || future.y > size.height {
            return false
        }

        return !walls.contains(where: { $0.frame.contains(future) })
    }

    // MARK: - Game Progress

    func reachDestination(at index: Int) {
        score += 100 * level
        scoreLabel.text = "Score: \(score)"
        destinations[index].removeFromParent()
        destinations.remove(at: index)

        let label = SKLabelNode(fontNamed: "Arial-BoldMT")
        label.text = "Destination Reached!"
        label.fontSize = 25
        label.fontColor = .green
        label.position = CGPoint(x: size.width/2, y: size.height/2 + 100)
        addChild(label)
        label.run(.sequence([.fadeOut(withDuration: 1.5), .removeFromParent()]))

        if destinations.isEmpty {
            nextLevel()
        }
    }

    func nextLevel() {
        level += 1
        levelLabel.text = "Level: \(level)"

        run(.sequence([
            .wait(forDuration: 0.5),
            .run { [weak self] in
                self?.currentMaze = self?.nextMaze ?? []
                self?.setupMaze(maze: self!.currentMaze)
                self?.findSafeStartingPosition()
                self?.currentDirection = .right
                self?.nextDirection = nil
            }
        ]))
    }

    func findSafeStartingPosition() {
        for row in stride(from: currentMaze.count - 2, to: 0, by: -1) {
            for col in 1 ..< currentMaze[row].count {
                if currentMaze[row][col] == 0 {
                    let pos = CGPoint(
                        x: CGFloat(col) * gridSize + gridSize/2,
                        y: CGFloat(currentMaze.count - row - 1) * gridSize + gridSize/2
                    )
                    let safe = destinations.allSatisfy {
                        hypot($0.position.x - pos.x, $0.position.y - pos.y) > gridSize * 3
                    }
                    if safe {
                        player.removeFromParent()
                        setupPlayer(position: pos)
                        startPlayerMovement()
                        return
                    }
                }
            }
        }
        player.position = CGPoint(x: gridSize + gridSize/2, y: gridSize + gridSize/2)
    }

    override func update(_ currentTime: TimeInterval) {
        // Can be used for game timers, future AI, etc.
    }
}

// MARK: - Contact Handling

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        let (a, b) = (contact.bodyA, contact.bodyB)
        if a.categoryBitMask == 1 && b.categoryBitMask == 4,
           let index = destinations.firstIndex(where: { $0 == b.node })
        {
            reachDestination(at: index)
        } else if b.categoryBitMask == 1 && a.categoryBitMask == 4,
                  let index = destinations.firstIndex(where: { $0 == a.node })
        {
            reachDestination(at: index)
        }
    }
}
