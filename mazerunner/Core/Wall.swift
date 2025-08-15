import SpriteKit

// MARK: - Wall Types
enum WallType {
    case regular
    case border
}

final class Wall: GameObject {
    
    // MARK: - GameObject Protocol Implementation
    
    var gridPosition: CGPoint
    let sprite: SKSpriteNode
    var gridType: GridCellType {
        return wallType == .border ? .borderWall : .wall
    }
    
    // MARK: - Wall Properties
    
    /// The type of wall (regular or border)
    let wallType: WallType
    
    /// Whether the wall can be moved by other systems
    var isMovable: Bool = false
    
    /// Whether the wall blocks movement of other objects
    var blocksMovement: Bool = true
    
    /// Whether the wall can be destroyed/removed
    var isDestructible: Bool {
        return wallType == .regular // Only regular walls can be dug
    }
    
    /// Whether the wall has been dug
    private(set) var isDug: Bool = false
    
    /// Whether the wall is currently being dug
    private(set) var isBeingDug: Bool = false
    
    // MARK: - Private Properties
    
    /// Reference to the grid system for position conversions
    private let gridSystem: GridSystem
    
    /// Reference to the game state manager
    private let gameStateManager: GameStateManager
    
    /// Digging effect node
    private var diggingEffectNode: SKSpriteNode?
    
    // MARK: - Initialization
    
    init(wallType: WallType, gridSystem: GridSystem, gameStateManager: GameStateManager, gridPosition: CGPoint) {
        self.wallType = wallType
        self.gridSystem = gridSystem
        self.gameStateManager = gameStateManager
        self.gridPosition = gridPosition
        
        // Create the wall sprite
        self.sprite = Wall.createWallSprite(wallType: wallType, gridSize: gridSystem.cellSize)
        
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
        stopDiggingEffect()
        sprite.removeFromParent()
        onRemoved()
    }
    
    // MARK: - Wall Digging
    
    /// Attempt to dig the wall
    /// - Returns: True if digging was successful, false if wall cannot be dug
    @discardableResult
    func dig() -> Bool {
        guard isDestructible else { return false }
        guard !isDug else { return false }
        guard !isBeingDug else { return false }
        
        isBeingDug = true
        
        // Show digging effect
        showDiggingEffect()
        
        // Award points for digging
        gameStateManager.addScore(10)
        
        // Mark tunnel as dug
        gameStateManager.markTunnelDug(at: sprite.position)
        
        // Play digging sound (will be handled by AudioSystem)
        print("Wall dug! +10 points")
        
        // Complete digging after effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.completeDigging()
        }
        
