import SpriteKit

final class GameManager {
    
    // MARK: - Properties
    
    /// The grid system for position conversions and grid operations
    private let gridSystem: GridSystem
    
    /// The game grid for tracking object positions
    private let gameGrid: GameGrid
    
    /// The game state manager for score, lives, and game state
    private let gameStateManager: GameStateManager
    
    /// The movement system for handling player and enemy movement
    private var movementSystem: MovementSystem?
    
    /// The current player
    private var player: Player?
    
    /// All enemies in the game
    private var enemies: [Enemy] = []
    
    /// All cherries in the game
    private var cherries: [Cherry] = []
    
    /// All walls in the game
    private var walls: [Wall] = []
    
    /// All border walls in the game
    private var borderWalls: [Wall] = []
    
    /// The scene where the game is being played
    private weak var scene: SKScene?
    
    /// Whether the game is currently active
    private var isGameActive: Bool = false
    
    // MARK: - Initialization
    
    init(scene: SKScene, gridSystem: GridSystem, gameStateManager: GameStateManager) {
        self.scene = scene
        self.gridSystem = gridSystem
        self.gameStateManager = gameStateManager
        self.gameGrid = GameGrid(gridSystem: gridSystem)
        
        // Initialize movement system
        self.movementSystem = MovementSystem(gridSystem: gridSystem, gameGrid: gameGrid, gameStateManager: gameStateManager, gameManager: self)
    }
    
    // MARK: - Game Lifecycle Management
    
    /// Start a new game
    func startNewGame() {
        print("GameManager: Starting new game")
        
        // Reset game state
        gameStateManager.resetToNewGame()
        
        // Clear all objects
        clearAllObjects()
        
        // Create the maze
        createMaze()
        
        // Spawn game objects
        spawnPlayer()
        spawnEnemies()
        spawnCherries()
        
        // Start movement system
        movementSystem?.startMovementSystem()
        
        // Set game as active
        isGameActive = true
        
        print("GameManager: New game started successfully")
    }
    
    /// Start a new level
    func startNewLevel() {
        print("GameManager: Starting level \(gameStateManager.levelNumber)")
        
        // Reset level state
        gameStateManager.startNewLevel()
        
        // Clear level objects (keep player and enemies)
        clearLevelObjects()
        
        // Recreate maze
        createMaze()
        
        // Respawn cherries
        spawnCherries()
        
        // Reset player and enemies to spawn positions
        resetPlayerAndEnemies()
        
        // Start movement system
        movementSystem?.startMovementSystem()
        
        // Set game as active
        isGameActive = true
        
        print("GameManager: Level \(gameStateManager.levelNumber) started successfully")
    }
    
    /// Pause the game
    func pauseGame() {
        guard isGameActive else { return }
        
        print("GameManager: Pausing game")
        gameStateManager.changeState(to: .paused)
        isGameActive = false
        
        // Stop all movement
        movementSystem?.pause()
    }
    
    /// Resume the game
    func resumeGame() {
        guard gameStateManager.currentState == .paused else { return }
        
        print("GameManager: Resuming game")
        gameStateManager.changeState(to: .playing)
        isGameActive = true
        
        // Resume movement system
        movementSystem?.resume()
    }
    
    /// End the game
    func endGame() {
        print("GameManager: Ending game")
        gameStateManager.changeState(to: .gameOver)
        isGameActive = false
        
        // Stop all movement
        movementSystem?.stopMovementSystem()
    }
    
    /// Restart the current level
    func restartLevel() {
        print("GameManager: Restarting level")
        
        // Reset level state
        gameStateManager.resetLevel()
        
        // Clear level objects
        clearLevelObjects()
        
        // Recreate maze
        createMaze()
        
        // Respawn cherries
        spawnCherries()
        
        // Reset player and enemies
        resetPlayerAndEnemies()
        
        // Set game as active
        isGameActive = true
        
        print("GameManager: Level restarted successfully")
    }
    
