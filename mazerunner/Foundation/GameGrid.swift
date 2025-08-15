import SpriteKit

// MARK: - Grid Cell Types
enum GridCellType {
    case empty
    case wall
    case borderWall
    case player
    case enemy
    case cherry
    case dugTunnel
}

// MARK: - Grid Cell Data
struct GridCell {
    var type: GridCellType
    var object: Any? // Reference to the actual game object (Player, Enemy, etc.)
    
    init(type: GridCellType = .empty, object: Any? = nil) {
        self.type = type
        self.object = object
    }
}

final class GameGrid {
    
    // MARK: - Properties
    private let gridSystem: GridSystem
    private var grid: [[GridCell]]
    private let width: Int
    private let height: Int
    
    // MARK: - Initialization
    init(gridSystem: GridSystem) {
        self.gridSystem = gridSystem
        self.width = gridSystem.width
        self.height = gridSystem.height
        
        // Initialize grid with empty cells
        self.grid = Array(repeating: Array(repeating: GridCell(), count: width), count: height)
    }
    
    // MARK: - Grid Access
    
    /// Get the cell at the specified grid position
    /// - Parameter gridPosition: Grid coordinates
    /// - Returns: GridCell at the position, or nil if out of bounds
    func getCell(at gridPosition: CGPoint) -> GridCell? {
        guard isValidGridPosition(gridPosition) else { return nil }
        let x = Int(gridPosition.x)
        let y = Int(gridPosition.y)
        return grid[y][x]
    }
    
    /// Set the cell at the specified grid position
    /// - Parameters:
    ///   - gridPosition: Grid coordinates
    ///   - cell: Cell data to set
    /// - Returns: True if successful, false if out of bounds
    @discardableResult
    func setCell(at gridPosition: CGPoint, to cell: GridCell) -> Bool {
        guard isValidGridPosition(gridPosition) else { return false }
        let x = Int(gridPosition.x)
        let y = Int(gridPosition.y)
        grid[y][x] = cell
        return true
    }
    
    /// Get the cell type at the specified grid position
    /// - Parameter gridPosition: Grid coordinates
    /// - Returns: Cell type, or .empty if out of bounds
    func getCellType(at gridPosition: CGPoint) -> GridCellType {
        guard let cell = getCell(at: gridPosition) else { return .empty }
        return cell.type
    }
    
    /// Set the cell type at the specified grid position
    /// - Parameters:
    ///   - gridPosition: Grid coordinates
    ///   - type: New cell type
    /// - Returns: True if successful, false if out of bounds
    @discardableResult
    func setCellType(at gridPosition: CGPoint, to type: GridCellType) -> Bool {
        guard isValidGridPosition(gridPosition) else { return false }
        let x = Int(gridPosition.x)
        let y = Int(gridPosition.y)
        grid[y][x].type = type
        return true
    }
    
    // MARK: - Grid State Queries
    
    /// Check if a grid position is empty
    /// - Parameter gridPosition: Grid coordinates
    /// - Returns: True if the cell is empty
    func isEmpty(at gridPosition: CGPoint) -> Bool {
        return getCellType(at: gridPosition) == .empty
    }
    
    /// Check if a grid position contains a wall
    /// - Parameter gridPosition: Grid coordinates
    /// - Returns: True if the cell contains a wall
    func isWall(at gridPosition: CGPoint) -> Bool {
        let cellType = getCellType(at: gridPosition)
        return cellType == .wall || cellType == .borderWall
    }
    
    /// Check if a grid position contains a diggable wall (not border)
    /// - Parameter gridPosition: Grid coordinates
    /// - Returns: True if the cell contains a diggable wall
    func isDiggableWall(at gridPosition: CGPoint) -> Bool {
        return getCellType(at: gridPosition) == .wall
    }
    
    /// Check if a grid position contains a border wall
    /// - Parameter gridPosition: Grid coordinates
    /// - Returns: True if the cell contains a border wall
    func isBorderWall(at gridPosition: CGPoint) -> Bool {
        return getCellType(at: gridPosition) == .borderWall
    }
    
    /// Check if a grid position contains the player
    /// - Parameter gridPosition: Grid coordinates
    /// - Returns: True if the cell contains the player
    func isPlayer(at gridPosition: CGPoint) -> Bool {
        return getCellType(at: gridPosition) == .player
    }
    
    /// Check if a grid position contains an enemy
    /// - Parameter gridPosition: Grid coordinates
    /// - Returns: True if the cell contains an enemy
    func isEnemy(at gridPosition: CGPoint) -> Bool {
        return getCellType(at: gridPosition) == .enemy
    }
    
    /// Check if a grid position contains a cherry
    /// - Parameter gridPosition: Grid coordinates
    /// - Returns: True if the cell contains a cherry
    func isCherry(at gridPosition: CGPoint) -> Bool {
        return getCellType(at: gridPosition) == .cherry
    }
    
    /// Check if a grid position is a dug tunnel
    /// - Parameter gridPosition: Grid coordinates
    /// - Returns: True if the cell is a dug tunnel
    func isDugTunnel(at gridPosition: CGPoint) -> Bool {
        return getCellType(at: gridPosition) == .dugTunnel
    }
    
    // MARK: - Object Management
    
