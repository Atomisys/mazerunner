import Foundation

// MARK: - Game State Enum
enum GameState: String, CaseIterable {
    case playing = "playing"
    case paused = "paused"
    case gameOver = "gameOver"
    case levelComplete = "levelComplete"
}

// MARK: - Game State Manager
final class GameStateManager {
    
    // MARK: - Properties
    
    /// Current game state
    private(set) var currentState: GameState = .playing
    
    /// Game score
    private(set) var score: Int = 0
    
    /// Player lives remaining
    private(set) var lives: Int = 3
    
    /// Cherries collected in current level
    private(set) var cherriesCollected: Int = 0
    
    /// Cherries required to complete the level
    private(set) var cherriesRequired: Int = 10
    
    /// Current level number
    private(set) var currentLevel: Int = 1
    
    /// Enemy speed multiplier (starts at 0.5, increases with levels)
    private(set) var enemySpeedMultiplier: CGFloat = 0.5
    
    /// Base player speed
    private(set) var basePlayerSpeed: CGFloat = 150
    
    /// Current player speed (can be modified by power-ups, digging, etc.)
    private(set) var currentPlayerSpeed: CGFloat = 150
    
    /// Set of dug tunnel positions
    private(set) var dugTunnels: Set<CGPoint> = []
    
    // MARK: - Initialization
    
    init() {
        resetToNewGame()
    }
    
    // MARK: - Game State Management
    
    /// Change the current game state
    /// - Parameter newState: The new game state
    func changeState(to newState: GameState) {
        let oldState = currentState
        currentState = newState
        
        // Handle state-specific logic
        switch newState {
        case .playing:
            if oldState == .paused {
                // Resume from pause
                print("Game resumed from pause")
            }
        case .paused:
            print("Game paused")
        case .gameOver:
            print("Game over - Final score: \(score)")
        case .levelComplete:
            print("Level \(currentLevel) complete!")
            completeLevel()
        }
    }
    
    /// Check if the game is currently active (playing or paused)
    var isGameActive: Bool {
        return currentState == .playing || currentState == .paused
    }
    
    /// Check if the game is over
    var isGameOver: Bool {
        return currentState == .gameOver
    }
    
    /// Check if the level is complete
    var isLevelComplete: Bool {
        return currentState == .levelComplete
    }
    
    // MARK: - Score Management
    
    /// Add points to the score
    /// - Parameter points: Points to add
    func addScore(_ points: Int) {
        score += points
        print("Score: \(score) (+\(points))")
    }
    
    /// Get the current score
    var currentScore: Int {
        return score
    }
    
    /// Get the score formatted as a string (e.g., "00000")
    var formattedScore: String {
        return String(format: "%05d", score)
    }
    
    // MARK: - Lives Management
    
    /// Lose a life
    /// - Returns: True if player still has lives remaining, false if game over
    @discardableResult
    func loseLife() -> Bool {
        lives -= 1
        print("Lives remaining: \(lives)")
        
        if lives <= 0 {
            changeState(to: .gameOver)
            return false
        }
        
        return true
    }
    
    /// Get the current number of lives
    var currentLives: Int {
        return lives
    }
    
    /// Get the lives formatted as a string
    var formattedLives: String {
        return "\(lives)"
    }
    
    // MARK: - Cherry Management
    
    /// Collect a cherry
    /// - Returns: True if level is now complete
    @discardableResult
    func collectCherry() -> Bool {
        cherriesCollected += 1
        addScore(100) // Cherry collection bonus
        
        print("Cherry collected: \(cherriesCollected)/\(cherriesRequired)")
        
        if cherriesCollected >= cherriesRequired {
            changeState(to: .levelComplete)
            return true
        }
        
        return false
    }
    
    /// Get the current cherry collection progress
    var cherryProgress: (collected: Int, required: Int) {
        return (cherriesCollected, cherriesRequired)
    }
    
    /// Get the cherry progress as a percentage
    var cherryProgressPercentage: Double {
        return Double(cherriesCollected) / Double(cherriesRequired) * 100.0
    }
    
    // MARK: - Level Management
    
