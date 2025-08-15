import SpriteKit

final class Enemy: GameObject {
    
    // MARK: - GameObject Protocol Implementation
    
    var gridPosition: CGPoint
    var sprite: SKSpriteNode
    let gridType: GridCellType = .enemy
    
    // MARK: - Enemy Properties (Preserved from original)
    
    let color: SKColor
    var direction: Direction = .down
    var lastGridPosition: CGPoint = .zero
    // Prebuilt variants with pupils offset: [up, down, left, right]
    var directionalSprites: [SKSpriteNode] = []
    
    // MARK: - GameObject Properties
    
    /// Whether the enemy can be moved by other systems
    var isMovable: Bool = true
    
    /// Whether the enemy blocks movement of other objects
    var blocksMovement: Bool = false
    
    /// Whether the enemy can be destroyed/removed
    var isDestructible: Bool = true
    
    // MARK: - Private Properties
    
    /// Reference to the grid system for position conversions
    private let gridSystem: GridSystem
    
    /// Whether the enemy is currently moving
    private var isMoving: Bool = false
    
    /// Current movement speed
    private var movementSpeed: CGFloat = 100.0
    
    // MARK: - Initialization
    
    /// Legacy initializer - preserved for backward compatibility
    init(sprite: SKSpriteNode, color: SKColor) {
        self.sprite = sprite
        self.color = color
        self.gridSystem = GridSystem(sceneSize: CGSize(width: 400, height: 800), gridWidth: 12, gridHeight: 27)
        self.gridPosition = CGPoint.zero
        self.updateGridPosition()
    }
    
    /// New initializer with grid system integration
    init(sprite: SKSpriteNode, color: SKColor, gridSystem: GridSystem, initialGridPosition: CGPoint) {
        self.sprite = sprite
        self.color = color
        self.gridSystem = gridSystem
        self.gridPosition = initialGridPosition
        
        // Initialize position
        updatePosition()
    }
    
    // MARK: - GameObject Protocol Methods
    
    func updatePosition() {
        let worldPosition = gridSystem.getWorldPosition(gridPosition)
        sprite.position = worldPosition
    }
    
    func updateGridPosition() {
        gridPosition = gridSystem.getGridPosition(sprite.position)
    }
    
    func initialize(at gridPosition: CGPoint) {
        self.gridPosition = gridPosition
        updatePosition()
        onPlaced(at: gridPosition)
    }
    
    func destroy() {
        sprite.removeFromParent()
        onRemoved()
    }
    
    // MARK: - Enemy Movement (Enhanced)
    
    /// Set the enemy's movement speed
    /// - Parameter speed: The movement speed
    func setMovementSpeed(_ speed: CGFloat) {
        movementSpeed = speed
    }
    
    /// Get the current movement speed
    var currentSpeed: CGFloat {
        return movementSpeed
    }
    
    /// Check if the enemy is currently moving
    var isCurrentlyMoving: Bool {
        return isMoving
    }
    
    /// Move the enemy to a specific grid position with animation
    /// - Parameter targetGridPos: The target grid position
    /// - Returns: True if movement started successfully
    @discardableResult
    func moveTo(_ targetGridPos: CGPoint) -> Bool {
        guard !isMoving else { return false }
        guard gridSystem.isValidGridPosition(targetGridPos) else { return false }
        
        let targetWorldPos = gridSystem.getWorldPosition(targetGridPos)
        let moveDuration = Double(gridSystem.cellSize) / Double(movementSpeed)
        
        isMoving = true
        
        let moveAction = SKAction.move(to: targetWorldPos, duration: moveDuration)
        moveAction.timingMode = .linear
        
        let completionAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.isMoving = false
            self.lastGridPosition = self.gridPosition
            self.gridPosition = targetGridPos
            self.onMoved(from: self.lastGridPosition, to: targetGridPos)
        }
        
        let sequence = SKAction.sequence([moveAction, completionAction])
        sprite.run(sequence, withKey: "enemyMovement")
        
