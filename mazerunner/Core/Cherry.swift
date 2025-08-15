import SpriteKit

final class Cherry: GameObject {
    
    // MARK: - GameObject Protocol Implementation
    
    var gridPosition: CGPoint
    let sprite: SKSpriteNode
    let gridType: GridCellType = .cherry
    
    // MARK: - Cherry Properties
    
    /// Whether the cherry can be moved by other systems
    var isMovable: Bool = false
    
    /// Whether the cherry blocks movement of other objects
    var blocksMovement: Bool = false
    
    /// Whether the cherry can be destroyed/removed
    var isDestructible: Bool = true
    
    /// Whether the cherry has been collected
    private(set) var isCollected: Bool = false
    
    /// Collection value (points awarded when collected)
    let collectionValue: Int = 100
    
    // MARK: - Private Properties
    
    /// Reference to the grid system for position conversions
    private let gridSystem: GridSystem
    
    /// Reference to the game state manager
    private let gameStateManager: GameStateManager
    
    /// Animation nodes for visual effects
    private var sparkleNode: SKShapeNode?
    private var collectionEffectNode: SKLabelNode?
    
    // MARK: - Initialization
    
    init(gridSystem: GridSystem, gameStateManager: GameStateManager, gridPosition: CGPoint) {
        self.gridSystem = gridSystem
        self.gameStateManager = gameStateManager
        self.gridPosition = gridPosition
        
        // Create the cherry sprite
        self.sprite = Cherry.createCherrySprite(gridSize: gridSystem.cellSize)
        
        // Initialize position
        updatePosition()
        
        // Start sparkle animation
        startSparkleAnimation()
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
        stopSparkleAnimation()
        sprite.removeFromParent()
        onRemoved()
    }
    
    // MARK: - Cherry Collection
    
    /// Collect the cherry
    /// - Returns: True if collection was successful, false if already collected
    @discardableResult
    func collect() -> Bool {
        guard !isCollected else { return false }
        
        isCollected = true
        
        // Award points
        gameStateManager.addScore(collectionValue)
        
        // Show collection effect
        showCollectionEffect()
        
        // Play collection sound (will be handled by AudioSystem)
        // For now, just print
        print("Cherry collected! +\(collectionValue) points")
        
        // Mark as collected in game state
        _ = gameStateManager.collectCherry()
        
        // Remove from scene after effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.destroy()
        }
        
