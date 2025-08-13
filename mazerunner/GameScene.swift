import SpriteKit
import GameplayKit
import AudioToolbox
import AVFoundation

final class GameScene: SKScene {
    
    // MARK: - Game Constants
    private var gridSize: CGFloat = 32
    private let basePlayerSpeed: CGFloat = 150
    private var currentPlayerSpeed: CGFloat = 150
    private var enemySpeedMultiplier: CGFloat = 0.5  // Enemy speed relative to player (starts at 20% speed)
    private let debugMode = true // Set to false to disable debug features
    
    private var enemySpeed: CGFloat {
        return basePlayerSpeed * enemySpeedMultiplier
    }
    
    // Grid dimensions (calculated in didMove)
    private var gridWidth: Int = 0
    private var gridHeight: Int = 0
    private var gridOffset: CGFloat = 0  // Horizontal offset to center the grid
    private var gridYOffset: CGFloat = 0  // Vertical offset to center the grid  // Offset to center the grid
    private let useGeneratedMaze: Bool = true
    
    // MARK: - Game State
    private var gameState: GameState = .playing
    private var score: Int = 0
    private var lives: Int = 3
    private var cherriesCollected: Int = 0
    private var cherriesRequired: Int = 10
    
    // MARK: - Game Objects
    private var player: SKSpriteNode!
    private var enemies: [Enemy] = []
    private var cherries: [SKSpriteNode] = []
    private var walls: [SKSpriteNode] = []
    private var borderWalls: [SKSpriteNode] = []  // Permanent, undiggable border walls
    private var dugTunnels: Set<CGPoint> = []
    
    // MARK: - UI Elements
    private var scoreLabel: SKLabelNode!
    private var livesLabel: SKLabelNode!
    private var gameOverLabel: SKLabelNode!
    private var debugDirectionLabel: SKLabelNode! // Debug label for enemy direction
    
    // MARK: - Audio
    private var cherrySoundPlayer: SoundPlayer!
    private var deathSoundPlayer: SoundPlayer!
    private var startSoundPlayer: SoundPlayer!
    private var wallSoundPlayer: SoundPlayer!
    
    // MARK: - Input
    private var currentDirection: CGVector = .zero
    private var lastEnemyUpdateTime: TimeInterval = 0
    private let enemyUpdateCooldown: TimeInterval = 0.1
    private var lastFrameTime: TimeInterval = 0
    
    enum GameState {
        case playing
        case paused
        case gameOver
        case levelComplete
    }

    override func didMove(to view: SKView) {
        setupGame()
    }
    
    private func setupGame() {
        backgroundColor = SKColor(red: 0.1, green: 0.05, blue: 0.2, alpha: 1.0)
        
        // Initialize audio
        cherrySoundPlayer = SoundPlayer(fileName: "cherry")
        deathSoundPlayer = SoundPlayer(fileName: "death")
        startSoundPlayer = SoundPlayer(fileName: "start")
        wallSoundPlayer = SoundPlayer(fileName: "wall")
        
        // Set up a 12x27 grid with square cells
        gridWidth = 12
        gridHeight = 27
        
        // Calculate cell size to make them square
        let cellSize = min(size.width / CGFloat(gridWidth), size.height / CGFloat(gridHeight))
        
        // Calculate offsets to center the grid
        let totalGridWidth = CGFloat(gridWidth) * cellSize
        let totalGridHeight = CGFloat(gridHeight) * cellSize
        let extraWidth = size.width - totalGridWidth
        let extraHeight = size.height - totalGridHeight
        
        self.gridOffset = extraWidth / 2
        self.gridYOffset = extraHeight / 2
        
        // Update gridSize to use the calculated cell size
        gridSize = cellSize
        
        createMaze()
        // Spawn cherries immediately after maze so they render above walls but below player/enemies
        spawnCherries()
        setupUI()
        spawnPlayer()
        spawnEnemies()
        updateUI() // Initialize UI labels
        
        // Play start sound
        startSoundPlayer.play(volume: 1.0)
    }
    
    private func setupUI() {
        // Score label - position above the border
        scoreLabel = SKLabelNode(fontNamed: "Courier-Bold")
        scoreLabel.fontSize = 10.5
        scoreLabel.fontColor = SKColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
        scoreLabel.position = CGPoint(x: 75, y: size.height - 20)
        scoreLabel.text = "SCORE: 00000"
        addChild(scoreLabel)
        
        // Lives label - position above the border
        livesLabel = SKLabelNode(fontNamed: "Courier-Bold")
        livesLabel.fontSize = 10.5
        livesLabel.fontColor = SKColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
        livesLabel.position = CGPoint(x: size.width - 75, y: size.height - 20)
        livesLabel.text = "LIVES: 3"
        addChild(livesLabel)
        
        // Debug direction label - only show if debug mode is enabled
        if debugMode {
            debugDirectionLabel = SKLabelNode(fontNamed: "Courier-Bold")
            debugDirectionLabel.fontSize = 18 // Made larger
            debugDirectionLabel.fontColor = SKColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0) // Bright yellow
            debugDirectionLabel.position = CGPoint(x: size.width/2, y: size.height - 80) // Moved lower
            debugDirectionLabel.text = "DIR: --"
            debugDirectionLabel.zPosition = 1000 // Ensure it appears above other elements
            addChild(debugDirectionLabel)
            print("DEBUG: Created debug direction label at position: \(debugDirectionLabel.position)")
        }
        