        return true
    }
    
    /// Complete the digging process
    private func completeDigging() {
        isBeingDug = false
        isDug = true
        
        // Hide the wall sprite
        sprite.alpha = 0.0
        
        // Mark as dug in the grid
        // This will be handled by the GameGrid when we integrate it
    }
    
    /// Check if the wall can be dug
    var canBeDug: Bool {
        return isDestructible && !isDug && !isBeingDug
    }
    
    /// Check if the wall is a border wall
    var isBorderWall: Bool {
        return wallType == .border
    }
    
    /// Check if the wall is a regular wall
    var isRegularWall: Bool {
        return wallType == .regular
    }
    
    // MARK: - Visual Effects
    
    /// Show digging effect
    private func showDiggingEffect() {
        guard diggingEffectNode == nil else { return }
        
        let digEffect = SKSpriteNode(color: SKColor(red: 0.8, green: 0.6, blue: 0.4, alpha: 1.0), size: CGSize(width: gridSystem.cellSize * 0.5, height: gridSystem.cellSize * 0.5))
        digEffect.position = sprite.position
        digEffect.alpha = 0.8
        digEffect.zPosition = sprite.zPosition + 1
        sprite.parent?.addChild(digEffect)
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let remove = SKAction.removeFromParent()
        digEffect.run(SKAction.sequence([fadeOut, remove]))
        
        diggingEffectNode = digEffect
    }
    
    /// Stop digging effect
    private func stopDiggingEffect() {
        diggingEffectNode?.removeFromParent()
        diggingEffectNode = nil
    }
    
    /// Create a pulsing effect for the wall (to indicate it's diggable)
    func startPulseAnimation() {
        guard isDestructible && !isDug else { return }
        
        let scaleUp = SKAction.scale(to: 1.05, duration: 0.3)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.3)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        let repeatForever = SKAction.repeatForever(sequence)
        
        sprite.run(repeatForever, withKey: "pulseAnimation")
    }
    
    /// Stop the pulsing effect
    func stopPulseAnimation() {
        sprite.removeAction(forKey: "pulseAnimation")
        sprite.setScale(1.0)
    }
    
    /// Highlight the wall to indicate it's diggable
    func highlight() {
        guard isDestructible && !isDug else { return }
        
        let originalColor = sprite.color
        let highlightColor = SKColor(red: 0.8, green: 0.6, blue: 0.4, alpha: 1.0)
        
        let colorize = SKAction.colorize(with: highlightColor, colorBlendFactor: 0.5, duration: 0.2)
        let restore = SKAction.colorize(with: originalColor, colorBlendFactor: 0.0, duration: 0.2)
        let sequence = SKAction.sequence([colorize, restore])
        
        sprite.run(sequence)
    }
    
    // MARK: - GameObject Event Handlers
    
    func onPlaced(at gridPosition: CGPoint) {
        print("\(wallType) wall placed at grid position: \(gridPosition)")
        
        // Start pulse animation for diggable walls
        if isDestructible {
            startPulseAnimation()
        }
    }
    
    func onRemoved() {
        print("\(wallType) wall removed from grid")
        stopPulseAnimation()
    }
    
    func onMoved(from: CGPoint, to: CGPoint) {
        print("\(wallType) wall moved from \(from) to \(to)")
    }
    
    func update(deltaTime: TimeInterval) {
        // Update wall logic here if needed
        // This will be called each frame
    }
    
    // MARK: - Static Factory Methods
    
    /// Create the wall sprite with visual details
    /// - Parameters:
    ///   - wallType: The type of wall to create
    ///   - gridSize: The size of grid cells
    /// - Returns: Configured wall sprite
    private static func createWallSprite(wallType: WallType, gridSize: CGFloat) -> SKSpriteNode {
        let wall: SKSpriteNode
        
        switch wallType {
        case .regular:
            // Regular wall with pixelated effect
            wall = SKSpriteNode(color: SKColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0), size: CGSize(width: gridSize, height: gridSize))
            wall.name = "wall"
            
            // Add pixelated effect with darker borders
            let border = SKShapeNode(rectOf: CGSize(width: gridSize, height: gridSize))
            border.strokeColor = SKColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0)
            border.lineWidth = 2
            border.position = CGPoint.zero
            wall.addChild(border)
            
        case .border:
            // Border wall with image
            wall = SKSpriteNode(imageNamed: "borderwall.png")
            wall.size = CGSize(width: gridSize, height: gridSize)
            wall.name = "borderWall"
        }
        
        wall.zPosition = 0
        return wall
    }
    
    // MARK: - Utility Methods
    
    /// Check if the wall is at the grid center
    var isAtGridCenter: Bool {
        return gridSystem.isAtGridCenter(sprite.position)
    }
    
    /// Get the wall's world position
    var worldPosition: CGPoint {
        return sprite.position
    }
    
    /// Set the wall's world position and update grid position
    /// - Parameter position: The new world position
    func setWorldPosition(_ position: CGPoint) {
        sprite.position = position
        updateGridPosition()
    }
    
    /// Snap the wall to the nearest grid center
    func snapToGridCenter() {
        let centeredPosition = gridSystem.snapToGridCenter(sprite.position)
        sprite.position = centeredPosition
        updateGridPosition()
    }
    
    /// Get the wall type as a string
    var typeString: String {
        return wallType == .border ? "Border" : "Regular"
    }
    
    /// Get the digging status
    var dug: Bool {
        return isDug
    }
    
    /// Get the digging in progress status
    var beingDug: Bool {
        return isBeingDug
    }
}
