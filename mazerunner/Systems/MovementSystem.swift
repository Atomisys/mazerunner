import SpriteKit

/// System responsible for handling all movement logic in the game
/// Manages player movement, enemy AI movement, and collision detection
final class MovementSystem {
    
    // MARK: - Properties
    
    private let gridSystem: GridSystem
    private let gameGrid: GameGrid
    private let gameStateManager: GameStateManager
    
    // MARK: - Movement State
    
    /// Current movement direction for the player
    private var currentPlayerDirection: Direction?
    
    /// Whether the player is currently moving
    private var isPlayerMoving: Bool = false
    
    /// Movement speed for different object types
    private let playerMovementSpeed: CGFloat = 2.0
    private let enemyMovementSpeed: CGFloat = 1.5
    
    /// Movement timer for continuous movement
    private var movementTimer: Timer?
    
    // MARK: - Initialization
    
    init(gridSystem: GridSystem, gameGrid: GameGrid, gameStateManager: GameStateManager) {
        self.gridSystem = gridSystem
        self.gameGrid = gameGrid
        self.gameStateManager = gameStateManager
    }
    
    // MARK: - Player Movement
    
    /// Start player movement in the specified direction
    /// - Parameter direction: The direction to move
    func startPlayerMovement(in direction: Direction) {
        guard !isPlayerMoving else { return }
        
        currentPlayerDirection = direction
        isPlayerMoving = true
        
        // Start continuous movement timer
        startMovementTimer()
    }
    
    /// Stop player movement
    func stopPlayerMovement() {
        isPlayerMoving = false
        currentPlayerDirection = nil
        stopMovementTimer()
    }
    
    /// Move player in the current direction
    func movePlayer() {
        guard isPlayerMoving, let player = getCurrentPlayer(), let direction = currentPlayerDirection else { return }
        
        let targetGridPosition = getTargetGridPosition(from: player.gridPosition, direction: direction)
        
        // Check if movement is valid
        guard canMoveTo(targetGridPosition) else {
            // Try to find an alternative direction or stop
            handleMovementBlocked()
            return
        }
        
        // Perform the movement
        performPlayerMovement(to: targetGridPosition)
    }
    
    /// Get the target grid position for a given direction
    /// - Parameters:
    ///   - currentPosition: Current grid position
    ///   - direction: Direction to move
    /// - Returns: Target grid position
    private func getTargetGridPosition(from currentPosition: CGPoint, direction: Direction) -> CGPoint {
        switch direction {
        case .up:
            return CGPoint(x: currentPosition.x, y: currentPosition.y + 1)
        case .down:
            return CGPoint(x: currentPosition.x, y: currentPosition.y - 1)
        case .left:
            return CGPoint(x: currentPosition.x - 1, y: currentPosition.y)
        case .right:
            return CGPoint(x: currentPosition.x + 1, y: currentPosition.y)
        // No zero case needed since we use optional Direction
        }
    }
    
    /// Check if an object can move to the specified grid position
    /// - Parameter gridPosition: Target grid position
    /// - Returns: True if movement is allowed
    private func canMoveTo(_ gridPosition: CGPoint) -> Bool {
        // Check if position is within grid bounds
        guard gridSystem.isValidGridPosition(gridPosition) else { return false }
        
        // Check if position is empty or contains a collectible
        let cellType = gameGrid.getCellType(at: gridPosition)
        return cellType == .empty || cellType == .cherry || cellType == .dugTunnel
    }
    
    /// Handle when player movement is blocked
    private func handleMovementBlocked() {
        // Stop movement if blocked
        stopPlayerMovement()
    }
    
    /// Perform the actual player movement
    /// - Parameter targetPosition: Target grid position
    private func performPlayerMovement(to targetPosition: CGPoint) {
        guard let player = getCurrentPlayer() else { return }
        
        let oldPosition = player.gridPosition
        
        // Update player's grid position
        player.gridPosition = targetPosition
        
        // Update player's world position
        let worldPosition = gridSystem.getWorldPosition(targetPosition)
        player.sprite.position = worldPosition
        
        // Handle grid updates
        updateGridForPlayerMovement(from: oldPosition, to: targetPosition)
        
        // Check for interactions at new position
        handlePlayerPositionInteractions(at: targetPosition)
    }
    
    /// Update the grid when player moves
    /// - Parameters:
    ///   - from: Previous grid position
    ///   - to: New grid position
    private func updateGridForPlayerMovement(from: CGPoint, to: CGPoint) {
        // Clear old position
        gameGrid.setCellType(at: from, to: .empty)
        
        // Set new position
        gameGrid.setCellType(at: to, to: .player)
    }
    
    /// Handle interactions when player moves to a new position
    /// - Parameter position: New grid position
    private func handlePlayerPositionInteractions(at position: CGPoint) {
        let cellType = gameGrid.getCellType(at: position)
        
        switch cellType {
        case .cherry:
            collectCherry(at: position)
        case .dugTunnel:
            // Player can move through dug tunnels
            break
        default:
            break
        }
    }
    