    /// Complete the current level
    private func completeLevel() {
        addScore(1000) // Level completion bonus
        
        // Increase difficulty for next level
        enemySpeedMultiplier += 0.1
        print("Enemy speed increased to \(enemySpeedMultiplier * 100)% of player speed")
    }
    
    /// Start a new level
    func startNewLevel() {
        currentLevel += 1
        cherriesCollected = 0
        dugTunnels.removeAll()
        
        // Reset player speed to base (in case it was modified)
        currentPlayerSpeed = basePlayerSpeed
        
        changeState(to: .playing)
        print("Starting level \(currentLevel)")
    }
    
    /// Get the current level number
    var levelNumber: Int {
        return currentLevel
    }
    
    /// Get the enemy speed multiplier
    var enemySpeed: CGFloat {
        return enemySpeedMultiplier
    }
    
    // MARK: - Player Speed Management
    
    /// Set the current player speed
    /// - Parameter speed: New player speed
    func setPlayerSpeed(_ speed: CGFloat) {
        currentPlayerSpeed = speed
    }
    
    /// Get the current player speed
    var playerSpeed: CGFloat {
        return currentPlayerSpeed
    }
    
    /// Get the base player speed
    var defaultPlayerSpeed: CGFloat {
        return basePlayerSpeed
    }
    
    /// Reset player speed to base speed
    func resetPlayerSpeed() {
        currentPlayerSpeed = basePlayerSpeed
    }
    
    // MARK: - Tunnel Management
    
    /// Mark a position as a dug tunnel
    /// - Parameter position: The world position of the dug tunnel
    func markTunnelDug(at position: CGPoint) {
        dugTunnels.insert(position)
    }
    
    /// Check if a position is a dug tunnel
    /// - Parameter position: The world position to check
    /// - Returns: True if the position is a dug tunnel
    func isTunnelDug(at position: CGPoint) -> Bool {
        return dugTunnels.contains(position)
    }
    
    /// Get all dug tunnel positions
    var allDugTunnels: Set<CGPoint> {
        return dugTunnels
    }
    
    /// Clear all dug tunnels (for level reset)
    func clearDugTunnels() {
        dugTunnels.removeAll()
    }
    
    // MARK: - Game Reset
    
    /// Reset the game state for a new game
    func resetToNewGame() {
        currentState = .playing
        score = 0
        lives = 3
        cherriesCollected = 0
        cherriesRequired = 10
        currentLevel = 1
        enemySpeedMultiplier = 0.5
        currentPlayerSpeed = basePlayerSpeed
        dugTunnels.removeAll()
        
        print("New game started")
    }
    
    /// Reset the current level (keep score and lives)
    func resetLevel() {
        cherriesCollected = 0
        dugTunnels.removeAll()
        currentPlayerSpeed = basePlayerSpeed
        changeState(to: .playing)
        
        print("Level \(currentLevel) reset")
    }
    
    // MARK: - Configuration
    
    /// Set the number of cherries required for level completion
    /// - Parameter required: Number of cherries required
    func setCherriesRequired(_ required: Int) {
        cherriesRequired = required
    }
    
    /// Set the base player speed
    /// - Parameter speed: Base player speed
    func setBasePlayerSpeed(_ speed: CGFloat) {
        basePlayerSpeed = speed
        currentPlayerSpeed = speed
    }
    
    /// Set the initial enemy speed multiplier
    /// - Parameter multiplier: Enemy speed multiplier
    func setEnemySpeedMultiplier(_ multiplier: CGFloat) {
        enemySpeedMultiplier = multiplier
    }
    
    // MARK: - Debug Information
    
    /// Get debug information about the current game state
    var debugInfo: String {
        return """
        Game State: \(currentState.rawValue)
        Level: \(currentLevel)
        Score: \(score)
        Lives: \(lives)
        Cherries: \(cherriesCollected)/\(cherriesRequired)
        Player Speed: \(currentPlayerSpeed)
        Enemy Speed Multiplier: \(enemySpeedMultiplier)
        Dug Tunnels: \(dugTunnels.count)
        """
    }
}
