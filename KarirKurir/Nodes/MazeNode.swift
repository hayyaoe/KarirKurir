import SpriteKit

class MazeNode: SKNode {
    
    // Physics category for walls
    static let wallCategory: UInt32 = 0x1 << 2
    
    private var mazeGrid: [[MazeCellType]]
    private var tileSize: CGSize
    
    init(mazeGrid: [[MazeCellType]], tileSize: CGSize) {
        self.mazeGrid = mazeGrid
        self.tileSize = tileSize
        super.init()
        
        generateMazeWalls()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func generateMazeWalls() {
        let wallColor = SKColor(white: 0.7, alpha: 1.0)
        
        for x in 0..<mazeGrid.count {
            for y in 0..<mazeGrid[x].count {
                if mazeGrid[x][y] == .wall {
                    let wall = SKSpriteNode(color: wallColor, size: tileSize)
                    // Position is calculated from the bottom-left, so we offset
                    wall.position = CGPoint(
                        x: CGFloat(x) * tileSize.width,
                        y: CGFloat(y) * tileSize.height
                    )
                    
                    // Setup physics for the wall
                    wall.physicsBody = SKPhysicsBody(rectangleOf: tileSize)
                    wall.physicsBody?.isDynamic = false
                    wall.physicsBody?.categoryBitMask = MazeNode.wallCategory
                    wall.physicsBody?.collisionBitMask = PlayerNode.category // Only player collides with walls
                    
                    addChild(wall)
                }
            }
        }
    }
}
