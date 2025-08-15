import SpriteKit

final class GridSystem {
    
    // MARK: - Grid Configuration
    private var gridSize: CGFloat = 32
    private var gridWidth: Int = 0
    private var gridHeight: Int = 0
    private var gridOffset: CGFloat = 0  // Horizontal offset to center the grid
    private var gridYOffset: CGFloat = 0  // Vertical offset to center the grid
    
    // MARK: - Initialization
    init(sceneSize: CGSize, gridWidth: Int = 12, gridHeight: Int = 27) {
        self.gridWidth = gridWidth
        self.gridHeight = gridHeight
        
        // Calculate cell size to make them square
        let cellSize = min(sceneSize.width / CGFloat(gridWidth), sceneSize.height / CGFloat(gridHeight))
        
        // Calculate offsets to center the grid
        let totalGridWidth = CGFloat(gridWidth) * cellSize
        let totalGridHeight = CGFloat(gridHeight) * cellSize
        let extraWidth = sceneSize.width - totalGridWidth
        let extraHeight = sceneSize.height - totalGridHeight
        
        self.gridOffset = extraWidth / 2
        self.gridYOffset = extraHeight / 2
        
        // Update gridSize to use the calculated cell size
        self.gridSize = cellSize
    }
    
    // MARK: - Grid Properties
    var cellSize: CGFloat { gridSize }
    var width: Int { gridWidth }
    var height: Int { gridHeight }
    var horizontalOffset: CGFloat { gridOffset }
    var verticalOffset: CGFloat { gridYOffset }
    
    // MARK: - Position Conversion
    
    /// Convert world position to grid coordinates
    /// - Parameter worldPosition: Position in world coordinates
    /// - Returns: Grid position (x, y) where (0,0) is top-left
    func getGridPosition(_ worldPosition: CGPoint) -> CGPoint {
        // Convert world position to grid coordinates
        // Invert Y coordinate so row 0 is at the top
        let gridX = round((worldPosition.x - gridSize/2 - gridOffset) / gridSize)
        let gridY = CGFloat(gridHeight - 1) - round((worldPosition.y - gridSize/2 - gridYOffset) / gridSize)
        return CGPoint(x: gridX, y: gridY)
    }
    
    /// Convert grid coordinates to world position (centered)
    /// - Parameter gridPosition: Grid position (x, y) where (0,0) is top-left
    /// - Returns: World position centered in the grid cell
    func getWorldPosition(_ gridPosition: CGPoint) -> CGPoint {
        // Convert grid coordinates to world position (centered)
        // Invert Y coordinate so row 0 is at the top (for dynamic island)
        let worldX = gridPosition.x * gridSize + gridSize/2 + gridOffset
        let worldY = (CGFloat(gridHeight - 1) - gridPosition.y) * gridSize + gridSize/2 + gridYOffset
        return CGPoint(x: worldX, y: worldY)
    }
    
    // MARK: - Grid Validation
    
    /// Check if a position is at the center of a grid cell
    /// - Parameter worldPosition: Position in world coordinates
    /// - Returns: True if the position is centered on a grid cell
    func isAtGridCenter(_ worldPosition: CGPoint) -> Bool {
        let gridPos = getGridPosition(worldPosition)
        let expectedWorldPos = getWorldPosition(gridPos)
        let tolerance: CGFloat = 2.0
        
        return abs(worldPosition.x - expectedWorldPos.x) < tolerance &&
               abs(worldPosition.y - expectedWorldPos.y) < tolerance
    }
    
    /// Check if a grid position is within valid bounds
    /// - Parameter gridPosition: Grid position to validate
    /// - Returns: True if the position is within the grid bounds
    func isValidGridPosition(_ gridPosition: CGPoint) -> Bool {
        return gridPosition.x >= 0 && gridPosition.x < CGFloat(gridWidth) &&
               gridPosition.y >= 0 && gridPosition.y < CGFloat(gridHeight)
    }
    
