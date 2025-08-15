# MazeRunner Refactoring Plan: Grid-Based Architecture

## Overview

This document outlines the strategy for decoupling the monolithic `GameScene.swift` (1300+ lines) into a clean, maintainable grid-based architecture. The goal is to separate concerns, improve testability, and create a more extensible codebase.

## Current State Analysis

### GameScene.swift Responsibilities (Monolithic)
- Game State Management (score, lives, cherries, game states)
- Grid System (position conversion between grid and world coordinates)
- Object Management (player, enemies, cherries, walls, border walls)
- Movement Logic (player and enemy movement with grid-based constraints)
- Collision Detection (cherry collection and enemy collisions)
- UI Management (score, lives, debug labels)
- Audio Management (sound effects)
- Maze Generation (wall placement and digging mechanics)
- Visual Effects (particle effects, color changes)

### Existing Good Structure
- `Enemy.swift` - Basic enemy class with directional sprites
- `Direction.swift` - Direction enum
- `Maze.swift` - Maze generation algorithm
- `SoundPlayer.swift` - Audio management

## Proposed Architecture

### 1. Core Architecture: Grid-Based Game Engine

#### `GridSystem.swift`
- Grid dimensions and configuration
- Position conversion utilities (`getGridPosition`, `getWorldPosition`)
- Grid validation and boundary checking
- Grid-based collision detection

#### `GameGrid.swift`
- Represents the game world as a 2D grid
- Tracks what's in each grid cell (walls, enemies, player, cherries, empty)
- Provides methods to query and modify grid state
- Handles grid-based pathfinding

### 2. Game Objects with Grid Positions

#### `GameObject.swift` (Protocol)
```swift
protocol GameObject {
    var gridPosition: CGPoint { get set }
    var sprite: SKSpriteNode { get }
    func updatePosition()
}
```

#### `Player.swift`
- Player-specific logic and state
- Movement input handling
- Grid position tracking
- Visual representation

#### `Enemy.swift` (Enhanced)
- AI movement logic
- Grid-based pathfinding
- Directional sprites management
- Current implementation is good but needs grid integration

#### `Cherry.swift`
- Cherry-specific behavior
- Collection logic
- Visual effects

#### `Wall.swift`
- Wall types (regular vs border)
- Digging mechanics
- Visual representation

### 3. Game State Management

#### `GameState.swift`
- Game state enum (playing, paused, gameOver, levelComplete)
- Score, lives, cherries tracking
- Level progression

#### `GameManager.swift`
- Coordinates between different systems
- Handles game flow (start, pause, restart, level complete)
- Manages object lifecycle

### 4. Systems Architecture

#### `MovementSystem.swift`
- Grid-based movement logic
- Pathfinding for enemies
- Movement validation and constraints

#### `CollisionSystem.swift`
- Grid-based collision detection
- Cherry collection
- Enemy-player collisions

#### `AudioSystem.swift`
- Centralized audio management
- Sound effect coordination

#### `UISystem.swift`
- Score and lives display
- Debug information
- Game over/level complete messages

#### `VisualEffectsSystem.swift`
- Particle effects
- Color changes
- Animation coordination

### 5. Maze and Level Management

#### `MazeGenerator.swift` (Enhanced from current `Maze.swift`)
- Maze generation algorithms
- Level-specific configurations
- Wall placement logic

#### `LevelManager.swift`
- Level progression
- Difficulty scaling
- Level-specific setups

### 6. Input Management

#### `InputManager.swift`
- Touch handling
- Direction calculation
- Input state management

## Implementation Phases

### Phase 1: Foundation (Week 1)
**Goal**: Create the core grid system and basic infrastructure

#### Tasks:
1. Create `GridSystem.swift`
   - Extract position conversion utilities from GameScene
   - Implement grid validation and boundary checking
   - Add grid-based collision detection helpers

2. Create `GameGrid.swift`
   - Implement 2D grid representation
   - Add methods to query and modify grid state
   - Create grid-based pathfinding utilities

3. Create `GameObject.swift` protocol
   - Define base interface for all game objects
   - Add grid position tracking
   - Include sprite management

4. Create `GameState.swift`
   - Extract game state enum and related data
   - Add score, lives, cherries tracking
   - Implement level progression logic

#### Deliverables:
- `GridSystem.swift`
- `GameGrid.swift`
- `GameObject.swift`
- `GameState.swift`

### Phase 2: Core Objects (Week 2)
**Goal**: Refactor existing objects to use grid positions

#### Tasks:
1. Refactor `Player.swift`
   - Extract player logic from GameScene
   - Implement grid position tracking
   - Add movement input handling
   - Maintain visual representation

