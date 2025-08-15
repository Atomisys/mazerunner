import SpriteKit

/// System responsible for managing all input handling in the game
/// Handles touch input, direction calculation, and input state management
final class InputManager {
    
    // MARK: - Input Types
    
    /// Types of input that can be processed
    enum InputType {
        case touch
        case swipe
        case tap
        case longPress
    }
    
    /// Input state for tracking continuous input
    enum InputState {
        case none
        case pressed
        case held
        case released
    }
    
    // MARK: - Properties
    
    private let scene: SKScene
    private let movementSystem: MovementSystem
    
    /// Current input state
    private var currentInputState: InputState = .none
    
    /// Last touch position
    private var lastTouchPosition: CGPoint?
    
    /// Touch start position for gesture recognition
    private var touchStartPosition: CGPoint?
    
    /// Touch start time for gesture recognition
    private var touchStartTime: TimeInterval?
    
    /// Minimum swipe distance to register as a swipe
    private var minSwipeDistance: CGFloat = 30.0
    
    /// Maximum time for a tap gesture
    private var maxTapTime: TimeInterval = 0.3
    
    /// Minimum time for a long press gesture
    private var minLongPressTime: TimeInterval = 0.5
    
    /// Current input direction
    private var currentDirection: Direction?
    
    /// Input callback closures
    private var onDirectionChanged: ((Direction?) -> Void)?
    private var onTap: ((CGPoint) -> Void)?
    private var onLongPress: ((CGPoint) -> Void)?
    private var onSwipe: ((Direction) -> Void)?
    
    // MARK: - Initialization
    
    /// Initialize the input manager
    /// - Parameters:
    ///   - scene: The game scene to handle input for
    ///   - movementSystem: The movement system to coordinate with
    init(scene: SKScene, movementSystem: MovementSystem) {
        self.scene = scene
        self.movementSystem = movementSystem
        setupInputHandling()
    }
    
    // MARK: - Input Setup
    
    /// Set up input handling for the scene
    private func setupInputHandling() {
        // Note: In a real implementation, you would set up touch handling here
        // For now, we'll provide the interface and methods that would be called
        // by the scene's touch handling methods
        print("InputManager: Input handling initialized")
    }
    
    // MARK: - Touch Handling
    
    /// Handle touch began event
    /// - Parameter position: Touch position in scene coordinates
    func handleTouchBegan(at position: CGPoint) {
        currentInputState = .pressed
        touchStartPosition = position
        touchStartTime = CACurrentMediaTime()
        lastTouchPosition = position
        
        print("InputManager: Touch began at \(position)")
    }
    
    /// Handle touch moved event
    /// - Parameter position: Touch position in scene coordinates
    func handleTouchMoved(to position: CGPoint) {
        guard let startPosition = touchStartPosition else { return }
        
        currentInputState = .held
        lastTouchPosition = position
        
        // Calculate direction from start position
        let direction = calculateDirection(from: startPosition, to: position)
        
        // Update current direction if it changed
        if direction != currentDirection {
            currentDirection = direction
            onDirectionChanged?(direction)
            
            // Update movement system
            movementSystem.handlePlayerInput(direction: direction)
            
            print("InputManager: Direction changed to \(direction?.rawValue ?? "none")")
        }
    }
    
    /// Handle touch ended event
    /// - Parameter position: Touch position in scene coordinates
    func handleTouchEnded(at position: CGPoint) {
        guard let startPosition = touchStartPosition,
              let startTime = touchStartTime else {
            currentInputState = .none
            return
        }
        
        let endTime = CACurrentMediaTime()
        let duration = endTime - startTime
        let distance = calculateDistance(from: startPosition, to: position)
        
        // Determine gesture type
        if distance < minSwipeDistance && duration < maxTapTime {
            // Tap gesture
            onTap?(position)
            print("InputManager: Tap detected at \(position)")
        } else if distance >= minSwipeDistance {
            // Swipe gesture
            let direction = calculateDirection(from: startPosition, to: position)
            if let direction = direction {
                onSwipe?(direction)
                print("InputManager: Swipe detected in direction \(direction.rawValue)")
            }
        } else if duration >= minLongPressTime {
            // Long press gesture
            onLongPress?(position)
            print("InputManager: Long press detected at \(position)")
        }
        
        // Reset input state
        currentInputState = .none
        currentDirection = nil
        onDirectionChanged?(nil)
        
        // Stop player movement
        movementSystem.handlePlayerInput(direction: nil)
        
        // Clear touch tracking
        touchStartPosition = nil
        touchStartTime = nil
        lastTouchPosition = nil
        
        print("InputManager: Touch ended")
    }
    
    /// Handle touch cancelled event
    func handleTouchCancelled() {
        currentInputState = .none
        currentDirection = nil
        onDirectionChanged?(nil)
        
        // Stop player movement
        movementSystem.handlePlayerInput(direction: nil)
        
        // Clear touch tracking
        touchStartPosition = nil
        touchStartTime = nil
        lastTouchPosition = nil
        
        print("InputManager: Touch cancelled")
    }
    
    // MARK: - Direction Calculation
    
