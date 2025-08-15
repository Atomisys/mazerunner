import Foundation

enum Maze {
    // Returns a 2D array [rows][cols] of Bool where true = wall, false = open path
    // Dimensions: cols = 10 (game columns 1..10), rows = 22 (mapped to world rows 3..24)
    static func generate(cols: Int = 10, rows: Int = 22) -> [[Bool]] {
        precondition(cols > 0 && rows > 2)

        // Start full of walls (true)
        var grid = Array(repeating: Array(repeating: true, count: cols), count: rows)

        // Maze on odd coordinates: carve cells at odd row indexes (1..rows-2 step 2)
        // and odd column indexes (1..cols-2 step 2). This leaves walls between cells.
        let minRow = 1, maxRow = rows - 2
        let minCol = 1, maxCol = cols - 1

        func isOddCell(_ r: Int, _ c: Int) -> Bool { r % 2 == 1 && c % 2 == 1 }
        func inBoundsCell(_ r: Int, _ c: Int) -> Bool { r >= minRow && r <= maxRow && c >= minCol && c <= maxCol }

        // Initialize odd cells as walls (already true) — we'll carve them open (false)
        // Depth-first carve stepping by 2
        func carve(from r: Int, _ c: Int) {
            grid[r][c] = false // open current cell
            var directions: [(Int, Int)] = [(-2, 0), (2, 0), (0, -2), (0, 2)]
            directions.shuffle()
            for (dr, dc) in directions {
                let nr = r + dr
                let nc = c + dc
                if inBoundsCell(nr, nc) && isOddCell(nr, nc) && grid[nr][nc] { // neighbor is still wall (unvisited)
                    // open the wall between (r,c) and (nr,nc)
                    grid[r + dr/2][c + dc/2] = false
                    grid[nr][nc] = false
                    carve(from: nr, nc)
                }
            }
        }

        // Choose odd start column near center
        var startCol = (cols / 2)
        if startCol % 2 == 0 { startCol = max(minCol, startCol - 1) }
        carve(from: minRow, startCol)

        // Create a primary entrance from the top lane (rowIndex 0) to the first row of the maze (rowIndex 1)
        grid[0][startCol] = false
        grid[1][startCol] = false

        // Additional top entrances at world columns 1 and 9 → local col indices 0 and 8
        // Ensure each entrance connects into the maze by opening the adjacent odd-column cell
        if cols >= 2 {
            // Entrance at colIndex 0 (world col 1)
            grid[0][1] = false
            grid[1][1] = false
            if cols > 1 { grid[1][1] = false } // connect into first odd-column cell
        }
        if cols >= 10 {
            // Entrance at colIndex 8 (world col 9)
            grid[0][9] = false
            grid[1][9] = false
            if cols > 9 { grid[1][9] = false } // connect into odd-column cell at 9
        }
        // Create a single exit from the last row of the maze (rowIndex rows-2) to the bottom lane (rowIndex rows-1)
        grid[rows - 2][startCol] = false
        grid[rows - 1][startCol] = false

        return grid
    }
}