2. Enhance `Enemy.swift`
   - Add grid integration
   - Implement grid-based movement
   - Maintain directional sprites
   - Add AI pathfinding

3. Create `Cherry.swift`
   - Extract cherry logic from GameScene
   - Implement collection behavior
   - Add visual effects

4. Create `Wall.swift`
   - Extract wall logic from GameScene
   - Implement wall types (regular vs border)
   - Add digging mechanics

5. Create `GameManager.swift`
   - Coordinate between different systems
   - Handle game flow
   - Manage object lifecycle

#### Deliverables:
- `Player.swift`
- Enhanced `Enemy.swift`
- `Cherry.swift`
- `Wall.swift`
- `GameManager.swift`

### Phase 3: Systems (Week 3)
**Goal**: Create focused systems for different game aspects

#### Tasks:
1. Create `MovementSystem.swift`
   - Extract movement logic from GameScene
   - Implement grid-based movement
   - Add pathfinding for enemies
   - Handle movement validation

2. Create `CollisionSystem.swift`
   - Extract collision detection from GameScene
   - Implement grid-based collisions
   - Handle cherry collection
   - Manage enemy-player collisions

3. Create `AudioSystem.swift`
   - Centralize audio management
   - Coordinate sound effects
   - Replace direct SoundPlayer usage

4. Create `UISystem.swift`
   - Extract UI logic from GameScene
   - Manage score and lives display
   - Handle debug information
   - Manage game messages

5. Create `InputManager.swift`
   - Extract input handling from GameScene
   - Implement touch handling
   - Add direction calculation
   - Manage input state

#### Deliverables:
- `MovementSystem.swift`
- `CollisionSystem.swift`
- `AudioSystem.swift`
- `UISystem.swift`
- `InputManager.swift`

### Phase 4: Integration and Polish (Week 4)
**Goal**: Integrate all systems and clean up GameScene

#### Tasks:
1. Update `GameScene.swift`
   - Remove monolithic code
   - Use new systems and objects
   - Maintain scene lifecycle
   - Keep rendering responsibilities

2. Create `VisualEffectsSystem.swift`
   - Extract visual effects from GameScene
   - Manage particle effects
   - Handle color changes
   - Coordinate animations

3. Create `LevelManager.swift`
   - Extract level management from GameScene
   - Handle level progression
   - Manage difficulty scaling
   - Coordinate level-specific setups

4. Enhance `MazeGenerator.swift`
   - Improve maze generation
   - Add level-specific configurations
   - Enhance wall placement logic

5. Final integration and testing
   - Ensure all systems work together
   - Fix any integration issues
   - Performance optimization
   - Final testing and bug fixes

#### Deliverables:
- Refactored `GameScene.swift`
- `VisualEffectsSystem.swift`
- `LevelManager.swift`
- Enhanced `MazeGenerator.swift`
- Performance benchmarks

## Design Principles

### 1. Grid as Source of Truth
- All game logic operates on grid coordinates
- Screen positions are calculated only for rendering
- Grid-based operations are more efficient than sprite-based collision detection

### 2. Systems over Monoliths
- Break functionality into focused systems
- Each system has a single responsibility
- Systems communicate through well-defined interfaces

### 3. Dependency Injection
- Systems receive dependencies rather than creating them
- Reduces coupling between components
- Improves testability

### 4. Event-Driven Architecture
- Systems communicate through events rather than direct coupling
- Loose coupling between components
- Easy to add new features

### 5. Data-Driven Design
- Game objects are primarily data with behavior attached
- Easy to serialize and modify
- Clear separation of data and logic

## Benefits

### 1. Maintainability
- Changes to one system don't affect others
- Clear separation of concerns
- Easier to understand and modify

### 2. Testability
- Systems can be tested through gameplay
- Clear interfaces make manual testing easier
- Better code organization improves debugging

### 3. Extensibility
- Easy to add new game objects
- Simple to add new systems
- Clear extension points

### 4. Performance
- Grid-based operations are more efficient
- Reduced collision detection overhead
- Better memory management

### 5. Code Quality
- Reduced complexity in individual files
- Better adherence to SOLID principles
- Improved code organization

## Risk Mitigation

### 1. Incremental Implementation
- Implement phases one at a time
- Test thoroughly after each phase
- Maintain working game throughout refactoring

### 2. Backward Compatibility
- Keep existing functionality working
- Gradual migration of features
- Fallback to old code if needed

### 3. Testing Strategy
- Manual testing for game feel and functionality
- Integration testing through gameplay
- Performance testing and optimization

