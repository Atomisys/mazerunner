import SpriteKit

/// System responsible for handling all collision detection and response in the game
/// Manages grid-based collisions, object interactions, and collision responses
final class CollisionSystem {
    
    // MARK: - Properties
    
    private let gridSystem: GridSystem
    private let gameGrid: GameGrid
    private let gameStateManager: GameStateManager
    
    // MARK: - Collision Types
    
    /// Types of collisions that can occur
    enum CollisionType {
        case playerWithEnemy
        case playerWithCherry
        case playerWithWall
        case enemyWithWall
        case enemyWithEnemy
    }
    
    /// Collision response actions
    enum CollisionResponse {
        case none
        case stopMovement
        case collectItem
        case loseLife
        case destroyObject
        case bounceBack
    }
    
    // MARK: - Initialization
    
    init(gridSystem: GridSystem, gameGrid: GameGrid, gameStateManager: GameStateManager) {
        self.gridSystem = gridSystem
        self.gameGrid = gameGrid
        self.gameStateManager = gameStateManager
    }
    
    // MARK: - Main Collision Detection
    
    /// Check for all collisions in the game
    func checkAllCollisions() {
        checkPlayerCollisions()
        checkEnemyCollisions()
    }
    
    /// Check collisions involving the player
    private func checkPlayerCollisions() {
        guard let player = getCurrentPlayer() else { return }
        
        let playerPosition = player.gridPosition
        
        // Check what's at the player's position
        let cellType = gameGrid.getCellType(at: playerPosition)
        
        switch cellType {
        case .enemy:
            handlePlayerEnemyCollision(player: player)
        case .cherry:
            handlePlayerCherryCollision(player: player, at: playerPosition)
        case .wall, .borderWall:
            handlePlayerWallCollision(player: player, at: playerPosition)
        default:
            break
        }
    }
    
    /// Check collisions involving enemies
    private func checkEnemyCollisions() {
        let enemies = getAllEnemies()
        
        for enemy in enemies {
            let enemyPosition = enemy.gridPosition
            
            // Check what's at the enemy's position
            let cellType = gameGrid.getCellType(at: enemyPosition)
            
            switch cellType {
            case .player:
                handleEnemyPlayerCollision(enemy: enemy)
            case .wall, .borderWall:
                handleEnemyWallCollision(enemy: enemy, at: enemyPosition)
            case .enemy:
                handleEnemyEnemyCollision(enemy: enemy, at: enemyPosition)
            default:
                break
            }
        }
    }
    
    // MARK: - Player Collision Handlers
    
    /// Handle collision between player and enemy
    /// - Parameter player: The player involved in collision
    private func handlePlayerEnemyCollision(player: Player) {
        // Player loses a life
        _ = gameStateManager.loseLife()
        
        // Trigger player hit effect
        player.onHit()
        
        // Reset player to spawn position
        resetPlayerToSpawn()
        
        // Reset enemies to spawn positions
        resetEnemiesToSpawn()
        
        // Play collision sound effect
        playCollisionSound(.playerWithEnemy)
    }
    
    /// Handle collision between player and cherry
    /// - Parameters:
    ///   - player: The player involved in collision
    ///   - position: Position of the cherry
    private func handlePlayerCherryCollision(player: Player, at position: CGPoint) {
        // Find the cherry object at this position
        guard let cherry = getCherryAt(position) else { return }
        
        // Check if the cherry can be collected
        guard cherry.canBeCollected(by: player.sprite.position) else { return }
        
        // Collect the cherry
        cherry.collect()
        
        // Update game state
        _ = gameStateManager.collectCherry()
        
        // Update grid
        gameGrid.setCellType(at: position, to: .empty)
        
        // Play collection sound effect
        playCollisionSound(.playerWithCherry)
    }
    