    // MARK: - Object Management
    
    /// Create and spawn the player
    private func spawnPlayer() {
        let playerGridPos = CGPoint(x: 6, y: 25) // Bottom center spawn
        player = Player(gridSystem: gridSystem, gameStateManager: gameStateManager)
        player?.initialize(at: playerGridPos)
        
        // Add to scene
        scene?.addChild(player?.sprite ?? SKSpriteNode())
        
        // Add to game grid
        gameGrid.placeObject(at: playerGridPos, type: .player, object: player)
        
        print("GameManager: Player spawned at \(playerGridPos)")
    }
    
    /// Create and spawn enemies
    private func spawnEnemies() {
        let enemyCount = 3
        let enemyColors = [
            SKColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0), // Red
            SKColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0), // Blue
            SKColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0)  // Magenta
        ]
        
        let enemyGridPositions = [
            CGPoint(x: 2, y: 2),      // Left side
            CGPoint(x: 6, y: 2),      // Center
            CGPoint(x: 9, y: 2)       // Right side
        ]
        
        enemies.removeAll()
        
        for i in 0..<enemyCount {
            let enemySprite = createEnemySprite(color: enemyColors[i], gridSize: gridSystem.cellSize)
            let enemy = Enemy(sprite: enemySprite, color: enemyColors[i], gridSystem: gridSystem, initialGridPosition: enemyGridPositions[i])
            
            // Build directional sprites
            enemy.directionalSprites = buildDirectionalEnemySprites(baseColor: enemyColors[i], gridSize: gridSystem.cellSize)
            
            enemies.append(enemy)
            
            // Add to scene
            scene?.addChild(enemy.sprite)
            
            // Add to game grid
            gameGrid.placeObject(at: enemyGridPositions[i], type: .enemy, object: enemy)
            
            print("GameManager: Enemy \(i) spawned at \(enemyGridPositions[i])")
        }
    }
    
    /// Create and spawn cherries
    private func spawnCherries() {
        let cherriesRequired = gameStateManager.cherryProgress.required
        
        cherries.removeAll()
        
        for _ in 0..<cherriesRequired {
            // Find a valid position for the cherry (inside diggable walls)
            guard let cherryPos = findValidCherryPosition() else { continue }
            
            let cherry = Cherry(gridSystem: gridSystem, gameStateManager: gameStateManager, gridPosition: cherryPos)
            cherries.append(cherry)
            
            // Add to scene
            scene?.addChild(cherry.sprite)
            
            // Add to game grid
            gameGrid.placeObject(at: cherryPos, type: .cherry, object: cherry)
            
            print("GameManager: Cherry spawned at \(cherryPos)")
        }
    }
    
    /// Create the maze with walls
    private func createMaze() {
        // Clear existing walls
        walls.removeAll()
        borderWalls.removeAll()
        
        // Create border walls
        createBorderWalls()
        
        // Create internal maze walls
        createInternalWalls()
        
        print("GameManager: Maze created with \(walls.count) regular walls and \(borderWalls.count) border walls")
    }
    
    /// Create border walls around the game area
    private func createBorderWalls() {
        let gridWidth = gridSystem.width
        let gridHeight = gridSystem.height
        
        // Top border (row 1)
        for x in 0..<gridWidth {
            createBorderWall(at: CGPoint(x: CGFloat(x), y: 1))
        }
        
        // Bottom border (row 26)
        for x in 0..<gridWidth {
            createBorderWall(at: CGPoint(x: CGFloat(x), y: 26))
        }
        
        // Left border (column 0) - exclude row 0 for dynamic island
        for y in 1..<gridHeight {
            createBorderWall(at: CGPoint(x: 0, y: CGFloat(y)))
        }
        
        // Right border (column 11) - exclude row 0 for dynamic island
        for y in 1..<gridHeight {
            createBorderWall(at: CGPoint(x: 11, y: CGFloat(y)))
        }
    }
    
    /// Create internal maze walls using the Maze generator
    private func createInternalWalls() {
        // Generate maze using the legacy Maze class
        // The maze generator returns a 2D array where true = wall, false = open path
        // Dimensions: cols = 10 (game columns 1..10), rows = 22 (mapped to world rows 3..24)
        let mazeData = Maze.generate(cols: 10, rows: 22)
        
        // Convert maze data to walls
        // Note: mazeData[row][col] where row 0 = world row 3, col 0 = world col 1
        for row in 0..<mazeData.count {
            for col in 0..<mazeData[row].count {
                let isWall = mazeData[row][col]
                
                if isWall {
                    // Convert maze coordinates to world coordinates
                    let worldRow = row + 3  // maze row 0 = world row 3
                    let worldCol = col + 1  // maze col 0 = world col 1
                    
                    // Skip if out of bounds
                    guard worldRow >= 2 && worldRow <= 25 && worldCol >= 1 && worldCol <= 10 else { continue }
                    
                    // Skip player spawn area
                    if worldCol == 6 && worldRow == 25 { continue }
                    
                    // Skip enemy spawn areas
                    if worldRow == 2 && (worldCol == 2 || worldCol == 6 || worldCol == 9) { continue }
                    
                    // Create wall at this position
                    let gridPosition = CGPoint(x: CGFloat(worldCol), y: CGFloat(worldRow))
                    createRegularWall(at: gridPosition)
                }
            }
        }
        
        print("GameManager: Generated maze with \(walls.count) internal walls")
    }
    
    /// Create a border wall at the specified grid position
    private func createBorderWall(at gridPosition: CGPoint) {
        let wall = Wall(wallType: .border, gridSystem: gridSystem, gameStateManager: gameStateManager, gridPosition: gridPosition, movementSystem: movementSystem)
        borderWalls.append(wall)
        
        // Add to scene
        scene?.addChild(wall.sprite)
        
        // Add to game grid
        gameGrid.placeObject(at: gridPosition, type: .borderWall, object: wall)
    }
    
    /// Create a regular wall at the specified grid position
    private func createRegularWall(at gridPosition: CGPoint) {
        let wall = Wall(wallType: .regular, gridSystem: gridSystem, gameStateManager: gameStateManager, gridPosition: gridPosition, movementSystem: movementSystem)
        walls.append(wall)
        
        // Add to scene
        scene?.addChild(wall.sprite)
        
        // Add to game grid
        gameGrid.placeObject(at: gridPosition, type: .wall, object: wall)
    }
    
    // MARK: - Helper Methods
    
    /// Find a valid position for a cherry (inside diggable walls)
    private func findValidCherryPosition() -> CGPoint? {
        var attempts = 0
        let maxAttempts = 100
        
        while attempts < maxAttempts {
            let gridX = Int.random(in: 1...10)
            let gridY = Int.random(in: 2...25)
            let position = CGPoint(x: CGFloat(gridX), y: CGFloat(gridY))
            
            // Check if position has a diggable wall and no cherry
            if gameGrid.isDiggableWall(at: position) && !gameGrid.isCherry(at: position) {
                return position
            }
            
            attempts += 1
        }
        
        return nil
    }
    
    /// Reset player and enemies to their spawn positions
    private func resetPlayerAndEnemies() {
        // Reset player
        player?.resetToSpawn()
        
        // Reset enemies
        let enemyGridPositions = [
            CGPoint(x: 2, y: 2),      // Left side
            CGPoint(x: 6, y: 2),      // Center
            CGPoint(x: 9, y: 2)       // Right side
        ]
        
        for (index, enemy) in enemies.enumerated() {
            if index < enemyGridPositions.count {
                enemy.resetToPosition(enemyGridPositions[index])
            }
        }
    }
    
    /// Clear all game objects
    private func clearAllObjects() {
        clearLevelObjects()
        
        // Remove player
        player?.destroy()
        player = nil
        
        // Remove enemies
        enemies.forEach { $0.destroy() }
        enemies.removeAll()
    }
    
    /// Clear level-specific objects (cherries, walls)
    private func clearLevelObjects() {
        // Remove cherries
        cherries.forEach { $0.destroy() }
        cherries.removeAll()
        
        // Remove walls
        walls.forEach { $0.destroy() }
        walls.removeAll()
        
        // Remove border walls
        borderWalls.forEach { $0.destroy() }
        borderWalls.removeAll()
        
        // Clear game grid
        gameGrid.clear()
    }
    
    // MARK: - Object Creation Helpers
    
    /// Create an enemy sprite
    private func createEnemySprite(color: SKColor, gridSize: CGFloat) -> SKSpriteNode {
        let enemySize = CGSize(width: gridSize * 0.8, height: gridSize * 0.8)
        let enemy = SKSpriteNode(color: color, size: enemySize)
        enemy.zPosition = 2
        enemy.name = "enemy"
        
        // Add enemy details (eyes)
        let eye1 = SKShapeNode(circleOfRadius: 2)
        eye1.fillColor = .white
        eye1.position = CGPoint(x: -6, y: 4)
        enemy.addChild(eye1)
        
        let eye2 = SKShapeNode(circleOfRadius: 2)
        eye2.fillColor = .white
        eye2.position = CGPoint(x: 6, y: 4)
        enemy.addChild(eye2)
        
        // Add pupils
        let pupilLeft = SKShapeNode(circleOfRadius: 1)
        pupilLeft.fillColor = .black
        pupilLeft.position = CGPoint(x: -6, y: 4)
        enemy.addChild(pupilLeft)
        
        let pupilRight = SKShapeNode(circleOfRadius: 1)
        pupilRight.fillColor = .black
        pupilRight.position = CGPoint(x: 6, y: 4)
        enemy.addChild(pupilRight)
        
        return enemy
    }
    
    /// Build directional enemy sprites
    private func buildDirectionalEnemySprites(baseColor: SKColor, gridSize: CGFloat) -> [SKSpriteNode] {
        let offsets: [CGPoint] = [CGPoint(x: 0, y: 2), CGPoint(x: 0, y: -2), CGPoint(x: -2, y: 0), CGPoint(x: 2, y: 0)]
        var sprites: [SKSpriteNode] = []
        
        for delta in offsets {
            let sprite = createEnemySprite(color: baseColor, gridSize: gridSize)
            
            // Update pupil positions based on direction
            if let pupilLeft = sprite.childNode(withName: "pupilLeft") as? SKShapeNode {
                pupilLeft.position = CGPoint(x: -6 + delta.x, y: 4 + delta.y)
            }
            if let pupilRight = sprite.childNode(withName: "pupilRight") as? SKShapeNode {
                pupilRight.position = CGPoint(x: 6 + delta.x, y: 4 + delta.y)
            }
            
            sprites.append(sprite)
        }
        
        return sprites
    }
    
    // MARK: - Public Access Methods
    
    /// Get the current player
    var currentPlayer: Player? {
        return player
    }
    
    /// Get all enemies
    var allEnemies: [Enemy] {
        return enemies
    }
    
    /// Get all cherries
    var allCherries: [Cherry] {
        return cherries
    }
    
    /// Get all walls
    var allWalls: [Wall] {
        return walls
    }
    
    /// Get all border walls
    var allBorderWalls: [Wall] {
        return borderWalls
    }
    
    /// Get the game grid
    var grid: GameGrid {
        return gameGrid
    }
    
    /// Get the grid system
    var gridSystemAccess: GridSystem {
        return gridSystem
    }
    
    /// Get the movement system
    var movementSystemAccess: MovementSystem? {
        return movementSystem
    }
    
    /// Get the game state manager
    var stateManager: GameStateManager {
        return gameStateManager
    }
    
    /// Check if the game is active
    var active: Bool {
        return isGameActive
    }
    
    /// Get the current scene
    var currentScene: SKScene? {
        return scene
    }
}