    /// Collect cherry at the specified position
    /// - Parameter position: Grid position of the cherry
    private func collectCherry(at position: CGPoint) {
        // This will be handled by the Cherry object's collect method
        // The MovementSystem just detects the interaction
    }
    
    // MARK: - Enemy Movement
    
    /// Move all enemies using AI
    func moveEnemies() {
        let enemies = getAllEnemies()
        
        for enemy in enemies {
            moveEnemy(enemy)
        }
    }
    
    /// Move a single enemy using AI
    /// - Parameter enemy: The enemy to move
    private func moveEnemy(_ enemy: Enemy) {
        guard let player = getCurrentPlayer() else { return }
        
        // Get AI direction
        let direction = enemy.findBestDirection(to: player.gridPosition, gameGrid: gameGrid)
        
        guard let aiDirection = direction else { return }
        
        let targetGridPosition = getTargetGridPosition(from: enemy.gridPosition, direction: aiDirection)
        
        // Check if movement is valid
        guard canEnemyMoveTo(targetGridPosition) else { return }
        
        // Perform enemy movement
        performEnemyMovement(enemy, to: targetGridPosition)
    }
    
    /// Check if an enemy can move to the specified position
    /// - Parameter gridPosition: Target grid position
    /// - Returns: True if movement is allowed
    private func canEnemyMoveTo(_ gridPosition: CGPoint) -> Bool {
        // Check if position is within grid bounds
        guard gridSystem.isValidGridPosition(gridPosition) else { return false }
        
        // Check if position is empty or contains a dug tunnel
        let cellType = gameGrid.getCellType(at: gridPosition)
        return cellType == .empty || cellType == .dugTunnel
    }
    
    /// Perform enemy movement
    /// - Parameters:
    ///   - enemy: The enemy to move
    ///   - targetPosition: Target grid position
    private func performEnemyMovement(_ enemy: Enemy, to targetPosition: CGPoint) {
        let oldPosition = enemy.gridPosition
        
        // Update enemy's grid position
        enemy.gridPosition = targetPosition
        
        // Update enemy's world position
        let worldPosition = gridSystem.getWorldPosition(targetPosition)
        enemy.sprite.position = worldPosition
        
        // Update grid
        updateGridForEnemyMovement(enemy, from: oldPosition, to: targetPosition)
        
        // Check for collision with player
        checkEnemyPlayerCollision(enemy, at: targetPosition)
    }
    
    /// Update the grid when enemy moves
    /// - Parameters:
    ///   - enemy: The enemy that moved
    ///   - from: Previous grid position
    ///   - to: New grid position
    private func updateGridForEnemyMovement(_ enemy: Enemy, from: CGPoint, to: CGPoint) {
        // Clear old position
        gameGrid.setCellType(at: from, to: .empty)
        
        // Set new position
        gameGrid.setCellType(at: to, to: .enemy)
    }
    
    /// Check for collision between enemy and player
    /// - Parameters:
    ///   - enemy: The enemy to check
    ///   - position: Enemy's current position
    private func checkEnemyPlayerCollision(_ enemy: Enemy, at position: CGPoint) {
        guard let player = getCurrentPlayer() else { return }
        
        if position == player.gridPosition {
            handleEnemyPlayerCollision(enemy, player)
        }
    }
    
    /// Handle collision between enemy and player
    /// - Parameters:
    ///   - enemy: The enemy involved in collision
    ///   - player: The player involved in collision
    private func handleEnemyPlayerCollision(_ enemy: Enemy, _ player: Player) {
        // Player loses a life
        _ = gameStateManager.loseLife()
        
        // Reset player to spawn position
        resetPlayerToSpawn()
        
        // Reset enemies to their spawn positions
        resetEnemiesToSpawn()
    }
    
    // MARK: - Movement Timer
    
    /// Start the movement timer for continuous movement
    private func startMovementTimer() {
        stopMovementTimer()
        
        let interval = 1.0 / playerMovementSpeed
        movementTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.movePlayer()
        }
    }
    
    /// Stop the movement timer
    private func stopMovementTimer() {
        movementTimer?.invalidate()
        movementTimer = nil
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
    
    // MARK: - Helper Methods
    
    /// Get the current player
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
    
    // MARK: - Public Interface
    
    /// Update the movement system (called each frame)
    /// - Parameter deltaTime: Time since last update
    func update(deltaTime: TimeInterval) {
        // Move enemies periodically
        // This could be based on a timer or frame counter
    }
    
    /// Handle input for player movement
    /// - Parameter direction: Direction from input
    func handlePlayerInput(direction: Direction?) {
        if let direction = direction {
            startPlayerMovement(in: direction)
        } else {
            stopPlayerMovement()
        }
    }
    
    /// Pause movement system
    func pause() {
        stopPlayerMovement()
    }
    
    /// Resume movement system
    func resume() {
        // Resume any paused movement
    }
    
    /// Clean up resources
    func cleanup() {
        stopMovementTimer()
    }
}