    /// Handle collision between player and wall
    /// - Parameters:
    ///   - player: The player involved in collision
    ///   - position: Position of the wall
    private func handlePlayerWallCollision(player: Player, at position: CGPoint) {
        // Check if the wall can be dug
        guard let wall = getWallAt(position) else { return }
        
        if wall.canBeDug {
            // Player can dig through this wall
            wall.dig()
            
            // Update grid to dug tunnel
            gameGrid.setCellType(at: position, to: .dugTunnel)
            
            // Play digging sound effect
            playCollisionSound(.playerWithWall)
        } else {
            // Wall cannot be dug - movement should be blocked
            // This is handled by the MovementSystem
        }
    }
    
    // MARK: - Enemy Collision Handlers
    
    /// Handle collision between enemy and player
    /// - Parameter enemy: The enemy involved in collision
    private func handleEnemyPlayerCollision(enemy: Enemy) {
        // This is the same as player-enemy collision
        // The collision is detected from the enemy's perspective
        guard let player = getCurrentPlayer() else { return }
        
        handlePlayerEnemyCollision(player: player)
    }
    
    /// Handle collision between enemy and wall
    /// - Parameters:
    ///   - enemy: The enemy involved in collision
    ///   - position: Position of the wall
    private func handleEnemyWallCollision(enemy: Enemy, at position: CGPoint) {
        // Enemies cannot dig walls, so they should be blocked
        // This is handled by the MovementSystem
        // The enemy should find an alternative path
    }
    
    /// Handle collision between enemy and another enemy
    /// - Parameters:
    ///   - enemy: The enemy involved in collision
    ///   - position: Position of the collision
    private func handleEnemyEnemyCollision(enemy: Enemy, at position: CGPoint) {
        // Enemies should avoid each other
        // This is handled by the MovementSystem's pathfinding
        // The enemy should find an alternative path
    }
    
    // MARK: - Grid-Based Collision Detection
    
    /// Check if a position is valid for movement
    /// - Parameter position: Grid position to check
    /// - Returns: True if the position is valid for movement
    func isValidMovementPosition(_ position: CGPoint) -> Bool {
        // Check if position is within grid bounds
        guard gridSystem.isValidGridPosition(position) else { return false }
        
        // Check what's at the position
        let cellType = gameGrid.getCellType(at: position)
        
        // Valid positions for movement
        return cellType == .empty || cellType == .cherry || cellType == .dugTunnel
    }
    
    /// Check if a position is valid for enemy movement
    /// - Parameter position: Grid position to check
    /// - Returns: True if the position is valid for enemy movement
    func isValidEnemyMovementPosition(_ position: CGPoint) -> Bool {
        // Check if position is within grid bounds
        guard gridSystem.isValidGridPosition(position) else { return false }
        
        // Check what's at the position
        let cellType = gameGrid.getCellType(at: position)
        
        // Valid positions for enemy movement (enemies can't collect cherries)
        return cellType == .empty || cellType == .dugTunnel
    }
    
    /// Check if there's a collision at a specific position
    /// - Parameter position: Grid position to check
    /// - Returns: Type of collision, or nil if no collision
    func getCollisionType(at position: CGPoint) -> CollisionType? {
        guard gridSystem.isValidGridPosition(position) else { return nil }
        
        let cellType = gameGrid.getCellType(at: position)
        
        switch cellType {
        case .wall, .borderWall:
            return .playerWithWall
        case .enemy:
            return .playerWithEnemy
        case .cherry:
            return .playerWithCherry
        default:
            return nil
        }
    }
    
    // MARK: - Object Retrieval
    
    /// Get the player at the current position
    /// - Returns: Current player instance, or nil if not found
    private func getCurrentPlayer() -> Player? {
        // This would be provided by the GameManager
        // For now, we'll need to implement this based on how we access the player
        return nil // TODO: Implement based on GameManager access
    }
    
    /// Get all enemies
    /// - Returns: Array of all enemy instances
    private func getAllEnemies() -> [Enemy] {
        // This would be provided by the GameManager
        // For now, we'll need to implement this based on how we access enemies
        return [] // TODO: Implement based on GameManager access
    }
    