    /// Check if a world position is within valid bounds
    /// - Parameter worldPosition: World position to validate
    /// - Returns: True if the position is within the scene bounds
    func isValidWorldPosition(_ worldPosition: CGPoint) -> Bool {
        return worldPosition.x >= gridSize && worldPosition.x < (CGFloat(gridWidth) * gridSize + gridOffset) &&
               worldPosition.y >= gridSize && worldPosition.y < (CGFloat(gridHeight) * gridSize + gridYOffset)
    }
    
    // MARK: - Grid-Based Collision Detection
    
    /// Check if two grid positions are the same
    /// - Parameters:
    ///   - position1: First grid position
    ///   - position2: Second grid position
    /// - Returns: True if the positions are the same grid cell
    func isSameGridPosition(_ position1: CGPoint, _ position2: CGPoint) -> Bool {
        return abs(position1.x - position2.x) < 0.1 && abs(position1.y - position2.y) < 0.1
    }
    
    /// Check if two world positions are in the same grid cell
    /// - Parameters:
    ///   - worldPos1: First world position
    ///   - worldPos2: Second world position
    /// - Returns: True if both positions are in the same grid cell
    func isSameGridCell(_ worldPos1: CGPoint, _ worldPos2: CGPoint) -> Bool {
        let gridPos1 = getGridPosition(worldPos1)
        let gridPos2 = getGridPosition(worldPos2)
        return isSameGridPosition(gridPos1, gridPos2)
    }
    
    /// Calculate grid distance between two positions
    /// - Parameters:
    ///   - gridPos1: First grid position
    ///   - gridPos2: Second grid position
    /// - Returns: Manhattan distance in grid cells
    func gridDistance(from gridPos1: CGPoint, to gridPos2: CGPoint) -> CGFloat {
        return abs(gridPos1.x - gridPos2.x) + abs(gridPos1.y - gridPos2.y)
    }
    
    /// Calculate Euclidean distance between two grid positions
    /// - Parameters:
    ///   - gridPos1: First grid position
    ///   - gridPos2: Second grid position
    /// - Returns: Euclidean distance in grid cells
    func euclideanGridDistance(from gridPos1: CGPoint, to gridPos2: CGPoint) -> CGFloat {
        let deltaX = gridPos1.x - gridPos2.x
        let deltaY = gridPos1.y - gridPos2.y
        return sqrt(deltaX * deltaX + deltaY * deltaY)
    }
    
    // MARK: - Grid Utilities
    
    /// Get all adjacent grid positions (up, down, left, right)
    /// - Parameter gridPosition: Center grid position
    /// - Returns: Array of valid adjacent grid positions
    func getAdjacentGridPositions(_ gridPosition: CGPoint) -> [CGPoint] {
        let directions = [
            CGPoint(x: 0, y: 1),   // Up
            CGPoint(x: 0, y: -1),  // Down
            CGPoint(x: -1, y: 0),  // Left
            CGPoint(x: 1, y: 0)    // Right
        ]
        
        var adjacentPositions: [CGPoint] = []
        
        for direction in directions {
            let adjacentPos = CGPoint(
                x: gridPosition.x + direction.x,
                y: gridPosition.y + direction.y
            )
            
            if isValidGridPosition(adjacentPos) {
                adjacentPositions.append(adjacentPos)
            }
        }
        
        return adjacentPositions
    }
    
    /// Get grid position in a specific direction
    /// - Parameters:
    ///   - from: Starting grid position
    ///   - direction: Direction vector (should be normalized)
    /// - Returns: Grid position in the specified direction, or nil if invalid
    func getGridPosition(in direction: CGVector, from gridPosition: CGPoint) -> CGPoint? {
        let targetPos = CGPoint(
            x: gridPosition.x + direction.dx,
            y: gridPosition.y + direction.dy
        )
        
        return isValidGridPosition(targetPos) ? targetPos : nil
    }
    
    /// Snap a world position to the nearest grid center
    /// - Parameter worldPosition: World position to snap
    /// - Returns: World position snapped to grid center
    func snapToGridCenter(_ worldPosition: CGPoint) -> CGPoint {
        let gridPos = getGridPosition(worldPosition)
        return getWorldPosition(gridPos)
    }
}
