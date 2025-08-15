# MazeRunner

A classic maze-based arcade game built with SpriteKit and Swift, featuring grid-based movement, enemy AI, and strategic wall-digging gameplay.

## 📋 Technical Implementation

### Class Structure
- **Main Class**: `final class GameScene: SKScene`
- **Game State Enum**: `enum GameState { playing, paused, gameOver, levelComplete }`
- **Code Organization**: MARK comments for sections (Game Constants, Game State, Game Objects, UI Elements, Audio, Input, Grid-Based Movement Helper Functions)

### Framework Dependencies
- **SpriteKit**: Core game framework
- **GameplayKit**: Maze generation utilities
- **AudioToolbox**: Audio system support
- **AVFoundation**: Audio playback capabilities

## 🎮 How to Play

### Objective
Navigate through procedurally generated mazes, collect cherries, and avoid enemies while advancing through increasingly difficult levels.

### Controls
- **Touch & Drag**: Move the player in the direction you swipe
- **Tap**: Quick directional movement
- **Long Press**: Strategic positioning
- **Direction Calculation**: Based on touch position relative to player (larger delta determines direction)
- **Inverted Y-Axis**: Touching above player moves to lower row number (grid coordinates)
- **Touch Events**:
  - `touchesBegan`: Sets direction based on touch location
  - `touchesMoved`: Updates direction during drag
  - `touchesEnded`: Resets direction to zero (stops movement)
- **Movement State**: Only processes input when `gameState == .playing`

## 🏗️ Game Architecture

### Maze Generation
- **Algorithm**: Depth-first search maze generation
- **Dimensions**: 10x22 internal maze (12x27 total game grid)
- **Grid Layout**:
  - Row 0: Blank (for dynamic island)
  - Row 1: Top border
  - Rows 2-25: Game area
  - Row 26: Bottom border
  - Column 0: Left border
  - Columns 1-10: Game area
  - Column 11: Right border
- **Entrances**: 3 entrances at the top (columns 1, 5, 9)
- **Exit**: 1 exit at the bottom (center column)
- **Connectivity**: All paths are guaranteed to be reachable
- **Border Walls**: Permanent, undiggable walls around the perimeter
- **Spawn Protection**: Player spawn (6,25) and enemy spawns (2,2), (6,2), (9,2) are protected from wall generation

### Grid-Based Movement
- **Player**: Moves along grid lines, can dig through walls
- **Enemies**: Follow grid paths, cannot dig walls
- **No Backtracking**: Enemies avoid reversing direction unless no other option exists
- **Grid Alignment**: All movement is snapped to grid positions
- **Grid Conversion**:
  - World to Grid: `gridX = round((worldX - gridSize/2 - gridOffset) / gridSize)`
  - Grid to World: `worldX = gridX * gridSize + gridSize/2 + gridOffset`
  - Y-axis inverted: Row 0 at top, increasing downward
- **Grid Center Tolerance**: 2.0 pixels for movement validation
- **Position Validation**:
  - `isValidGridPosition`: Checks bounds (0 to gridWidth/gridHeight)
  - `isAtGridCenter`: Checks if object is within 2.0 pixels of grid center
  - `isWallAtGridPosition`: Checks for walls with 0.1 tolerance
  - `isDiggableWallAtGridPosition`: Checks only regular walls (not border walls)
  - `isValidPosition`: Checks world bounds (gridSize to screenSize - gridSize)
  - `isPositionOccupied`: Uses frame intersection for collision detection
- **Collision Detection**:
  - Cherry collection: 60% of grid size radius
  - Enemy collision: 70% of grid size radius
- **Grid Dimensions**: 12x27 total grid (10x22 internal maze area)
- **Cell Size**: Calculated as `min(screenWidth/12, screenHeight/27)` for square cells
- **Movement State Management**:
  - Objects must be at grid center before movement starts
  - Movement only occurs when no actions are currently running (`hasActions()` check)
  - Direction must be non-zero for movement to start
  - Actions are chained to avoid pauses at grid centers