### 4. Documentation
- Document each system's responsibilities
- Maintain clear interfaces
- Update this plan as needed

## Success Criteria

### Phase 1 Success
- Grid system works correctly
- Position conversions are accurate
- Basic game objects can be created
- Game compiles and runs without errors

### Phase 2 Success
- Player and enemies move correctly on grid
- All game objects track grid positions
- Game manager coordinates systems
- All game functionality works as expected

### Phase 3 Success
- All systems work independently
- Systems communicate correctly
- Game functionality is preserved
- Performance is maintained or improved

### Phase 4 Success
- GameScene is significantly smaller and cleaner
- All functionality works as before
- Performance is maintained or improved
- Code is more maintainable and organized
- Ready for future unit testing implementation

## Timeline

- **Week 1**: Phase 1 - Foundation
- **Week 2**: Phase 2 - Core Objects
- **Week 3**: Phase 3 - Systems
- **Week 4**: Phase 4 - Integration and Polish

Total estimated time: 4 weeks

## Notes

- This plan is flexible and can be adjusted based on progress
- Each phase should be completed and tested before moving to the next
- Regular code reviews should be conducted throughout the process
- Performance should be monitored throughout the refactoring

## Testing Strategy Note

**Intentional Decision**: Unit tests and integration tests are intentionally excluded from this refactoring plan to avoid the overhead of constantly rewriting tests as the architecture evolves. Instead, we focus on:

- **Manual Testing**: Thorough gameplay testing to ensure functionality works correctly
- **Compilation Testing**: Ensuring the game compiles and runs without errors
- **Performance Testing**: Monitoring performance throughout the refactoring
- **Future Testing**: The clean architecture will make it easy to add comprehensive unit tests after the refactoring is complete

This approach allows us to move faster through the refactoring while still maintaining quality through direct validation of the game's behavior.

## Performance Testing Methodology

### Baseline Measurement
- **Before Refactoring**: Establish performance baseline on current GameScene implementation
- **Metrics to Track**:
  - Frame rate (target: 60 FPS)
  - Memory usage during gameplay
  - CPU usage during intensive moments (many enemies, lots of movement)
  - Battery drain on mobile devices

### Testing Scenarios
1. **Normal Gameplay**: Player moving around, collecting cherries, avoiding enemies
2. **High Activity**: Multiple enemies moving simultaneously, player digging walls
3. **Stress Test**: Maximum number of objects on screen, rapid input
4. **Long Session**: Extended gameplay to check for memory leaks

### Performance Monitoring Tools
- **Xcode Instruments**: Profile CPU, memory, and frame rate
- **SpriteKit Debug**: Use SKView's debug options to monitor rendering
- **Manual Observation**: Visual assessment of smoothness and responsiveness
- **Device Testing**: Test on actual iOS devices, not just simulator

### Performance Checkpoints
- **After Each Phase**: Compare performance to baseline
- **Acceptable Degradation**: Up to 5% performance loss is acceptable during refactoring
- **Performance Regression**: If performance drops more than 10%, investigate and optimize
- **Final Goal**: Match or exceed original performance with cleaner architecture

### Optimization Strategies
- **Grid-Based Collision**: Should improve performance over sprite-based collision detection
- **Efficient Pathfinding**: Optimize enemy AI to reduce CPU usage
- **Memory Management**: Ensure proper cleanup of game objects
- **Rendering Optimization**: Minimize unnecessary sprite updates

## Project Directory Structure

### Proposed Organization
```
mazerunner/
├── Foundation/           # Phase 1 files
│   ├── GridSystem.swift
│   ├── GameGrid.swift
│   ├── GameObject.swift
│   └── GameState.swift
├── Core/                 # Phase 2 files (when we create them)
│   ├── Player.swift
│   ├── Enemy.swift (enhanced)
│   ├── Cherry.swift
│   ├── Wall.swift
│   └── GameManager.swift
├── Systems/              # Phase 3 files (when we create them)
│   ├── MovementSystem.swift
│   ├── CollisionSystem.swift
│   ├── AudioSystem.swift
│   ├── UISystem.swift
│   └── InputManager.swift
├── Managers/             # Phase 4 files (when we create them)
│   ├── LevelManager.swift
│   ├── VisualEffectsSystem.swift
│   └── MazeGenerator.swift (enhanced)
├── Legacy/               # Original files (to be cleaned up)
│   ├── GameScene.swift (original)
│   ├── Enemy.swift (original)
│   └── SoundPlayer.swift
├── Resources/            # Assets
│   ├── *.mp3
│   ├── *.png
│   └── *.sks
└── UI/                   # UI-related files
    ├── GameViewController.swift
    ├── AppDelegate.swift
    └── Base.lproj/
```

