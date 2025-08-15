import SpriteKit

/// System responsible for managing all UI elements in the game
/// Handles score display, lives display, level information, and menu systems
final class UISystem {
    
    // MARK: - UI Elements
    
    /// Main UI container node
    private var uiContainer: SKNode?
    
    /// Score display label
    private var scoreLabel: SKLabelNode?
    
    /// Lives display label
    private var livesLabel: SKLabelNode?
    
    /// Level display label
    private var levelLabel: SKLabelNode?
    
    /// Game state display (e.g., "PAUSED", "GAME OVER")
    private var gameStateLabel: SKLabelNode?
    
    /// Menu container for pause/game over menus
    private var menuContainer: SKNode?
    
    // MARK: - Properties
    
    private let gameStateManager: GameStateManager
    private let scene: SKScene
    
    // MARK: - UI Configuration
    
    /// UI positioning and styling constants
    private struct UIConfig {
        static let topMargin: CGFloat = 20
        static let leftMargin: CGFloat = 20
        static let labelSpacing: CGFloat = 30
        static let fontSize: CGFloat = 18
        static let fontName = "Courier-Bold"
        static let labelColor = SKColor.white
        static let backgroundColor = SKColor.black.withAlphaComponent(0.7)
    }
    
    // MARK: - Initialization
    
    /// Initialize the UI system
    /// - Parameters:
    ///   - scene: The game scene to attach UI to
    ///   - gameStateManager: Manager for game state
    init(scene: SKScene, gameStateManager: GameStateManager) {
        self.scene = scene
        self.gameStateManager = gameStateManager
        setupUI()
    }
    
    // MARK: - UI Setup
    
    /// Set up all UI elements
    private func setupUI() {
        createUIContainer()
        createScoreLabel()
        createLivesLabel()
        createLevelLabel()
        createGameStateLabel()
        createMenuContainer()
        
        // Initial update
        updateAllUI()
    }
    
    /// Create the main UI container
    private func createUIContainer() {
        uiContainer = SKNode()
        uiContainer?.name = "UIContainer"
        uiContainer?.zPosition = 1000 // Ensure UI appears above game elements
        scene.addChild(uiContainer!)
    }
    