## 🎯 Gameplay Mechanics

### Level Progression
- **Cherry Collection**: Collect all 10 cherries to complete a level
- **Level Advancement**: Automatically progresses to next level after 2-second delay
- **Difficulty Scaling**: Enemies get faster each level (+10% speed)
- **Level Reset**: Player and enemies return to spawn positions
- **Pause on Hit**: Game pauses for 1 second when player is hit

### Scoring System
- **Cherry Collection**: +100 points per cherry
- **Wall Digging**: +10 points per wall removed
- **Level Completion**: +1000 points bonus
- **Score Display**: 5-digit format (e.g., "00000")

### Player Abilities
- **Movement**: Grid-based movement in 4 directions
- **Spawn Position**: Column 6, row 25 (bottom center of game area)
- **Wall Digging**: Can dig through regular walls (not border walls)
- **Slowdown Effect**: Temporarily slows down to 50% speed for 0.5 seconds after digging a wall
- **Lives**: Start with 3 lives, lose 1 when hit by enemy
- **Respawn**: Returns to spawn position after being hit

### Enemy Behavior
- **AI Movement**: Pathfinding toward player position
- **Speed Progression**: 
  - Level 1: 50% of player speed (enemySpeedMultiplier = 0.5)
  - Each level: +10% speed increase
- **Movement Rules**:
  - Cannot dig walls
  - Can move through dug walls
  - Avoids backtracking when possible
  - Grid-aligned movement only
- **Enemy Count**: 3 enemies (Red, Blue, Magenta)
- **Spawn Positions**: Row 2, columns 2, 6, 9 (top of game area)
- **Movement Timing**: Updates every 0.1 seconds (enemyUpdateCooldown)
- **Movement Algorithm**:
  - Random direction selection from available paths
  - Avoids returning to last grid position
  - Waits at dead ends and retries
  - Makes new decisions only at intersections (multiple paths available)
  - Continues straight when only one path available
- **Directional Sprites**: Each enemy has 4 sprite variants (up, down, left, right) with pupil positions

### Cherry Spawning
- **Count**: 10 cherries per level
- **Spawn Rules**: Only inside diggable walls (not border walls)
- **Avoidance**: No overlapping with other cherries
- **Retry Logic**: Up to 500 attempts per cherry placement
- **Spawn Area**: Grid positions (1,2) to (10,25) - internal maze area only

## 🏗️ Technical Architecture

### Project Structure
```
mazerunner/
├── Foundation/          # Core utilities and protocols
│   ├── GridSystem.swift
│   ├── GameGrid.swift
│   ├── GameObject.swift
│   ├── GameState.swift
│   ├── Direction.swift
│   ├── Maze.swift
│   └── SoundPlayer.swift
├── Core/               # Game entities
│   ├── Player.swift
│   ├── Enemy.swift
│   ├── Cherry.swift
│   ├── Wall.swift
│   └── GameManager.swift
├── Systems/            # Game systems
│   ├── MovementSystem.swift
│   ├── CollisionSystem.swift
│   ├── AudioSystem.swift
│   ├── UISystem.swift
│   └── InputManager.swift
├── UI/                 # User interface
│   ├── GameViewController.swift
│   └── AppDelegate.swift
└── Legacy/             # Original GameScene (for reference)
    └── GameScene.swift
```

### Key Systems

#### MovementSystem
- Handles player and enemy movement
- Manages movement timers and speed scaling
- Implements grid-based movement validation
- Controls player slowdown effects

#### CollisionSystem
- Detects collisions between game objects
- Handles cherry collection
- Manages player-enemy collisions
- Processes wall-digging interactions

#### GameStateManager
- Tracks score, lives, and level progression
- Manages enemy speed scaling
- Handles game state transitions
- Maintains dug tunnel positions