    /// Place an object at a grid position
    /// - Parameters:
    ///   - gridPosition: Grid coordinates
    ///   - type: Type of object to place
    ///   - object: Reference to the actual game object
    /// - Returns: True if successful, false if position is occupied
    @discardableResult
    func placeObject(at gridPosition: CGPoint, type: GridCellType, object: Any?) -> Bool {
        guard isEmpty(at: gridPosition) else { return false }
        return setCell(at: gridPosition, to: GridCell(type: type, object: object))
    }
    
    /// Remove an object from a grid position
    /// - Parameter gridPosition: Grid coordinates
    /// - Returns: The removed object, or nil if position was empty
    @discardableResult
    func removeObject(at gridPosition: CGPoint) -> Any? {
        guard let cell = getCell(at: gridPosition), cell.type != .empty else { return nil }
        let removedObject = cell.object
        setCell(at: gridPosition, to: GridCell())
        return removedObject
    }
    
    /// Move an object from one position to another
    /// - Parameters:
    ///   - from: Source grid position
    ///   - to: Destination grid position
    /// - Returns: True if successful, false if source is empty or destination is occupied
    @discardableResult
    func moveObject(from: CGPoint, to: CGPoint) -> Bool {
        guard let sourceCell = getCell(at: from), sourceCell.type != .empty else { return false }
        guard isEmpty(at: to) else { return false }
        
        // Remove from source
        setCell(at: from, to: GridCell())
        
        // Place at destination
        setCell(at: to, to: sourceCell)
        
        return true
    }
    
    /// Get all positions of a specific cell type
    /// - Parameter type: Cell type to search for
    /// - Returns: Array of grid positions containing the specified type
    func getAllPositions(of type: GridCellType) -> [CGPoint] {
        var positions: [CGPoint] = []
        
        for y in 0..<height {
            for x in 0..<width {
                let position = CGPoint(x: CGFloat(x), y: CGFloat(y))
                if getCellType(at: position) == type {
                    positions.append(position)
                }
            }
        }
        
        return positions
    }
    
    /// Count cells of a specific type
    /// - Parameter type: Cell type to count
    /// - Returns: Number of cells of the specified type
    func countCells(of type: GridCellType) -> Int {
        return getAllPositions(of: type).count
    }
    
    // MARK: - Grid-Based Pathfinding
    
    /// Get all valid adjacent positions (no walls)
    /// - Parameter gridPosition: Center grid position
    /// - Returns: Array of valid adjacent grid positions
    func getValidAdjacentPositions(_ gridPosition: CGPoint) -> [CGPoint] {
        let allAdjacent = gridSystem.getAdjacentGridPositions(gridPosition)
        return allAdjacent.filter { isEmpty(at: $0) }
    }
    
    /// Check if a path exists between two positions using simple line of sight
    /// - Parameters:
    ///   - from: Starting position
    ///   - to: Target position
    /// - Returns: True if there's a clear path (no walls)
    func hasLineOfSight(from: CGPoint, to: CGPoint) -> Bool {
        // Simple line of sight check - can be enhanced with proper pathfinding
        let positions = getPositionsBetween(from: from, to: to)
        
        for position in positions {
            if isWall(at: position) {
                return false
            }
        }
        
        return true
    }
    
    /// Get all positions between two points (Bresenham's line algorithm)
    /// - Parameters:
    ///   - from: Starting position
    ///   - to: Ending position
    /// - Returns: Array of grid positions between the two points
    private func getPositionsBetween(from: CGPoint, to: CGPoint) -> [CGPoint] {
        var positions: [CGPoint] = []
        
        let x0 = Int(from.x)
        let y0 = Int(from.y)
        let x1 = Int(to.x)
        let y1 = Int(to.y)
        
        let dx = abs(x1 - x0)
        let dy = abs(y1 - y0)
        let sx = x0 < x1 ? 1 : -1
        let sy = y0 < y1 ? 1 : -1
        var err = dx - dy
        
        var x = x0
        var y = y0
        
        while true {
            positions.append(CGPoint(x: CGFloat(x), y: CGFloat(y)))
            
            if x == x1 && y == y1 { break }
            
            let e2 = 2 * err
            if e2 > -dy {
                err -= dy
                x += sx
            }
            if e2 < dx {
                err += dx
                y += sy
            }
        }
        
        return positions
    }
    
    // MARK: - Grid Validation
    
    /// Check if a grid position is within bounds
    /// - Parameter gridPosition: Grid position to validate
    /// - Returns: True if the position is within the grid bounds
    private func isValidGridPosition(_ gridPosition: CGPoint) -> Bool {
        return gridSystem.isValidGridPosition(gridPosition)
    }
    
    // MARK: - Grid Utilities
    
    /// Clear the entire grid (set all cells to empty)
    func clear() {
        for y in 0..<height {
            for x in 0..<width {
                grid[y][x] = GridCell()
            }
        }
    }
    
    /// Get a string representation of the grid for debugging
    /// - Returns: String showing the grid layout
    func debugString() -> String {
        var result = ""
        
        for y in (0..<height).reversed() { // Print from top to bottom
            for x in 0..<width {
                let cellType = grid[y][x].type
                switch cellType {
                case .empty:
                    result += "."
                case .wall:
                    result += "W"
                case .borderWall:
                    result += "B"
                case .player:
                    result += "P"
                case .enemy:
                    result += "E"
                case .cherry:
                    result += "C"
                case .dugTunnel:
                    result += "T"
                }
            }
            result += "\n"
        }
        
        return result
    }
}
