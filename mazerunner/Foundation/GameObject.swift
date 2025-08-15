import SpriteKit

/// Protocol defining the base interface for all game objects
/// All game objects must implement this protocol to ensure consistency
protocol GameObject: AnyObject {
    
    // MARK: - Required Properties
    
    /// The grid position of this game object
    var gridPosition: CGPoint { get set }
    
    /// The sprite node representing this object visually
    var sprite: SKSpriteNode { get }
    
    /// The type of this game object for grid tracking
    var gridType: GridCellType { get }
    
    // MARK: - Required Methods
    
    /// Update the object's position based on its grid position
    /// This should convert grid coordinates to world coordinates
    func updatePosition()
    
    /// Update the object's grid position based on its world position
    /// This should convert world coordinates to grid coordinates
    func updateGridPosition()
    
    /// Initialize the object at a specific grid position
    /// - Parameter gridPosition: The initial grid position
    func initialize(at gridPosition: CGPoint)
    
    /// Remove the object from the scene and clean up resources
    func destroy()
    
    // MARK: - Optional Properties
    
    /// Whether this object can be moved by other systems
    var isMovable: Bool { get }
    
    /// Whether this object blocks movement of other objects
    var blocksMovement: Bool { get }
    
    /// Whether this object can be destroyed/removed
    var isDestructible: Bool { get }
    
    /// The z-position for rendering order
    var zPosition: CGFloat { get set }
    
    // MARK: - Optional Methods
    
    /// Called when the object is placed on the grid
    /// - Parameter gridPosition: The position where the object was placed
    func onPlaced(at gridPosition: CGPoint)
    
    /// Called when the object is removed from the grid
    func onRemoved()
    
    /// Called when the object moves to a new grid position
    /// - Parameters:
    ///   - from: The previous grid position
    ///   - to: The new grid position
    func onMoved(from: CGPoint, to: CGPoint)
    
    /// Update the object's visual state (called each frame)
    /// - Parameter deltaTime: Time since last update
    func update(deltaTime: TimeInterval)
}

// MARK: - Default Implementations

extension GameObject {
    
    // MARK: - Default Property Values
    
    /// Default implementation: most objects are movable
    var isMovable: Bool { return true }
    
    /// Default implementation: most objects don't block movement
    var blocksMovement: Bool { return false }
    
    /// Default implementation: most objects can be destroyed
    var isDestructible: Bool { return true }
    
    /// Default implementation: get z-position from sprite
    var zPosition: CGFloat {
        get { return sprite.zPosition }
        set { sprite.zPosition = newValue }
    }
    
    // MARK: - Default Method Implementations
    
    /// Default implementation: do nothing when placed
    func onPlaced(at gridPosition: CGPoint) {
        // Override in subclasses if needed
    }
    
    /// Default implementation: do nothing when removed
    func onRemoved() {
        // Override in subclasses if needed
    }
    
    /// Default implementation: do nothing when moved
    func onMoved(from: CGPoint, to: CGPoint) {
        // Override in subclasses if needed
    }
    
    /// Default implementation: do nothing during update
    func update(deltaTime: TimeInterval) {
        // Override in subclasses if needed
    }
    
    /// Default implementation: remove sprite from parent
    func destroy() {
        sprite.removeFromParent()
    }
}

// MARK: - GameObject Utilities

extension GameObject {
    
    /// Get the world position of this object
    var worldPosition: CGPoint {
        return sprite.position
    }
    
    /// Set the world position and update grid position accordingly
    /// - Parameter position: The new world position
    func setWorldPosition(_ position: CGPoint) {
        sprite.position = position
        updateGridPosition()
    }
    
    /// Check if this object is at the specified grid position
    /// - Parameter gridPosition: The grid position to check
    /// - Returns: True if the object is at the specified position
    func isAtGridPosition(_ gridPosition: CGPoint) -> Bool {
        return abs(self.gridPosition.x - gridPosition.x) < 0.1 && 
               abs(self.gridPosition.y - gridPosition.y) < 0.1
    }
    
    /// Get the distance to another game object in grid cells
    /// - Parameter other: The other game object
    /// - Returns: Manhattan distance in grid cells
    func gridDistance(to other: GameObject) -> CGFloat {
        return abs(gridPosition.x - other.gridPosition.x) + 
               abs(gridPosition.y - other.gridPosition.y)
    }
    
    /// Get the Euclidean distance to another game object in grid cells
    /// - Parameter other: The other game object
    /// - Returns: Euclidean distance in grid cells
    func euclideanGridDistance(to other: GameObject) -> CGFloat {
        let deltaX = gridPosition.x - other.gridPosition.x
        let deltaY = gridPosition.y - other.gridPosition.y
        return sqrt(deltaX * deltaX + deltaY * deltaY)
    }
    
    /// Check if this object can move to the specified grid position
    /// - Parameter gridPosition: The target grid position
    /// - Returns: True if the object can move to the position
    func canMoveTo(_ gridPosition: CGPoint) -> Bool {
        // Default implementation: can move anywhere
        // Override in subclasses for specific movement rules
        return isMovable
    }
    
    /// Move the object to the specified grid position
    /// - Parameter gridPosition: The target grid position
    /// - Returns: True if the move was successful
    @discardableResult
    func moveTo(_ gridPosition: CGPoint) -> Bool {
        guard canMoveTo(gridPosition) else { return false }
        
        let oldPosition = self.gridPosition
        self.gridPosition = gridPosition
        updatePosition()
        onMoved(from: oldPosition, to: gridPosition)
        
        return true
    }
}

// MARK: - GameObject Factory

/// Factory for creating game objects
protocol GameObjectFactory {
    
    /// Create a new game object of the specified type
    /// - Parameter type: The type of game object to create
    /// - Returns: A new game object instance
    func createGameObject(of type: GridCellType) -> GameObject?
    
    /// Create a game object at a specific grid position
    /// - Parameters:
    ///   - type: The type of game object to create
    ///   - gridPosition: The initial grid position
    /// - Returns: A new game object instance, or nil if creation failed
    func createGameObject(of type: GridCellType, at gridPosition: CGPoint) -> GameObject?
}