        return true
    }
    
    /// Check if the cherry can be collected by the player
    /// - Parameter playerPosition: The player's world position
    /// - Returns: True if the cherry is within collection range
    func canBeCollected(by playerPosition: CGPoint) -> Bool {
        guard !isCollected else { return false }
        
        let distance = sqrt(
            pow(playerPosition.x - sprite.position.x, 2) +
            pow(playerPosition.y - sprite.position.y, 2)
        )
        
        // Collection radius - more forgiving than frame intersection
        let collectionRadius = gridSystem.cellSize * 0.6
        return distance < collectionRadius
    }
    
    // MARK: - Visual Effects
    
    /// Start the sparkle animation
    private func startSparkleAnimation() {
        guard sparkleNode == nil else { return }
        
        let sparkle = SKShapeNode(circleOfRadius: 2)
        sparkle.fillColor = SKColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
        sparkle.position = CGPoint(x: 6, y: 6)
        sparkle.name = "sparkle"
        sprite.addChild(sparkle)
        
        // Animate sparkle
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        let sequence = SKAction.sequence([fadeOut, fadeIn])
        let repeatForever = SKAction.repeatForever(sequence)
        
        sparkle.run(repeatForever)
        sparkleNode = sparkle
    }
    
    /// Stop the sparkle animation
    private func stopSparkleAnimation() {
        sparkleNode?.removeFromParent()
        sparkleNode = nil
    }
    
    /// Show collection effect
    private func showCollectionEffect() {
        // Create score effect
        let effect = SKLabelNode(fontNamed: "Courier-Bold")
        effect.fontSize = 16
        effect.fontColor = SKColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
        effect.position = sprite.position
        effect.text = "+\(collectionValue)"
        effect.zPosition = 1000 // Ensure it appears above other elements
        sprite.parent?.addChild(effect)
        
        // Animate the effect
        let moveUp = SKAction.moveBy(x: 0, y: 30, duration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let remove = SKAction.removeFromParent()
        let group = SKAction.group([moveUp, fadeOut])
        let sequence = SKAction.sequence([group, remove])
        
        effect.run(sequence)
        collectionEffectNode = effect
        
        // Hide the cherry sprite
        sprite.alpha = 0.0
    }
    
    /// Create a pulsing effect for the cherry
    func startPulseAnimation() {
        let scaleUp = SKAction.scale(to: 1.1, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        let sequence = SKAction.sequence([scaleUp, scaleDown])
        let repeatForever = SKAction.repeatForever(sequence)
        
        sprite.run(repeatForever, withKey: "pulseAnimation")
    }
    
    /// Stop the pulsing effect
    func stopPulseAnimation() {
        sprite.removeAction(forKey: "pulseAnimation")
        sprite.setScale(1.0)
    }
    
    // MARK: - GameObject Event Handlers
    
    func onPlaced(at gridPosition: CGPoint) {
        print("Cherry placed at grid position: \(gridPosition)")
        startPulseAnimation()
    }
    
    func onRemoved() {
        print("Cherry removed from grid")
        stopPulseAnimation()
    }
    
    func onMoved(from: CGPoint, to: CGPoint) {
        print("Cherry moved from \(from) to \(to)")
    }
    
    func update(deltaTime: TimeInterval) {
        // Update cherry logic here if needed
        // This will be called each frame
    }
    
    // MARK: - Static Factory Methods
    
    /// Create the cherry sprite with visual details
    /// - Parameter gridSize: The size of grid cells
    /// - Returns: Configured cherry sprite
    private static func createCherrySprite(gridSize: CGFloat) -> SKSpriteNode {
        let cherry = SKSpriteNode(color: .clear, size: CGSize(width: gridSize * 0.8, height: gridSize * 0.8))
        cherry.zPosition = 1 // Above walls
        
        // Create cherry body
        let cherryBody = SKShapeNode(circleOfRadius: 8)
        cherryBody.fillColor = SKColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        cherryBody.strokeColor = SKColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)
        cherryBody.lineWidth = 1
        cherryBody.position = CGPoint(x: 0, y: 0)
        cherry.addChild(cherryBody)
        
        // Add cherry stem
        let stem = SKShapeNode()
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 8))
        path.addLine(to: CGPoint(x: 0, y: 12))
        stem.path = path
        stem.strokeColor = SKColor(red: 0.3, green: 0.6, blue: 0.0, alpha: 1.0)
        stem.lineWidth = 2
        cherry.addChild(stem)
        
        cherry.name = "cherry"
        return cherry
    }
    
    // MARK: - Utility Methods
    
    /// Check if the cherry is at the grid center
    var isAtGridCenter: Bool {
        return gridSystem.isAtGridCenter(sprite.position)
    }
    
    /// Get the cherry's world position
    var worldPosition: CGPoint {
        return sprite.position
    }
    
    /// Set the cherry's world position and update grid position
    /// - Parameter position: The new world position
    func setWorldPosition(_ position: CGPoint) {
        sprite.position = position
        updateGridPosition()
    }
    
    /// Snap the cherry to the nearest grid center
    func snapToGridCenter() {
        let centeredPosition = gridSystem.snapToGridCenter(sprite.position)
        sprite.position = centeredPosition
        updateGridPosition()
    }
    
    /// Get the collection status
    var collected: Bool {
        return isCollected
    }
    
    /// Get the collection value
    var value: Int {
        return collectionValue
    }
}