    /// Calculate direction from one point to another
    /// - Parameters:
    ///   - from: Starting point
    ///   - to: Ending point
    /// - Returns: Calculated direction
    private func calculateDirection(from: CGPoint, to: CGPoint) -> Direction? {
        let deltaX = to.x - from.x
        let deltaY = to.y - from.y
        
        // Determine primary direction based on larger delta
        if abs(deltaX) > abs(deltaY) {
            // Horizontal movement
            return deltaX > 0 ? .right : .left
        } else {
            // Vertical movement
            return deltaY > 0 ? .up : .down
        }
    }
    
    /// Calculate distance between two points
    /// - Parameters:
    ///   - from: Starting point
    ///   - to: Ending point
    /// - Returns: Distance between points
    private func calculateDistance(from: CGPoint, to: CGPoint) -> CGFloat {
        let deltaX = to.x - from.x
        let deltaY = to.y - from.y
        return sqrt(deltaX * deltaX + deltaY * deltaY)
    }
    
    // MARK: - Input Validation
    
    /// Check if a position is within valid input bounds
    /// - Parameter position: Position to validate
    /// - Returns: True if position is valid for input
    private func isValidInputPosition(_ position: CGPoint) -> Bool {
        return position.x >= 0 && position.x <= scene.size.width &&
               position.y >= 0 && position.y <= scene.size.height
    }
    
    /// Check if input should be processed based on game state
    /// - Returns: True if input should be processed
    private func shouldProcessInput() -> Bool {
        // In a real implementation, you would check game state here
        // For example, don't process input if game is paused
        return true
    }
    
    // MARK: - Callback Registration
    
    /// Set callback for direction changes
    /// - Parameter callback: Closure to call when direction changes
    func onDirectionChanged(_ callback: @escaping (Direction?) -> Void) {
        onDirectionChanged = callback
    }
    
    /// Set callback for tap gestures
    /// - Parameter callback: Closure to call when tap is detected
    func onTap(_ callback: @escaping (CGPoint) -> Void) {
        onTap = callback
    }
    
    /// Set callback for long press gestures
    /// - Parameter callback: Closure to call when long press is detected
    func onLongPress(_ callback: @escaping (CGPoint) -> Void) {
        onLongPress = callback
    }
    
    /// Set callback for swipe gestures
    /// - Parameter callback: Closure to call when swipe is detected
    func onSwipe(_ callback: @escaping (Direction) -> Void) {
        onSwipe = callback
    }
    
    // MARK: - Input State Management
    
    /// Get current input state
    /// - Returns: Current input state
    func getCurrentInputState() -> InputState {
        return currentInputState
    }
    
    /// Get current direction
    /// - Returns: Current input direction
    func getCurrentDirection() -> Direction? {
        return currentDirection
    }
    
    /// Check if input is currently active
    /// - Returns: True if input is being processed
    func isInputActive() -> Bool {
        return currentInputState != .none
    }
    
    /// Reset input state
    func resetInput() {
        currentInputState = .none
        currentDirection = nil
        onDirectionChanged?(nil)
        
        // Stop player movement
        movementSystem.handlePlayerInput(direction: nil)
        
        // Clear touch tracking
        touchStartPosition = nil
        touchStartTime = nil
        lastTouchPosition = nil
        
        print("InputManager: Input reset")
    }
    
    // MARK: - Input Configuration
    
    /// Update minimum swipe distance
    /// - Parameter distance: New minimum swipe distance
    func setMinSwipeDistance(_ distance: CGFloat) {
        minSwipeDistance = distance
    }
    
    /// Update maximum tap time
    /// - Parameter time: New maximum tap time
    func setMaxTapTime(_ time: TimeInterval) {
        maxTapTime = time
    }
    
    /// Update minimum long press time
    /// - Parameter time: New minimum long press time
    func setMinLongPressTime(_ time: TimeInterval) {
        minLongPressTime = time
    }
    
    // MARK: - Debug Information
    
    /// Get debug information about current input state
    /// - Returns: Debug string with input information
    func getDebugInfo() -> String {
        return """
        InputManager Debug Info:
        - Input State: \(currentInputState)
        - Current Direction: \(currentDirection?.rawValue ?? "none")
        - Touch Start Position: \(touchStartPosition != nil ? "(\(touchStartPosition!.x), \(touchStartPosition!.y))" : "none")
        - Last Touch Position: \(lastTouchPosition != nil ? "(\(lastTouchPosition!.x), \(lastTouchPosition!.y))" : "none")
        - Touch Duration: \(touchStartTime != nil ? "\(CACurrentMediaTime() - touchStartTime!)" : "none")
        - Input Active: \(isInputActive())
        """
    }
    
    // MARK: - Public Interface
    
    /// Process input for the current frame
    /// This would be called each frame to handle continuous input
    func update() {
        // In a real implementation, you might handle continuous input here
        // For example, checking if a held touch should trigger a long press
        if currentInputState == .held,
           let startTime = touchStartTime {
            let currentTime = CACurrentMediaTime()
            let duration = currentTime - startTime
            
            if duration >= minLongPressTime {
                // Trigger long press if not already triggered
                if let position = lastTouchPosition {
                    onLongPress?(position)
                    print("InputManager: Long press triggered at \(position)")
                }
            }
        }
    }
    
    /// Enable or disable input processing
    /// - Parameter enabled: Whether input should be processed
    func setInputEnabled(_ enabled: Bool) {
        if !enabled {
            resetInput()
        }
        print("InputManager: Input \(enabled ? "enabled" : "disabled")")
    }
}