        // Game over label (hidden initially)
        gameOverLabel = SKLabelNode(fontNamed: "Courier-Bold")
        gameOverLabel.fontSize = 36
        gameOverLabel.fontColor = SKColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        gameOverLabel.position = CGPoint(x: size.width/2, y: size.height/2)
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.zPosition = 1000 // Ensure it appears above all other elements
        gameOverLabel.isHidden = true
        addChild(gameOverLabel)
    }
    
    private func createMaze() {
        // Create border walls according to the 12x27 grid specification:
        // - Row 0: blank (for dynamic island)
        // - Row 1: top border
        // - Rows 2-25: game area
        // - Row 26: bottom border
        // - Column 0: left border
        // - Columns 1-10: game area
        // - Column 11: right border
        
        // Top border (row 1)
        for x in 0..<gridWidth {
            createBorderWall(at: getWorldPosition(CGPoint(x: CGFloat(x), y: 1)))
        }
        
        // Bottom border (row 26)
        for x in 0..<gridWidth {
            createBorderWall(at: getWorldPosition(CGPoint(x: CGFloat(x), y: 26)))
        }
        
        // Left border (column 0) - exclude row 0 for dynamic island
        for y in 1..<gridHeight {
            createBorderWall(at: getWorldPosition(CGPoint(x: 0, y: CGFloat(y))))
        }
        
        // Right border (column 11) - exclude row 0 for dynamic island
        for y in 1..<gridHeight {
            createBorderWall(at: getWorldPosition(CGPoint(x: 11, y: CGFloat(y))))
        }
        
        if useGeneratedMaze {
            // Generate a 10x22 grid for rows 2..23 and cols 1..10
            let mazeGrid = Maze.generate(cols: 10, rows: 22)
            // Map: mazeGrid[rowIndex][colIndex] where
            // rowIndex 0 -> world row 2, ... rowIndex 21 -> world row 23
            // colIndex 0 -> world col 1, ... colIndex 9 -> world col 10
            for rowIndex in 0..<22 {
                let worldRow = 3 + rowIndex
                for colIndex in 0..<10 {
                    let worldCol = 1 + colIndex
                    if mazeGrid[rowIndex][colIndex] {
                        createWall(at: getWorldPosition(CGPoint(x: CGFloat(worldCol), y: CGFloat(worldRow))))
                    }
                }
            }
        } else {
            // Existing random walls logic
            // Create internal maze structure in the game area (rows 2-25, columns 1-10)
            for x in 1...10 {
                for y in 2...25 {
                    // Skip player spawn area (bottom center)
                    if x == 6 && y == 25 {
                        continue
                    }
                    // Skip enemy spawn areas (top row near edges and center)
                    if y == 2 && (x == 2 || x == 6 || x == 9) {
                        continue
                    }
                    
                    if Double.random(in: 0...1) < 0.25 {
                        createWall(at: getWorldPosition(CGPoint(x: CGFloat(x), y: CGFloat(y))))
                    }
                }
            }
            
            // Add some diagonal walls for variety
            for i in stride(from: 3, to: 9, by: 2) {
                if Double.random(in: 0...1) < 0.25 {
                    createWall(at: getWorldPosition(CGPoint(x: CGFloat(i), y: CGFloat(i + 2))))
                }
            }
        }
    }
    
    private func createWall(at position: CGPoint) {
        let wall = createPixelatedSprite(size: CGSize(width: gridSize, height: gridSize), color: SKColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0))
        wall.position = position
        wall.name = "wall"
        wall.zPosition = 0
        walls.append(wall)
        addChild(wall)
    }
    
    private func createBorderWall(at position: CGPoint) {
        //let wall = createPixelatedSprite(size: CGSize(width: gridSize, height: gridSize), color: SKColor(red: 0.4, green: 0.2, blue: 0.1, alpha: 1.0))
        let wall = SKSpriteNode(imageNamed: "borderwall.png")
        wall.size = CGSize(width: gridSize, height: gridSize)
        wall.position = position
        wall.name = "borderWall"
        wall.zPosition = 0
        borderWalls.append(wall)
        addChild(wall)
    }
    
    private func createPixelatedSprite(size: CGSize, color: SKColor) -> SKSpriteNode {
        let sprite = SKSpriteNode(color: color, size: size)
        
        // Add pixelated effect with darker borders
        let border = SKShapeNode(rectOf: size)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        border.strokeColor = SKColor(red: red * 0.5, green: green * 0.5, blue: blue * 0.5, alpha: 1.0)
        border.lineWidth = 2
        border.position = CGPoint.zero
        sprite.addChild(border)
        
        return sprite
    }
    
    private func spawnPlayer() {
        player = createPixelatedSprite(size: CGSize(width: gridSize * 0.8, height: gridSize * 0.8), color: SKColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 1.0))
        player.zPosition = 2
        
        // Spawn player at bottom center of game area (column 6, row 25)
        let playerGridPos = CGPoint(x: 6, y: 25)
        let playerWorldPos = getWorldPosition(playerGridPos)
        player.position = playerWorldPos
        player.name = "player"
        
        // Add player details
        let eye1 = SKShapeNode(circleOfRadius: 2)
        eye1.fillColor = .black
        eye1.position = CGPoint(x: -6, y: 4)
        player.addChild(eye1)
        
        let eye2 = SKShapeNode(circleOfRadius: 2)
        eye2.fillColor = .black
        eye2.position = CGPoint(x: 6, y: 4)
        player.addChild(eye2)
        
        addChild(player)
    }
    
    private func spawnEnemies() {
        let enemyCount = 3
        let enemyColors = [
            SKColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0), // Red
            SKColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0), // Blue
            SKColor(red: 1.0, green: 0.0, blue: 1.0, alpha: 1.0)  // Magenta
        ]
        
        for i in 0..<enemyCount {
            let enemySprite = createPixelatedSprite(size: CGSize(width: gridSize * 0.8, height: gridSize * 0.8), color: enemyColors[i])
            // Give each enemy a slightly different z so overlapping enemies stack together consistently
            enemySprite.zPosition = 2 + (CGFloat(i) * 0.01)
            
            // Spawn enemies at top of game area (row 2, columns 2, 6, 9)
            let enemyGridPositions = [
                CGPoint(x: 2, y: 2),      // Left side
                CGPoint(x: 6, y: 2),      // Center
                CGPoint(x: 9, y: 2)       // Right side
            ]
            
            let gridPos = enemyGridPositions[i]
            let worldPos = getWorldPosition(gridPos)
            enemySprite.position = worldPos
            enemySprite.name = "enemy"
            
            // Add enemy details
            let eye1 = SKShapeNode(circleOfRadius: 2)
            eye1.fillColor = .white
            eye1.position = CGPoint(x: -6, y: 4)
            enemySprite.addChild(eye1)
            
            let eye2 = SKShapeNode(circleOfRadius: 2)
            eye2.fillColor = .white
            eye2.position = CGPoint(x: 6, y: 4)
            enemySprite.addChild(eye2)
            
            // Add centered pupils
            let pupilLeft = SKShapeNode(circleOfRadius: 1)
            pupilLeft.fillColor = .black
            pupilLeft.strokeColor = .black
            pupilLeft.zPosition = 0
            pupilLeft.position = CGPoint(x: -6, y: 4)
            enemySprite.addChild(pupilLeft)

            let pupilRight = SKShapeNode(circleOfRadius: 1)
            pupilRight.fillColor = .black
            pupilRight.strokeColor = .black
            pupilRight.zPosition = 0
            pupilRight.position = CGPoint(x: 6, y: 4)
            enemySprite.addChild(pupilRight)
            
            // Create Enemy object and build its directional sprite variants
            let enemy = Enemy(sprite: enemySprite, color: enemyColors[i])
            enemy.directionalSprites = buildDirectionalEnemySprites(baseColor: enemyColors[i])
            enemies.append(enemy)
            addChild(enemySprite)
            
            // Start the movement chain for this enemy
            let enemyGridPos = getGridPosition(enemySprite.position)
            startEnemyMovement(enemy: enemy, from: enemyGridPos)
        }
    }

    private func buildDirectionalEnemySprites(baseColor: SKColor) -> [SKSpriteNode] {
        // Helper to build four variants with pupils offset relative to eye center
        // Order: [up, down, left, right]
        let offsets: [CGPoint] = [CGPoint(x: 0, y: 2), CGPoint(x: 0, y: -2), CGPoint(x: -2, y: 0), CGPoint(x: 2, y: 0)]
        var sprites: [SKSpriteNode] = []
        for delta in offsets {
            let sprite = createPixelatedSprite(size: CGSize(width: gridSize * 0.8, height: gridSize * 0.8), color: baseColor)
            // Eyes
            let eyeLeft = SKShapeNode(circleOfRadius: 2)
            eyeLeft.fillColor = .white
            eyeLeft.position = CGPoint(x: -6, y: 4)
            sprite.addChild(eyeLeft)
            let eyeRight = SKShapeNode(circleOfRadius: 2)
            eyeRight.fillColor = .white
            eyeRight.position = CGPoint(x: 6, y: 4)
            sprite.addChild(eyeRight)
            // Pupils offset by delta
            let pupilLeft = SKShapeNode(circleOfRadius: 1)
            pupilLeft.fillColor = .black
            pupilLeft.strokeColor = .black
            pupilLeft.zPosition = 0
            pupilLeft.position = CGPoint(x: -6 + delta.x, y: 4 + delta.y)
            sprite.addChild(pupilLeft)
            let pupilRight = SKShapeNode(circleOfRadius: 1)
            pupilRight.fillColor = .black
            pupilRight.strokeColor = .black
            pupilRight.zPosition = 0
            pupilRight.position = CGPoint(x: 6 + delta.x, y: 4 + delta.y)
            sprite.addChild(pupilRight)
            sprites.append(sprite)
        }
        return sprites
    }
    
    private func spawnCherries() {
        for _ in 0..<cherriesRequired {
            let cherry = createCherrySprite()
            
            // Force cherries to spawn inside diggable walls only, not borders and not overlapping others
            var gridPosition: CGPoint
            var worldPosition: CGPoint
            var attempts = 0
            repeat {
                let gridX = Int.random(in: 1...10)
                let gridY = Int.random(in: 2...25)
                gridPosition = CGPoint(x: CGFloat(gridX), y: CGFloat(gridY))
                worldPosition = getWorldPosition(gridPosition)
                attempts += 1
                // Avoid infinite loop in sparse mazes
                if attempts > 500 { break }
            } while !isDiggableWallAtGridPosition(gridPosition) || hasCherry(atGridPosition: gridPosition)
            
            // If we failed to find a wall spot, skip placing this cherry
            if !isDiggableWallAtGridPosition(gridPosition) { continue }
            
            cherry.position = worldPosition
            cherry.name = "cherry"
            cherries.append(cherry)
            addChild(cherry)
        }
    }
    
    private func createCherrySprite() -> SKSpriteNode {
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
        
        // Add sparkle effect
        let sparkle = SKShapeNode(circleOfRadius: 2)
        sparkle.fillColor = SKColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
        sparkle.position = CGPoint(x: 6, y: 6)
        cherry.addChild(sparkle)
        
        return cherry
    }
    
    private func isPositionOccupied(_ position: CGPoint) -> Bool {
        // Check if position overlaps with walls, border walls, player, or enemies
        let checkNode = SKSpriteNode(color: .clear, size: CGSize(width: gridSize, height: gridSize))
        checkNode.position = position
        
        for wall in walls {
            if checkNode.frame.intersects(wall.frame) {
                return true
            }
        }
        
        for borderWall in borderWalls {
            if checkNode.frame.intersects(borderWall.frame) {
                return true
            }
        }
        
        if checkNode.frame.intersects(player.frame) {
            return true
        }
        
        for enemy in enemies {
            if checkNode.frame.intersects(enemy.sprite.frame) {
                return true
            }
        }
        
        return false
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameState == .playing else { return }
        
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let direction = getDirectionFromTouch(location)
        
        if direction != .zero {
            currentDirection = direction
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameState == .playing else { return }

        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let direction = getDirectionFromTouch(location)
        
        if direction != .zero {
            currentDirection = direction
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard gameState == .playing else { return }
        currentDirection = .zero
    }
    

    private func getDirectionFromTouch(_ location: CGPoint) -> CGVector {
        let playerPosition = player.position
        let deltaX = location.x - playerPosition.x
        let deltaY = location.y - playerPosition.y
        
        if abs(deltaX) > abs(deltaY) {
            return deltaX > 0 ? CGVector(dx: 1, dy: 0) : CGVector(dx: -1, dy: 0)
        } else {
            // With inverted grid: touching above player (higher Y) should move to lower row number
            // So positive deltaY should result in negative Y movement in grid coordinates
            return deltaY > 0 ? CGVector(dx: 0, dy: -1) : CGVector(dx: 0, dy: 1)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        guard gameState == .playing else { return }
        
        // Update player immediately (no cooldown for smooth movement)
        updatePlayer()
        
        // Update enemies with a cooldown to avoid excessive processing
        if currentTime - lastEnemyUpdateTime > enemyUpdateCooldown {
            updateEnemies()
            lastEnemyUpdateTime = currentTime
        }
        
        // Check collisions every frame for responsive gameplay
        checkCollisions()
        
        // Update UI every frame to show real-time debug info
        updateUI()
    }
    
    private func updatePlayer() {
        // Stop any existing movement when direction changes to zero
        if currentDirection == .zero {
            player.removeAllActions()
            return
        }
        
        // Skip if player is currently moving
        if player.hasActions() {
            return
        }
        
        // Get the player's current grid position
        let currentGridPos = getGridPosition(player.position)
        
        // Ensure player is properly centered on grid before allowing movement
        if !isAtGridCenter(player.position) {
            // Snap player to grid center
            let centeredPosition = getWorldPosition(currentGridPos)
            player.position = centeredPosition
        }
        
        // Start a chain of movements to avoid pausing at each grid center
        startPlayerMovement(from: currentGridPos)
    }
    
    private func startPlayerMovement(from currentGridPos: CGPoint) {
        // Calculate next grid position based on current direction
        let targetGridPos = CGPoint(
            x: currentGridPos.x + currentDirection.dx,
            y: currentGridPos.y + currentDirection.dy
        )
        
        // Check if we can move in this direction
        if isValidGridPosition(targetGridPos) {
            // Check for walls
            if isWallAtGridPosition(targetGridPos) {
                digWall(at: getWorldPosition(targetGridPos))
                // If it was a border wall, digging fails and wall still exists
                if isWallAtGridPosition(targetGridPos) {
                    return
                }
            }
            
            let targetWorldPos = getWorldPosition(targetGridPos)
            // Calculate duration based on player speed and grid size
            let moveDuration = Double(gridSize) / Double(currentPlayerSpeed)
            let moveAction = SKAction.move(to: targetWorldPos, duration: moveDuration)
            moveAction.timingMode = .linear
            
            // Chain the next movement to avoid pausing
            let nextMoveAction = SKAction.run { [weak self] in
                guard let self = self else { return }
                // Mark tunnel as dug when we reach the position
                self.dugTunnels.insert(targetWorldPos)
                // Only continue if we still have a direction
                if self.currentDirection != .zero {
                    self.startPlayerMovement(from: targetGridPos)
                }
            }
            
            let sequence = SKAction.sequence([moveAction, nextMoveAction])
            player.run(sequence, withKey: "playerMovement")
        }
    }
    
    private func normalize(vector: CGVector) -> CGVector {
        let length = sqrt(vector.dx * vector.dx + vector.dy * vector.dy)
        guard length > 0 else { return .zero }
        return CGVector(dx: vector.dx / length, dy: vector.dy / length)
    }
    
    private func updateEnemies() {
        for enemy in enemies {
            // Skip if enemy is currently moving
            if enemy.sprite.hasActions() {
                continue
            }
            
            // Get the enemy's current grid position
            let currentGridPos = getGridPosition(enemy.sprite.position)
            
            // Ensure enemy is properly centered on grid before allowing movement
            if !isAtGridCenter(enemy.sprite.position) {
                // Snap enemy to grid center
                let centeredPosition = getWorldPosition(currentGridPos)
                enemy.sprite.position = centeredPosition
            }
            
            // Start a chain of movements to avoid pausing at each grid center
            startEnemyMovement(enemy: enemy, from: currentGridPos)
        }
    }
    
    private func startEnemyMovement(enemy: Enemy, from currentGridPos: CGPoint) {
        // Build a list of all possible directions
        let allDirections = [
            CGVector(dx: 0, dy: 1),  // Up
            CGVector(dx: 0, dy: -1), // Down
            CGVector(dx: -1, dy: 0), // Left
            CGVector(dx: 1, dy: 0)   // Right
        ]
        
        var possibleDirections: [CGVector] = []
        
        // Check which directions are valid (no walls, within bounds, and not going back to last position)
        for direction in allDirections {
            let testGridPos = CGPoint(
                x: currentGridPos.x + direction.dx,
                y: currentGridPos.y + direction.dy
            )
            
            if isValidGridPosition(testGridPos) && !isWallAtGridPosition(testGridPos) {
                // Don't go back to the position we just came from
                if testGridPos != enemy.lastGridPosition {
                    possibleDirections.append(direction)
                }
            }
        }
        
        // If no directions available, wait and try again
        if possibleDirections.isEmpty {
            let waitDuration = Double(gridSize) / Double(enemySpeed)
            let waitAction = SKAction.wait(forDuration: waitDuration)
            let retryAction = SKAction.run { [weak self] in
                self?.startEnemyMovement(enemy: enemy, from: currentGridPos)
            }
            let sequence = SKAction.sequence([waitAction, retryAction])
            enemy.sprite.run(sequence, withKey: "enemyMovement")
            return
        }
        
        // Pick a random direction from the available ones
        let chosenDirection = possibleDirections.randomElement()!
        moveEnemy(enemy: enemy, direction: chosenDirection, from: currentGridPos)
    }
    
    private func useDirectionalSprite(for enemy: Enemy) {
        guard !enemy.directionalSprites.isEmpty else { return }
        let index: Int
        switch enemy.direction {
        case .up: index = 0
        case .down: index = 1
        case .left: index = 2
        case .right: index = 3
        }

        let oldNode = enemy.sprite
        let newNode = enemy.directionalSprites[index]

        // If this node is already active, skip
        if newNode === oldNode { return }

        newNode.position = oldNode.position
        newNode.zPosition = oldNode.zPosition
        newNode.name = oldNode.name

        addChild(newNode)
        oldNode.removeFromParent()
        enemy.sprite = newNode
    }

    private func moveEnemy(enemy: Enemy, direction: CGVector, from currentGridPos: CGPoint) {
        let targetGridPos = CGPoint(
            x: currentGridPos.x + direction.dx,
            y: currentGridPos.y + direction.dy
        )
        
        // Store the current position as lastGridPosition BEFORE moving
        enemy.lastGridPosition = currentGridPos
        // Update enemy direction to the new direction and swap sprite variant
        enemy.direction = vectorToDirection(direction)
        useDirectionalSprite(for: enemy)
        
        let targetWorldPos = getWorldPosition(targetGridPos)
        // Calculate duration based on enemy speed and grid size
        let moveDuration = Double(gridSize) / Double(enemySpeed)
        let moveAction = SKAction.move(to: targetWorldPos, duration: moveDuration)
        moveAction.timingMode = .linear
        
        // Check if the target position is an intersection (multiple directions available)
        let allDirections = [
            CGVector(dx: 0, dy: 1),  // Up
            CGVector(dx: 0, dy: -1), // Down
            CGVector(dx: -1, dy: 0), // Left
            CGVector(dx: 1, dy: 0)   // Right
        ]
        
        var availableDirectionsAtTarget: [CGVector] = []
        for dir in allDirections {
            let testGridPos = CGPoint(
                x: targetGridPos.x + dir.dx,
                y: targetGridPos.y + dir.dy
            )
            if isValidGridPosition(testGridPos) && !isWallAtGridPosition(testGridPos) {
                availableDirectionsAtTarget.append(dir)
            }
        }
        
        // Only make a new decision if we're at an intersection (multiple directions available)
        let nextMoveAction = SKAction.run { [weak self] in
            if availableDirectionsAtTarget.count > 1 {
                // We're at an intersection, make a new decision
                self?.startEnemyMovement(enemy: enemy, from: targetGridPos)
            } else if availableDirectionsAtTarget.count == 1 {
                // Only one direction available, continue in that direction
                let nextDirection = availableDirectionsAtTarget[0]
                self?.moveEnemy(enemy: enemy, direction: nextDirection, from: targetGridPos)
            } else {
                // No directions available, wait and try again (dead end)
                let waitDuration = Double(self?.gridSize ?? 32) / Double(self?.enemySpeed ?? 100)
                let waitAction = SKAction.wait(forDuration: waitDuration)
                let retryAction = SKAction.run { [weak self] in
                    self?.startEnemyMovement(enemy: enemy, from: targetGridPos)
                }
                let sequence = SKAction.sequence([waitAction, retryAction])
                enemy.sprite.run(sequence, withKey: "enemyMovement")
            }
        }
        
        let sequence = SKAction.sequence([moveAction, nextMoveAction])
        enemy.sprite.run(sequence, withKey: "enemyMovement")
    }
    
    private func getEnemyDirection(_ enemy: Enemy) -> CGVector {
        // Simple AI: move towards player
        let deltaX = player.position.x - enemy.sprite.position.x
        let deltaY = player.position.y - enemy.sprite.position.y
        
        if abs(deltaX) > abs(deltaY) {
            return deltaX > 0 ? CGVector(dx: 1, dy: 0) : CGVector(dx: -1, dy: 0)
        } else {
            // With inverted grid: if player is above enemy in world coordinates (higher Y),
            // enemy should move to lower row number in grid coordinates (negative Y movement)
            return deltaY > 0 ? CGVector(dx: 0, dy: -1) : CGVector(dx: 0, dy: 1)
        }
    }
    
    private func vectorToDirection(_ vector: CGVector) -> Direction {
        if vector.dx > 0 {
            return .right
        } else if vector.dx < 0 {
            return .left
        } else if vector.dy > 0 {
            return .down  // Positive Y in our inverted system means moving down
        } else if vector.dy < 0 {
            return .up    // Negative Y in our inverted system means moving up
        }
        return .down // Default fallback
    }
    
    private func getOppositeDirection(_ direction: Direction) -> Direction {
        switch direction {
        case .up:
            return .down
        case .down:
            return .up
        case .left:
            return .right
        case .right:
            return .left
        }
    }
    
    private func getOppositeDirection(_ direction: CGPoint) -> Direction {
        switch direction {
        case CGPoint(x: 0, y: 1): // Up
            return .down
        case CGPoint(x: 0, y: -1): // Down
            return .up
        case CGPoint(x: -1, y: 0): // Left
            return .right
        case CGPoint(x: 1, y: 0): // Right
            return .left
        default:
            return .down // Default fallback
        }
    }
    
    private func directionToVector(_ direction: Direction) -> CGVector {
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
    
    private func findAlternativePath(for enemy: SKSpriteNode) -> CGVector {
        // Try all four directions to find a valid path
        let directions: [CGVector] = [
            CGVector(dx: 1, dy: 0),   // Right
            CGVector(dx: -1, dy: 0),  // Left
            CGVector(dx: 0, dy: 1),   // Up
            CGVector(dx: 0, dy: -1)   // Down
        ]
        
        // Calculate distance to player for each direction
        var bestDirection = CGVector.zero
        var shortestDistance: CGFloat = CGFloat.greatestFiniteMagnitude
        
        for direction in directions {
            let testPosition = CGPoint(
                x: enemy.position.x + direction.dx * gridSize,
                y: enemy.position.y + direction.dy * gridSize
            )
            
            // Convert to grid position and check if valid
            let testGridPos = getGridPosition(testPosition)
            
            // Check if this direction is valid (no walls, within bounds)
            if isValidGridPosition(testGridPos) && !isWallAtGridPosition(testGridPos) {
                // Calculate distance from this position to the player
                let distanceToPlayer = sqrt(
                    pow(testPosition.x - player.position.x, 2) +
                    pow(testPosition.y - player.position.y, 2)
                )
                
                // Choose the direction that gets closest to the player
                if distanceToPlayer < shortestDistance {
                    shortestDistance = distanceToPlayer
                    bestDirection = direction
                }
            }
        }
        
        return bestDirection
    }
    
    // MARK: - Grid-Based Movement Helper Functions
    
    private func getGridPosition(_ worldPosition: CGPoint) -> CGPoint {
        // Convert world position to grid coordinates
        // Invert Y coordinate so row 0 is at the top
        let gridX = round((worldPosition.x - gridSize/2 - gridOffset) / gridSize)
        let gridY = CGFloat(gridHeight - 1) - round((worldPosition.y - gridSize/2 - gridYOffset) / gridSize)
        return CGPoint(x: gridX, y: gridY)
    }
    
    private func getWorldPosition(_ gridPosition: CGPoint) -> CGPoint {
        // Convert grid coordinates to world position (centered)
        // Invert Y coordinate so row 0 is at the top (for dynamic island)
        let worldX = gridPosition.x * gridSize + gridSize/2 + gridOffset
        let worldY = (CGFloat(gridHeight - 1) - gridPosition.y) * gridSize + gridSize/2 + gridYOffset
        return CGPoint(x: worldX, y: worldY)
    }
    
    private func isAtGridCenter(_ worldPosition: CGPoint) -> Bool {
        let gridPos = getGridPosition(worldPosition)
        let expectedWorldPos = getWorldPosition(gridPos)
        let tolerance: CGFloat = 2.0
        
        return abs(worldPosition.x - expectedWorldPos.x) < tolerance &&
               abs(worldPosition.y - expectedWorldPos.y) < tolerance
    }
    
    private func isValidGridPosition(_ gridPosition: CGPoint) -> Bool {
        return gridPosition.x >= 0 && gridPosition.x < CGFloat(gridWidth) &&
               gridPosition.y >= 0 && gridPosition.y < CGFloat(gridHeight)
    }
    
    private func isWallAtGridPosition(_ gridPosition: CGPoint) -> Bool {
        // Check regular walls
        for wall in walls {
            let wallGridPos = getGridPosition(wall.position)
            if abs(gridPosition.x - wallGridPos.x) < 0.1 && abs(gridPosition.y - wallGridPos.y) < 0.1 {
                return true
            }
        }
        
        // Check border walls
        for borderWall in borderWalls {
            let wallGridPos = getGridPosition(borderWall.position)
            if abs(gridPosition.x - wallGridPos.x) < 0.1 && abs(gridPosition.y - wallGridPos.y) < 0.1 {
                return true
            }
        }
        
        return false
    }

    private func isDiggableWallAtGridPosition(_ gridPosition: CGPoint) -> Bool {
        // True only for regular walls (not border walls)
        for wall in walls {
            let wallGridPos = getGridPosition(wall.position)
            if abs(gridPosition.x - wallGridPos.x) < 0.1 && abs(gridPosition.y - wallGridPos.y) < 0.1 {
                return true
            }
        }
        return false
    }

    private func hasCherry(atGridPosition gridPosition: CGPoint) -> Bool {
        for cherry in cherries {
            let cherryGridPos = getGridPosition(cherry.position)
            if abs(gridPosition.x - cherryGridPos.x) < 0.1 && abs(gridPosition.y - cherryGridPos.y) < 0.1 {
                return true
            }
        }
        return false
    }
    
    private func findAlternativeGridPath(for enemy: Enemy, from currentGridPos: CGPoint) -> CGVector {
        let directions = [
            CGVector(dx: 0, dy: 1),  // Up
            CGVector(dx: 0, dy: -1), // Down
            CGVector(dx: -1, dy: 0), // Left
            CGVector(dx: 1, dy: 0)   // Right
        ]
        
        var bestDirection = CGVector.zero
        var shortestDistance: CGFloat = CGFloat.greatestFiniteMagnitude
        
        let playerGridPos = getGridPosition(player.position)
        
        for direction in directions {
            let testGridPos = CGPoint(
                x: currentGridPos.x + direction.dx,
                y: currentGridPos.y + direction.dy
            )
            
            // Check if this direction is valid (no walls, within bounds)
            if isValidGridPosition(testGridPos) && !isWallAtGridPosition(testGridPos) {
                // Avoid going back the way we just came
                let directionEnum = vectorToDirection(direction)
                let oppositeDirection = getOppositeDirection(enemy.direction)
                
                if directionEnum == oppositeDirection {
                    continue // Skip this direction as it's the opposite of where we just came from
                }
                
                // Calculate grid distance to player
                let distanceToPlayer = sqrt(
                    pow(testGridPos.x - playerGridPos.x, 2) +
                    pow(testGridPos.y - playerGridPos.y, 2)
                )
                
                // Choose the direction that gets closest to the player
                if distanceToPlayer < shortestDistance {
                    shortestDistance = distanceToPlayer
                    bestDirection = direction
                }
            }
        }
        
        // If no valid direction found (all directions blocked or would backtrack), 
        // allow backtracking as a last resort
        if bestDirection == .zero {
            for direction in directions {
                let testGridPos = CGPoint(
                    x: currentGridPos.x + direction.dx,
                    y: currentGridPos.y + direction.dy
                )
                
                if isValidGridPosition(testGridPos) && !isWallAtGridPosition(testGridPos) {
                    bestDirection = direction
                    break
                }
            }
        }
        
        return bestDirection
    }
    
    private func isValidPosition(_ position: CGPoint) -> Bool {
        return position.x >= gridSize && position.x < size.width - gridSize &&
               position.y >= gridSize && position.y < size.height - gridSize
    }
    
    private func slowPlayerForDigging() {
        // Cancel any existing slowdown action to prevent overlapping
        self.removeAction(forKey: "diggingSlowdown")
        
        // Ensure we start from a clean state
        currentPlayerSpeed = basePlayerSpeed
        
        // Create the slowdown action sequence
        let slowAction = SKAction.run { 
            self.currentPlayerSpeed = self.basePlayerSpeed * 0.5
            // Add visual indicator - change player color to show slowdown
            self.player.color = SKColor(red: 0.7, green: 0.7, blue: 1.0, alpha: 1.0)
            
            // Restart player movement with new speed if they're currently moving
            if self.player.hasActions() && self.currentDirection != .zero {
                self.player.removeAllActions()
                let currentGridPos = self.getGridPosition(self.player.position)
                self.startPlayerMovement(from: currentGridPos)
            }
        }
        let waitAction = SKAction.wait(forDuration: 0.5)
        let normalAction = SKAction.run { 
            self.currentPlayerSpeed = self.basePlayerSpeed
            // Restore normal player color
            self.player.color = SKColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 1.0)
            
            // Restart player movement with normal speed if they're currently moving
            if self.player.hasActions() && self.currentDirection != .zero {
                self.player.removeAllActions()
                let currentGridPos = self.getGridPosition(self.player.position)
                self.startPlayerMovement(from: currentGridPos)
            }
            
            print("DEBUG: Player speed reset to normal: \(self.currentPlayerSpeed)")
        }
        let sequence = SKAction.sequence([slowAction, waitAction, normalAction])
        
        // Run it on the scene itself, not the player
        self.run(sequence, withKey: "diggingSlowdown")
    }
    
    private func digWall(at position: CGPoint) {
        // Convert world position to grid position
        let gridPosition = getGridPosition(position)
        
        // Don't dig border walls - they are permanent
        for borderWall in borderWalls {
            let wallGridPos = getGridPosition(borderWall.position)
            if abs(gridPosition.x - wallGridPos.x) < 0.1 && abs(gridPosition.y - wallGridPos.y) < 0.1 {
                return // This is a border wall, don't dig it
            }
        }
        
        // Find and remove wall at the exact grid position
        walls = walls.filter { wall in
            let wallGridPos = getGridPosition(wall.position)
            
            if abs(gridPosition.x - wallGridPos.x) < 0.1 && abs(gridPosition.y - wallGridPos.y) < 0.1 {
                // Add digging effect
                let digEffect = SKSpriteNode(color: SKColor(red: 0.8, green: 0.6, blue: 0.4, alpha: 1.0), size: CGSize(width: gridSize * 0.5, height: gridSize * 0.5))
                digEffect.position = wall.position
                digEffect.alpha = 0.8
                addChild(digEffect)
                
                let fadeOut = SKAction.fadeOut(withDuration: 0.5)
                let remove = SKAction.removeFromParent()
                digEffect.run(SKAction.sequence([fadeOut, remove]))
                
                // Play wall digging sound
                wallSoundPlayer.play(volume: 0.2)
                
                // Slow down player for digging
                slowPlayerForDigging()
                
                // Award points for digging a wall
                score += 10
                updateUI()

                wall.removeFromParent()
                return false
            }
            return true
        }
    }

    private func checkCollisions() {
        // Check cherry collection with distance-based detection
        cherries = cherries.filter { cherry in
            let distance = sqrt(
                pow(player.position.x - cherry.position.x, 2) +
                pow(player.position.y - cherry.position.y, 2)
            )
            
            // Collection radius - more forgiving than frame intersection
            if distance < gridSize * 0.6 {
                cherry.removeFromParent()
                cherriesCollected += 1
                score += 100
                // Play cherry collection sound
                cherrySoundPlayer.play(volume: 0.8)
                updateUI()
                
                // Add collection effect
                let effect = SKLabelNode(fontNamed: "Courier-Bold")
                effect.fontSize = 16
                effect.fontColor = SKColor(red: 1.0, green: 1.0, blue: 0.0, alpha: 1.0)
                effect.position = cherry.position
                effect.text = "+100"
                addChild(effect)
                
                let moveUp = SKAction.moveBy(x: 0, y: 30, duration: 1.0)
                let fadeOut = SKAction.fadeOut(withDuration: 1.0)
                let remove = SKAction.removeFromParent()
                effect.run(SKAction.sequence([SKAction.group([moveUp, fadeOut]), remove]))
                
                if cherriesCollected >= cherriesRequired {
                    levelComplete()
                }
                return false
            }
            return true
        }
        
        // Check enemy collision with more precise distance-based detection
        for enemy in enemies {
            let distance = sqrt(
                pow(player.position.x - enemy.sprite.position.x, 2) +
                pow(player.position.y - enemy.sprite.position.y, 2)
            )
            
            // Collision radius - smaller than grid size for better feel
            if distance < gridSize * 0.7 {
                playerHit()
                break
            }
        }
    }
    
    private func playerHit() {
        lives -= 1
        updateUI()
        
        // Play death sound
        deathSoundPlayer.play(volume: 0.9)
        
        // Add hit effect
        let hitEffect = SKSpriteNode(color: SKColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5), size: player.size)
        hitEffect.position = player.position
        addChild(hitEffect)
        
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        hitEffect.run(SKAction.sequence([fadeOut, remove]))
        
        if lives <= 0 {
            gameOver()
        } else {
            // Temporarily pause the game to prevent multiple collisions
            gameState = .paused
            
            // Stop all movement immediately
            player.removeAllActions()
            for enemy in enemies {
                enemy.sprite.removeAllActions()
            }
            
            // Reset player direction to prevent continued movement after respawn
            currentDirection = .zero
            
            // Pause for 1 second before resetting positions
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // Reset player position to bottom center of game area (column 6, row 25)
                let playerGridPos = CGPoint(x: 6, y: 25)
                let playerWorldPos = self.getWorldPosition(playerGridPos)
                self.player.position = playerWorldPos
                
                // Reset enemies to their starting positions
                let enemyGridPositions = [
                    CGPoint(x: 2, y: 2),      // Left side
                    CGPoint(x: 6, y: 2),      // Center
                    CGPoint(x: 9, y: 2)       // Right side
                ]
                
                for (index, enemy) in self.enemies.enumerated() {
                    // Stop current movement
                    enemy.sprite.removeAllActions()
                    
                    // Reset to starting position
                    let gridPos = enemyGridPositions[index]
                    let worldPos = self.getWorldPosition(gridPos)
                    enemy.sprite.position = worldPos
                    
                    // Reset enemy state
                    enemy.lastGridPosition = CGPoint.zero
                    enemy.direction = .down // Default direction
                    
                    // Restart movement from new position
                    self.startEnemyMovement(enemy: enemy, from: gridPos)
                }
                
                // Resume gameplay
                self.gameState = .playing
            }
        }
    }
    
    private func levelComplete() {
        gameState = .levelComplete
        score += 1000
        
        // Increase enemy speed by 10% for the next level
        enemySpeedMultiplier += 0.1
        print("Enemy speed increased to \(enemySpeedMultiplier * 100)% of player speed")
        
        updateUI()
        
        // Show level complete message
        let levelCompleteLabel = SKLabelNode(fontNamed: "Courier-Bold")
        levelCompleteLabel.fontSize = 32
        levelCompleteLabel.fontColor = SKColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
        levelCompleteLabel.position = CGPoint(x: size.width/2, y: size.height/2)
        levelCompleteLabel.text = "LEVEL COMPLETE!"
        addChild(levelCompleteLabel)
        
        // Restart level after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.restartLevel()
        }
    }
    
    private func gameOver() {
        gameState = .gameOver
        gameOverLabel.isHidden = false
        
        // Restart game after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.restartGame()
        }
    }
    
    private func restartLevel() {
        // Remove all game objects
        player.removeFromParent()
        enemies.forEach { $0.sprite.removeFromParent() }
        cherries.forEach { $0.removeFromParent() }
        walls.forEach { $0.removeFromParent() }
        borderWalls.forEach { $0.removeFromParent() }
        
        // Reset game state
        enemies.removeAll()
        cherries.removeAll()
        walls.removeAll()
        borderWalls.removeAll()
        dugTunnels.removeAll()
        cherriesCollected = 0
        gameState = .playing
        
        // Recreate level
        createMaze()
        spawnPlayer()
        spawnEnemies()
        spawnCherries()
        
        // Remove level complete label
        children.forEach { child in
            if child is SKLabelNode && (child as! SKLabelNode).text == "LEVEL COMPLETE!" {
                child.removeFromParent()
            }
        }
    }
    
    private func restartGame() {
        // Reset all game state
        score = 0
        lives = 3
        cherriesCollected = 0
        enemySpeedMultiplier = 0.5  // Reset enemy speed to starting value
        gameState = .playing
        
        // Remove all game objects
        player.removeFromParent()
        enemies.forEach { $0.sprite.removeFromParent() }
        cherries.forEach { $0.removeFromParent() }
        walls.forEach { $0.removeFromParent() }
        borderWalls.forEach { $0.removeFromParent() }
        
        // Reset collections
        enemies.removeAll()
        cherries.removeAll()
        walls.removeAll()
        borderWalls.removeAll()
        dugTunnels.removeAll()
        
        // Hide game over label
        gameOverLabel.isHidden = true
        
        // Recreate game
        createMaze()
        spawnPlayer()
        spawnEnemies()
        spawnCherries()
        updateUI()
        
        // Play start sound
        startSoundPlayer.play(volume: 1.0)
    }
    
    private func updateUI() {
        scoreLabel.text = String(format: "SCORE: %05d", score)
        livesLabel.text = "LIVES: \(lives)"
        
        // Update debug direction label if debug mode is enabled
        if debugMode && debugDirectionLabel != nil {
            if !enemies.isEmpty {
                let enemy = enemies[0]
                let currentGridPos = getGridPosition(enemy.sprite.position)
                debugDirectionLabel.text = "DIR: \(enemy.direction.rawValue.uppercased()) | LAST: (\(Int(enemy.lastGridPosition.x)),\(Int(enemy.lastGridPosition.y)))"
            } else {
                debugDirectionLabel.text = "DIR: -- | LAST: --"
            }
        }
    }
}