#### Maze Generation
- Uses depth-first search algorithm
- Creates connected, navigable mazes
- Ensures proper entrance/exit placement
- Maintains spawn area protection

## 🎨 Visual Design

### Game Objects
- **Player**: Yellow circle (RGB: 1.0, 0.9, 0.0) with black eyes, zPosition 2
- **Enemies**: 3 colored circles (Red, Blue, Magenta) with white eyes and black pupils, zPosition 2 + (index * 0.01)
- **Cherries**: Red circles (RGB: 1.0, 0.0, 0.0) with green stems (RGB: 0.3, 0.6, 0.0) and yellow sparkle effects, zPosition 1
- **Walls**: Brown rectangles (RGB: 0.6, 0.4, 0.2) with darker borders, zPosition 0
- **Border Walls**: Image-based ("borderwall.png") instead of colored rectangles, zPosition 0
- **Dug Tunnels**: Invisible but trackable positions
- **Object Sizes**: All game objects are 80% of grid cell size (gridSize * 0.8)
- **Pixelated Effect**: All sprites have darker borders for pixelated appearance
- **Visual Details**:
  - Eyes: 2px radius circles
  - Pupils: 1px radius circles
  - Cherry body: 8px radius circle
  - Cherry sparkle: 2px radius circle
  - Cherry stem: 2px line width
  - Sprite borders: 2px line width

### Visual Effects
- **Player Slowdown**: Blue tint (RGB: 0.7, 0.7, 1.0) during digging slowdown
- **Cherry Collection**: +100 score popup with fade animation (moves up 30 pixels over 1 second)
- **Wall Digging**: Brown particle effect (RGB: 0.8, 0.6, 0.4) with 0.5 second fade, size 50% of grid, alpha 0.8
- **Player Hit**: Red flash effect (RGB: 1.0, 0.0, 0.0, 0.5 alpha) with 0.3 second fade
- **Background**: Dark purple (RGB: 0.1, 0.05, 0.2)
- **Debug Output**: Console prints for player speed reset and enemy speed increases
- **Animation Timing**:
  - Wall digging effect: 0.5 second fade
  - Player hit effect: 0.3 second fade
  - Cherry collection: 1.0 second fade

## 🔊 Audio System

### Sound Effects
- **Cherry Collection**: High-pitched collection sound
- **Wall Digging**: Low rumble sound
- **Player Death**: Dramatic death sound
- **Game Start**: Upbeat start sound

### Audio Management
- Centralized audio control through AudioSystem
- Volume controls for different sound types
- **Sound Volumes**:
  - Cherry collection: 0.8 volume
  - Wall digging: 0.2 volume
  - Death sound: 0.9 volume
  - Start sound: 1.0 volume
- Background music support (future enhancement)

### UI Elements
- **Score Display**: Top-left corner (x: 75, y: height-20), 5-digit format, yellow color (RGB: 1.0, 0.8, 0.0), 10.5pt font
- **Lives Display**: Top-right corner (x: width-75, y: height-20), red color (RGB: 1.0, 0.3, 0.3), 10.5pt font
- **Game Over**: Center screen message, red color (RGB: 1.0, 0.0, 0.0), 36pt font, zPosition 1000
- **Level Complete**: Center screen message, green color (RGB: 0.0, 1.0, 0.0), 32pt font
- **Debug Label**: Yellow debug direction display (when debugMode = true), 18pt font, zPosition 1000
- **Font**: All UI uses "Courier-Bold" font family
- **Debug Format**: "DIR: {DIRECTION} | LAST: ({X},{Y})" with uppercased direction

## 🚀 Performance Features

### Grid-Based Optimization
- Efficient collision detection using grid positions
- Reduced computational complexity for movement
- Optimized pathfinding for enemy AI
- **Movement Chaining**: Player movement chains to next grid position to avoid pauses
- **Update Frequency**: Player updates every frame, enemies update every 0.1 seconds
- **Grid Snapping**: Objects snap to grid center with 2.0 pixel tolerance
- **Movement Validation**:
  - Objects must be at grid center before movement starts
  - Movement only occurs when no actions are currently running
  - Direction must be non-zero for movement to start