        return true
    }
    
    /// Stop all enemy movement
    func stopMovement() {
        isMoving = false
        sprite.removeAllActions()
    }
    
    /// Update the enemy's directional sprite based on current direction
    func updateDirectionalSprite() {
        guard !directionalSprites.isEmpty else { return }
        
        let index: Int
        switch direction {
        case .up: index = 0
        case .down: index = 1
        case .left: index = 2
        case .right: index = 3
        }
        
        let oldNode = sprite
        let newNode = directionalSprites[index]
        
        // If this node is already active, skip
        if newNode === oldNode { return }
        
        newNode.position = oldNode.position
        newNode.zPosition = oldNode.zPosition
        newNode.name = oldNode.name
        
        oldNode.parent?.addChild(newNode)
        oldNode.removeFromParent()
        sprite = newNode
    }
    
    /// Set the enemy direction and update the sprite
    /// - Parameter newDirection: The new direction
    func setDirection(_ newDirection: Direction) {
        direction = newDirection
        updateDirectionalSprite()
    }
    
    /// Get the direction as a vector
    var directionVector: CGVector {
        switch direction {
        case .up:
            return CGVector(dx: 0, dy: 1)
        case .down:
            return CGVector(dx: 0, dy: -1)
        case .left:
            return CGVector(dx: -1, dy: 0)
        case .right:
            return CGVector(dx: 1, dy: 0)
        }
    }
    
    /// Get the opposite direction
    var oppositeDirection: Direction {
        switch direction {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }
    
    // MARK: - AI Pathfinding (Enhanced)
    
    /// Get valid adjacent positions for pathfinding
    /// - Parameter gameGrid: The game grid to check against
    /// - Returns: Array of valid adjacent grid positions
    func getValidAdjacentPositions(gameGrid: GameGrid) -> [CGPoint] {
        return gameGrid.getValidAdjacentPositions(gridPosition)
    }
    
    /// Find the best direction to move towards a target
    /// - Parameters:
    ///   - targetGridPos: The target grid position
    ///   - gameGrid: The game grid to check against
    /// - Returns: The best direction to move, or nil if no valid direction
    func findBestDirection(to targetGridPos: CGPoint, gameGrid: GameGrid) -> Direction? {
        let adjacentPositions = getValidAdjacentPositions(gameGrid: gameGrid)
        
        var bestDirection: Direction?
        var shortestDistance: CGFloat = CGFloat.greatestFiniteMagnitude
        
        for position in adjacentPositions {
            // Don't go back to the position we just came from
            if position == lastGridPosition { continue }
            
            let distance = gridSystem.euclideanGridDistance(from: position, to: targetGridPos)
            if distance < shortestDistance {
                shortestDistance = distance
                bestDirection = getDirectionToPosition(position)
            }
        }
        
        return bestDirection
    }
    
    /// Get the direction needed to reach a specific position
    /// - Parameter targetPos: The target position
    /// - Returns: The direction to move
    private func getDirectionToPosition(_ targetPos: CGPoint) -> Direction {
        let deltaX = targetPos.x - gridPosition.x
        let deltaY = targetPos.y - gridPosition.y
        
        if abs(deltaX) > abs(deltaY) {
            return deltaX > 0 ? .right : .left
        } else {
            return deltaY > 0 ? .up : .down
        }
    }
    
    // MARK: - GameObject Event Handlers
    
    func onPlaced(at gridPosition: CGPoint) {
        print("Enemy placed at grid position: \(gridPosition)")
    }
    
    func onRemoved() {
        print("Enemy removed from grid")
    }
    
    func onMoved(from: CGPoint, to: CGPoint) {
        print("Enemy moved from \(from) to \(to)")
        // Update directional sprite when moving
        updateDirectionalSprite()
    }
    
    func update(deltaTime: TimeInterval) {
        // Update enemy AI logic here if needed
        // This will be called each frame
    }
    
    // MARK: - Utility Methods
    
    /// Check if the enemy is at the grid center
    var isAtGridCenter: Bool {
        return gridSystem.isAtGridCenter(sprite.position)
    }
    
    /// Get the enemy's world position
    var worldPosition: CGPoint {
        return sprite.position
    }
    
    /// Set the enemy's world position and update grid position
    /// - Parameter position: The new world position
    func setWorldPosition(_ position: CGPoint) {
        sprite.position = position
        updateGridPosition()
    }
    
    /// Snap the enemy to the nearest grid center
    func snapToGridCenter() {
        let centeredPosition = gridSystem.snapToGridCenter(sprite.position)
        sprite.position = centeredPosition
        updateGridPosition()
    }
    
    /// Reset the enemy to a specific grid position
    /// - Parameter gridPosition: The new grid position
    func resetToPosition(_ gridPosition: CGPoint) {
        stopMovement()
        lastGridPosition = CGPoint.zero
        initialize(at: gridPosition)
    }
}