    /// Create the score display label
    private func createScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: UIConfig.fontName)
        scoreLabel?.fontSize = UIConfig.fontSize
        scoreLabel?.fontColor = UIConfig.labelColor
        scoreLabel?.horizontalAlignmentMode = .left
        scoreLabel?.verticalAlignmentMode = .top
        scoreLabel?.position = CGPoint(x: UIConfig.leftMargin, y: scene.size.height - UIConfig.topMargin)
        scoreLabel?.name = "ScoreLabel"
        uiContainer?.addChild(scoreLabel!)
    }
    
    /// Create the lives display label
    private func createLivesLabel() {
        livesLabel = SKLabelNode(fontNamed: UIConfig.fontName)
        livesLabel?.fontSize = UIConfig.fontSize
        livesLabel?.fontColor = UIConfig.labelColor
        livesLabel?.horizontalAlignmentMode = .left
        livesLabel?.verticalAlignmentMode = .top
        livesLabel?.position = CGPoint(x: UIConfig.leftMargin, y: scene.size.height - UIConfig.topMargin - UIConfig.labelSpacing)
        livesLabel?.name = "LivesLabel"
        uiContainer?.addChild(livesLabel!)
    }
    
    /// Create the level display label
    private func createLevelLabel() {
        levelLabel = SKLabelNode(fontNamed: UIConfig.fontName)
        levelLabel?.fontSize = UIConfig.fontSize
        levelLabel?.fontColor = UIConfig.labelColor
        levelLabel?.horizontalAlignmentMode = .left
        levelLabel?.verticalAlignmentMode = .top
        levelLabel?.position = CGPoint(x: UIConfig.leftMargin, y: scene.size.height - UIConfig.topMargin - (UIConfig.labelSpacing * 2))
        levelLabel?.name = "LevelLabel"
        uiContainer?.addChild(levelLabel!)
    }
    
    /// Create the game state display label
    private func createGameStateLabel() {
        gameStateLabel = SKLabelNode(fontNamed: UIConfig.fontName)
        gameStateLabel?.fontSize = UIConfig.fontSize * 1.5
        gameStateLabel?.fontColor = UIConfig.labelColor
        gameStateLabel?.horizontalAlignmentMode = .center
        gameStateLabel?.verticalAlignmentMode = .center
        gameStateLabel?.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        gameStateLabel?.name = "GameStateLabel"
        gameStateLabel?.isHidden = true
        uiContainer?.addChild(gameStateLabel!)
    }
    
    /// Create the menu container
    private func createMenuContainer() {
        menuContainer = SKNode()
        menuContainer?.name = "MenuContainer"
        menuContainer?.isHidden = true
        uiContainer?.addChild(menuContainer!)
    }
    
    // MARK: - UI Updates
    
    /// Update all UI elements
    func updateAllUI() {
        updateScoreLabel()
        updateLivesLabel()
        updateLevelLabel()
        updateGameStateLabel()
    }
    
    /// Update the score display
    private func updateScoreLabel() {
        scoreLabel?.text = "Score: \(gameStateManager.score)"
    }
    
    /// Update the lives display
    private func updateLivesLabel() {
        livesLabel?.text = "Lives: \(gameStateManager.lives)"
    }
    
    /// Update the level display
    private func updateLevelLabel() {
        levelLabel?.text = "Level: \(gameStateManager.currentLevel)"
    }
    
    /// Update the game state display
    private func updateGameStateLabel() {
        switch gameStateManager.currentState {
        case .playing:
            gameStateLabel?.isHidden = true
        case .paused:
            gameStateLabel?.text = "PAUSED"
            gameStateLabel?.isHidden = false
        case .gameOver:
            gameStateLabel?.text = "GAME OVER"
            gameStateLabel?.isHidden = false
        case .levelComplete:
            gameStateLabel?.text = "LEVEL COMPLETE!"
            gameStateLabel?.isHidden = false
        }
    }
    
    // MARK: - Menu Management
    
    /// Show the pause menu
    func showPauseMenu() {
        clearMenuContainer()
        
        let pauseMenu = createMenu(title: "PAUSED", options: [
            ("Resume", { [weak self] in self?.hideMenu() }),
            ("Restart Level", { [weak self] in self?.restartLevel() }),
            ("Main Menu", { [weak self] in self?.returnToMainMenu() })
        ])
        
        menuContainer?.addChild(pauseMenu)
        menuContainer?.isHidden = false
    }
    
    /// Show the game over menu
    func showGameOverMenu() {
        clearMenuContainer()
        
        let gameOverMenu = createMenu(title: "GAME OVER", options: [
            ("Try Again", { [weak self] in self?.restartGame() }),
            ("Main Menu", { [weak self] in self?.returnToMainMenu() })
        ])
        
        menuContainer?.addChild(gameOverMenu)
        menuContainer?.isHidden = false
    }
    
    /// Show the level complete menu
    func showLevelCompleteMenu() {
        clearMenuContainer()
        
        let levelCompleteMenu = createMenu(title: "LEVEL COMPLETE!", options: [
            ("Next Level", { [weak self] in self?.nextLevel() }),
            ("Main Menu", { [weak self] in self?.returnToMainMenu() })
        ])
        
        menuContainer?.addChild(levelCompleteMenu)
        menuContainer?.isHidden = false
    }
    
    /// Hide the menu
    func hideMenu() {
        menuContainer?.isHidden = true
        clearMenuContainer()
    }
    
    /// Clear the menu container
    private func clearMenuContainer() {
        menuContainer?.removeAllChildren()
    }
    
    // MARK: - Menu Creation
    
    /// Create a menu with title and options
    /// - Parameters:
    ///   - title: Menu title
    ///   - options: Array of (text, action) tuples
    /// - Returns: Menu node
    private func createMenu(title: String, options: [(String, () -> Void)]) -> SKNode {
        let menuNode = SKNode()
        
        // Create background
        let background = SKShapeNode(rectOf: CGSize(width: 300, height: CGFloat(options.count * 50 + 80)))
        background.fillColor = UIConfig.backgroundColor
        background.strokeColor = UIConfig.labelColor
        background.lineWidth = 2
        background.position = CGPoint(x: 0, y: 0)
        menuNode.addChild(background)
        
        // Create title
        let titleLabel = SKLabelNode(fontNamed: UIConfig.fontName)
        titleLabel.text = title
        titleLabel.fontSize = UIConfig.fontSize * 1.2
        titleLabel.fontColor = UIConfig.labelColor
        titleLabel.position = CGPoint(x: 0, y: background.frame.height / 2 - 30)
        menuNode.addChild(titleLabel)
        
        // Create option buttons
        for (index, option) in options.enumerated() {
            let button = createMenuButton(text: option.0, action: option.1)
            button.position = CGPoint(x: 0, y: background.frame.height / 2 - 80 - CGFloat(index * 50))
            menuNode.addChild(button)
        }
        
        return menuNode
    }
    
    /// Create a menu button
    /// - Parameters:
    ///   - text: Button text
    ///   - action: Action to perform when tapped
    /// - Returns: Button node
    private func createMenuButton(text: String, action: @escaping () -> Void) -> SKNode {
        let buttonNode = SKNode()
        
        // Create button background
        let background = SKShapeNode(rectOf: CGSize(width: 200, height: 40))
        background.fillColor = UIConfig.labelColor.withAlphaComponent(0.3)
        background.strokeColor = UIConfig.labelColor
        background.lineWidth = 1
        buttonNode.addChild(background)
        
        // Create button text
        let label = SKLabelNode(fontNamed: UIConfig.fontName)
        label.text = text
        label.fontSize = UIConfig.fontSize
        label.fontColor = UIConfig.labelColor
        label.verticalAlignmentMode = .center
        buttonNode.addChild(label)
        
        // Store action for later use (in a real implementation, you'd handle touch events)
        // For now, we'll just print the action
        print("Menu button '\(text)' would execute action")
        
        return buttonNode
    }
    
    // MARK: - Menu Actions
    
    /// Restart the current level
    private func restartLevel() {
        print("UISystem: Restart level requested")
        hideMenu()
        // This would be handled by the GameManager
    }
    
    /// Restart the entire game
    private func restartGame() {
        print("UISystem: Restart game requested")
        hideMenu()
        // This would be handled by the GameManager
    }
    
    /// Go to the next level
    private func nextLevel() {
        print("UISystem: Next level requested")
        hideMenu()
        // This would be handled by the GameManager
    }
    
    /// Return to main menu
    private func returnToMainMenu() {
        print("UISystem: Return to main menu requested")
        hideMenu()
        // This would be handled by the GameManager
    }
    
    // MARK: - Visual Effects
    
    /// Show a temporary message
    /// - Parameters:
    ///   - message: Message to display
    ///   - duration: How long to show the message
    func showTemporaryMessage(_ message: String, duration: TimeInterval = 2.0) {
        let messageLabel = SKLabelNode(fontNamed: UIConfig.fontName)
        messageLabel.text = message
        messageLabel.fontSize = UIConfig.fontSize
        messageLabel.fontColor = UIConfig.labelColor
        messageLabel.horizontalAlignmentMode = .center
        messageLabel.verticalAlignmentMode = .center
        messageLabel.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2 + 50)
        messageLabel.zPosition = 1001
        uiContainer?.addChild(messageLabel)
        
        // Animate the message
        let fadeOut = SKAction.fadeOut(withDuration: duration)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fadeOut, remove])
        messageLabel.run(sequence)
    }
    
    /// Show score increase effect
    /// - Parameter points: Points gained
    func showScoreIncrease(_ points: Int) {
        let scoreEffect = SKLabelNode(fontNamed: UIConfig.fontName)
        scoreEffect.text = "+\(points)"
        scoreEffect.fontSize = UIConfig.fontSize * 1.5
        scoreEffect.fontColor = SKColor.yellow
        scoreEffect.horizontalAlignmentMode = .center
        scoreEffect.verticalAlignmentMode = .center
        scoreEffect.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        scoreEffect.zPosition = 1001
        uiContainer?.addChild(scoreEffect)
        
        // Animate the effect
        let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 1.0)
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let remove = SKAction.removeFromParent()
        let group = SKAction.group([moveUp, fadeOut])
        let sequence = SKAction.sequence([group, remove])
        scoreEffect.run(sequence)
    }
    
    // MARK: - Public Interface
    
    /// Update UI when game state changes
    func onGameStateChanged() {
        updateGameStateLabel()
        
        switch gameStateManager.currentState {
        case .paused:
            showPauseMenu()
        case .gameOver:
            showGameOverMenu()
        case .levelComplete:
            showLevelCompleteMenu()
        case .playing:
            hideMenu()
        }
    }
    
    /// Update UI when score changes
    func onScoreChanged() {
        updateScoreLabel()
    }
    
    /// Update UI when lives change
    func onLivesChanged() {
        updateLivesLabel()
    }
    
    /// Update UI when level changes
    func onLevelChanged() {
        updateLevelLabel()
    }
    
    /// Show/hide UI elements
    /// - Parameter isVisible: Whether UI should be visible
    func setUIVisibility(_ isVisible: Bool) {
        uiContainer?.isHidden = !isVisible
    }
}