    /// Get cherry at a specific position
    /// - Parameter position: Grid position to check
    /// - Returns: Cherry object at the position, or nil if not found
    private func getCherryAt(_ position: CGPoint) -> Cherry? {
        // This would be provided by the GameManager
        // For now, we'll need to implement this based on how we access cherries
        return nil // TODO: Implement based on GameManager access
    }
    
    /// Get wall at a specific position
    /// - Parameter position: Grid position to check
    /// - Returns: Wall object at the position, or nil if not found
    private func getWallAt(_ position: CGPoint) -> Wall? {
        // This would be provided by the GameManager
        // For now, we'll need to implement this based on how we access walls
        return nil // TODO: Implement based on GameManager access
    }
    
    // MARK: - Reset Functions
    
    /// Reset player to spawn position
    private func resetPlayerToSpawn() {
        guard let player = getCurrentPlayer() else { return }
        
        let spawnPosition = CGPoint(x: 6, y: 25) // Default spawn position
        player.gridPosition = spawnPosition
        
        let worldPosition = gridSystem.getWorldPosition(spawnPosition)
        player.sprite.position = worldPosition
        
        // Update grid
        gameGrid.setCellType(at: spawnPosition, to: .player)
    }
    
    /// Reset all enemies to their spawn positions
    private func resetEnemiesToSpawn() {
        let enemies = getAllEnemies()
        
        for enemy in enemies {
            // Reset to a random valid position
            let spawnPosition = getRandomSpawnPosition()
            enemy.gridPosition = spawnPosition
            
            let worldPosition = gridSystem.getWorldPosition(spawnPosition)
            enemy.sprite.position = worldPosition
            
            // Update grid
            gameGrid.setCellType(at: spawnPosition, to: .enemy)
        }
    }
    
    /// Get a random spawn position for enemies
    /// - Returns: Random valid grid position
    private func getRandomSpawnPosition() -> CGPoint {
        // Simple random spawn - in a real implementation, you'd have predefined spawn points
        let x = Int.random(in: 1..<gridSystem.width - 1)
        let y = Int.random(in: 1..<gridSystem.height - 1)
        return CGPoint(x: x, y: y)
    }
    
    // MARK: - Sound Effects
    
    /// Play collision sound effect
    /// - Parameter collisionType: Type of collision that occurred
    private func playCollisionSound(_ collisionType: CollisionType) {
        // This will be handled by the AudioSystem
        // For now, we'll just log the collision type
        print("Collision sound: \(collisionType)")
    }
    
    // MARK: - Public Interface
    
    /// Update the collision system (called each frame)
    /// - Parameter deltaTime: Time since last update
    func update(deltaTime: TimeInterval) {
        // Check for collisions each frame
        checkAllCollisions()
    }
    
    /// Check if a specific collision would occur
    /// - Parameters:
    ///   - objectType: Type of object moving
    ///   - fromPosition: Starting position
    ///   - toPosition: Target position
    /// - Returns: Type of collision that would occur, or nil if no collision
    func checkCollision(objectType: GridCellType, from fromPosition: CGPoint, to toPosition: CGPoint) -> CollisionType? {
        return getCollisionType(at: toPosition)
    }
    
    /// Get the appropriate response for a collision type
    /// - Parameter collisionType: Type of collision
    /// - Returns: Appropriate response action
    func getCollisionResponse(for collisionType: CollisionType) -> CollisionResponse {
        switch collisionType {
        case .playerWithEnemy:
            return .loseLife
        case .playerWithCherry:
            return .collectItem
        case .playerWithWall:
            return .stopMovement
        case .enemyWithWall:
            return .stopMovement
        case .enemyWithEnemy:
            return .stopMovement
        }
    }
    
    /// Pause collision system
    func pause() {
        // Pause collision detection if needed
    }
    
    /// Resume collision system
    func resume() {
        // Resume collision detection
    }
    
    /// Clean up resources
    func cleanup() {
        // Clean up any resources
    }
}