### Benefits of this organization:
1. **Clear Separation**: Each phase has its own directory
2. **Easy Navigation**: Developers can quickly find related files
3. **Scalability**: Easy to add new files to appropriate directories
4. **Legacy Tracking**: Original files are preserved until fully replaced
5. **Logical Grouping**: Related functionality is grouped together

### Implementation Notes:
- Files will be moved to appropriate directories as each phase is completed
- Legacy files will be moved to Legacy/ directory when replaced
- Xcode project will be updated to reflect new structure
- Import statements may need updating when files are moved

## Progress Tracking

### Phase 1: Foundation (Week 1)
- [x] Create `GridSystem.swift`
  - [x] Extract position conversion utilities from GameScene
  - [x] Implement grid validation and boundary checking
  - [x] Add grid-based collision detection helpers
- [x] Create `GameGrid.swift`
  - [x] Implement 2D grid representation
  - [x] Add methods to query and modify grid state
  - [x] Create grid-based pathfinding utilities
- [x] Create `GameObject.swift` protocol
  - [x] Define base interface for all game objects
  - [x] Add grid position tracking
  - [x] Include sprite management
- [x] Create `GameState.swift`
  - [x] Extract game state enum and related data
  - [x] Add score, lives, cherries tracking
  - [x] Implement level progression logic

### Phase 2: Core Objects (Week 2)
- [x] Refactor `Player.swift`
  - [x] Extract player logic from GameScene
  - [x] Implement grid position tracking
  - [x] Add movement input handling
  - [x] Maintain visual representation
- [x] Enhance `Enemy.swift`
  - [x] Add grid integration
  - [x] Implement grid-based movement
  - [x] Maintain directional sprites
  - [x] Add AI pathfinding
- [x] Create `Cherry.swift`
  - [x] Extract cherry logic from GameScene
  - [x] Implement collection behavior
  - [x] Add visual effects
- [x] Create `Wall.swift`
  - [x] Extract wall logic from GameScene
  - [x] Implement wall types (regular vs border)
  - [x] Add digging mechanics
- [x] Create `GameManager.swift`
  - [x] Coordinate between different systems
  - [x] Handle game flow
  - [x] Manage object lifecycle

### Phase 3: Systems (Week 3)
- [ ] Create `MovementSystem.swift`
  - [ ] Extract movement logic from GameScene
  - [ ] Implement grid-based movement
  - [ ] Add pathfinding for enemies
  - [ ] Handle movement validation
- [ ] Create `CollisionSystem.swift`
  - [ ] Extract collision detection from GameScene
  - [ ] Implement grid-based collisions
  - [ ] Handle cherry collection
  - [ ] Manage enemy-player collisions
- [ ] Create `AudioSystem.swift`
  - [ ] Centralize audio management
  - [ ] Coordinate sound effects
  - [ ] Replace direct SoundPlayer usage
- [ ] Create `UISystem.swift`
  - [ ] Extract UI logic from GameScene
  - [ ] Manage score and lives display
  - [ ] Handle debug information
  - [ ] Manage game messages
- [ ] Create `InputManager.swift`
  - [ ] Extract input handling from GameScene
  - [ ] Implement touch handling
  - [ ] Add direction calculation
  - [ ] Manage input state

### Phase 4: Integration and Polish (Week 4)
- [ ] Update `GameScene.swift`
  - [ ] Remove monolithic code
  - [ ] Use new systems and objects
  - [ ] Maintain scene lifecycle
  - [ ] Keep rendering responsibilities
- [ ] Create `VisualEffectsSystem.swift`
  - [ ] Extract visual effects from GameScene
  - [ ] Manage particle effects
  - [ ] Handle color changes
  - [ ] Coordinate animations
- [ ] Create `LevelManager.swift`
  - [ ] Extract level management from GameScene
  - [ ] Handle level progression
  - [ ] Manage difficulty scaling
  - [ ] Coordinate level-specific setups
- [ ] Enhance `MazeGenerator.swift`
  - [ ] Improve maze generation
  - [ ] Add level-specific configurations
  - [ ] Enhance wall placement logic
- [ ] Final integration and testing
  - [ ] Ensure all systems work together
  - [ ] Fix any integration issues
  - [ ] Performance optimization
  - [ ] Final testing and bug fixes

### Overall Progress
- [ ] Phase 1 Complete
- [ ] Phase 2 Complete
- [ ] Phase 3 Complete
- [ ] Phase 4 Complete
- [ ] **REFACTORING COMPLETE**
