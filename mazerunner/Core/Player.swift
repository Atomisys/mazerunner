import SpriteKit

final class Player: GameObject {
    
    // MARK: - GameObject Protocol Implementation
    
    var gridPosition: CGPoint
    let sprite: SKSpriteNode
    let gridType: GridCellType = .player
    
    // MARK: - Player Properties
    
    /// Whether the player can be moved by other systems
    var isMovable: Bool = true
    
    /// Whether the player blocks movement of other objects
    var blocksMovement: Bool = false
    
    /// Whether the player can be destroyed/removed
    var isDestructible: Bool = false
    
    /// Current movement direction
    private var currentDirection: CGVector = .zero
    
    /// Whether the player is currently moving
    private var isMoving: Bool = false
    
    /// Reference to the grid system for position conversions
    private let gridSystem: GridSystem
    
    /// Reference to the game state manager
    private let gameStateManager: GameStateManager
    
    // MARK: - Initialization
    
    init(gridSystem: GridSystem, gameStateManager: GameStateManager) {
        self.gridSystem = gridSystem
        self.gameStateManager = gameStateManager
        
        // Initialize at default spawn position (bottom center)
        self.gridPosition = CGPoint(x: 6, y: 25)
        
        // Create the player sprite
        self.sprite = Player.createPlayerSprite(gridSize: gridSystem.cellSize)
        
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
    
    // MARK: - Player Movement
    
    /// Set the current movement direction
    /// - Parameter direction: The direction vector
    func setDirection(_ direction: CGVector) {
        currentDirection = direction
    }
    
    /// Get the current movement direction
    var direction: CGVector {
        return currentDirection
    }
    
    /// Check if the player is currently moving
    var isCurrentlyMoving: Bool {
        return isMoving
    }
    
    /// Start movement in the current direction
    /// - Returns: True if movement started successfully
    @discardableResult
    func startMovement() -> Bool {
        guard !isMoving && currentDirection != .zero else { return false }
        
        let targetGridPos = CGPoint(
            x: gridPosition.x + currentDirection.dx,
            y: gridPosition.y + currentDirection.dy
        )
        
        // Check if the target position is valid
        guard gridSystem.isValidGridPosition(targetGridPos) else { return false }
        
        // Start the movement animation
        moveTo(targetGridPos)
        return true
    }
    
    /// Stop all movement
    func stopMovement() {
        isMoving = false
        sprite.removeAllActions()
    }
    
    /// Move to a specific grid position with animation
    /// - Parameter targetGridPos: The target grid position
    /// - Returns: True if movement started successfully
    @discardableResult
    func moveTo(_ targetGridPos: CGPoint) -> Bool {
        guard !isMoving else { return false }
        guard gridSystem.isValidGridPosition(targetGridPos) else { return false }
        
        let targetWorldPos = gridSystem.getWorldPosition(targetGridPos)
        let moveDuration = Double(gridSystem.cellSize) / Double(gameStateManager.playerSpeed)
        
        isMoving = true
        
        let moveAction = SKAction.move(to: targetWorldPos, duration: moveDuration)
        moveAction.timingMode = .linear
        
        let completionAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.isMoving = false
            self.gridPosition = targetGridPos
            self.onMoved(from: self.gridPosition, to: targetGridPos)
            
            // Continue movement if direction is still set
            if self.currentDirection != .zero {
                self.startMovement()
            }
        }
        
        let sequence = SKAction.sequence([moveAction, completionAction])
        sprite.run(sequence, withKey: "playerMovement")
        
        return true
    }
    
    // MARK: - Player Actions
    
    /// Handle wall digging at the current position
    /// - Returns: True if a wall was dug
    @discardableResult
    func digWall() -> Bool {
        // This will be implemented when we integrate with GameGrid
        // For now, just mark the tunnel as dug
        gameStateManager.markTunnelDug(at: sprite.position)
        return true
    }
    
    /// Handle player being hit by an enemy
    func onHit() {
        // Visual feedback
        let hitEffect = SKSpriteNode(color: SKColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5), size: sprite.size)
        hitEffect.position = sprite.position
        sprite.parent?.addChild(hitEffect)
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        hitEffect.run(SKAction.sequence([fadeOut, remove]))
        
        // Lose a life
        _ = gameStateManager.loseLife()
    }
    
    /// Reset player to spawn position
    func resetToSpawn() {
        stopMovement()
        currentDirection = .zero
        initialize(at: CGPoint(x: 6, y: 25)) // Default spawn position
    }
    
    // MARK: - Visual Effects
    
    /// Change player color to indicate slowdown
    func showSlowdownEffect() {
        sprite.color = SKColor(red: 0.7, green: 0.7, blue: 1.0, alpha: 1.0)
    }
    
    /// Restore normal player color
    func restoreNormalColor() {
        sprite.color = SKColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 1.0)
    }
    
    // MARK: - GameObject Event Handlers
    
    func onPlaced(at gridPosition: CGPoint) {
        print("Player placed at grid position: \(gridPosition)")
    }
    
    func onRemoved() {
        print("Player removed from grid")
    }
    
    func onMoved(from: CGPoint, to: CGPoint) {
        print("Player moved from \(from) to \(to)")
    }
    
    func update(deltaTime: TimeInterval) {
        // Update player logic here if needed
        // This will be called each frame
    }
    
    // MARK: - Static Factory Methods
    
    /// Create the player sprite with visual details
    /// - Parameter gridSize: The size of grid cells
    /// - Returns: Configured player sprite
    private static func createPlayerSprite(gridSize: CGFloat) -> SKSpriteNode {
        let playerSize = CGSize(width: gridSize * 0.8, height: gridSize * 0.8)
        let player = SKSpriteNode(color: SKColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 1.0), size: playerSize)
        
        player.zPosition = 2
        player.name = "player"
        
        // Add player details (eyes)
        let eye1 = SKShapeNode(circleOfRadius: 2)
        eye1.fillColor = .black
        eye1.position = CGPoint(x: -6, y: 4)
        player.addChild(eye1)
        
        let eye2 = SKShapeNode(circleOfRadius: 2)
        eye2.fillColor = .black
        eye2.position = CGPoint(x: 6, y: 4)
        player.addChild(eye2)
        
        return player
    }
    
    // MARK: - Utility Methods
    
    /// Check if the player is at the grid center
    var isAtGridCenter: Bool {
        return gridSystem.isAtGridCenter(sprite.position)
    }
    
    /// Get the player's world position
    var worldPosition: CGPoint {
        return sprite.position
    }
    
    /// Set the player's world position and update grid position
    /// - Parameter position: The new world position
    func setWorldPosition(_ position: CGPoint) {
        sprite.position = position
        updateGridPosition()
    }
    
    /// Snap the player to the nearest grid center
    func snapToGridCenter() {
        let centeredPosition = gridSystem.snapToGridCenter(sprite.position)
        sprite.position = centeredPosition
        updateGridPosition()
    }
}