- **Intersection Detection**: Enemies detect intersections to make new movement decisions

### Memory Management
- Proper cleanup of game objects
- Efficient sprite management
- Timer-based updates for smooth performance
- **Object Cleanup**: All game objects removed from parent and collections cleared on level/game restart
- **Dug Tunnel Tracking**: Set<CGPoint> tracks all dug tunnel positions
- **Z-Position Management**: Enemies have slightly different z-positions to prevent overlap issues
- **Action Management**:
  - Player actions use key "playerMovement"
  - Enemy actions use key "enemyMovement"
  - Slowdown actions use key "diggingSlowdown"
  - Actions are removed and recreated when speed changes
- **UI Cleanup**: Level complete labels removed using `children.forEach` iteration
- **Memory Safety**: Uses `[weak self]` in closures to prevent retain cycles
- **Action State Checking**: `hasActions()` used to prevent overlapping movements

## 🔧 Development Notes

### Game Constants
- **Base Player Speed**: 150 points per second
- **Grid Size**: 32 (initial, recalculated based on screen size)
- **Debug Mode**: Enabled by default (set to false to disable debug features)
- **Enemy Update Cooldown**: 0.1 seconds
- **Player Slowdown Duration**: 0.5 seconds
- **Level Complete Delay**: 2.0 seconds
- **Game Over Delay**: 2.0 seconds
- **Player Hit Pause**: 1.0 second
- **Movement Timing**:
  - Player movement duration: `gridSize / currentPlayerSpeed`
  - Enemy movement duration: `gridSize / enemySpeed`
  - Linear timing mode for all movements
- **Position Tolerance**: 0.1 for grid position comparisons
- **Unused Variables**: `lastFrameTime` (declared but never used)
- **Helper Functions**:
  - `normalize(vector:)`: Normalizes CGVector to unit length
  - `directionToVector(direction:)`: Converts Direction enum to CGVector
  - `getOppositeDirection(direction:)`: Returns opposite direction (both Direction and CGPoint versions)
  - `findAlternativePath(for:)`: Alternative pathfinding for enemies (unused)

### SpriteKit Actions
- **Movement Actions**: `SKAction.move(to:duration:)` with linear timing mode
- **Timing Actions**: `SKAction.wait(forDuration:)` for delays and cooldowns
- **Visual Actions**: `SKAction.fadeOut(withDuration:)` for effects
- **Sequence Actions**: `SKAction.sequence([...])` for chaining actions
- **Group Actions**: `SKAction.group([...])` for parallel execution
- **Custom Actions**: `SKAction.run { }` for custom logic execution
- **Cleanup Actions**: `SKAction.removeFromParent()` for object removal
- **Action Management**: `removeAllActions()` for stopping movement, `hasActions()` for state checking

### Architecture Benefits
- **Modularity**: Each system has a single responsibility
- **Testability**: Systems can be tested independently
- **Maintainability**: Clear separation of concerns
- **Extensibility**: Easy to add new features

### Grid System Benefits
- **Predictable Movement**: All objects follow grid rules
- **Efficient Collision**: Grid-based collision detection
- **Consistent AI**: Enemies follow predictable patterns
- **Visual Clarity**: Clean, organized game layout

## 🎯 Future Enhancements

### Potential Features
- Power-ups and special abilities
- Multiple maze themes
- Advanced enemy AI patterns
- Multiplayer support
- Level editor
- Achievement system

### Technical Improvements
- Enhanced visual effects
- More sophisticated audio
- Performance optimizations
- Accessibility features

---

**Built with SpriteKit and Swift** | **Grid-based Architecture** | **Procedural Maze Generation**
