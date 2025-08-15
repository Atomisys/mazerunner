import SpriteKit

final class Enemy {
    var sprite: SKSpriteNode
    let color: SKColor
    var direction: Direction = .down
    var lastGridPosition: CGPoint = .zero
    // Prebuilt variants with pupils offset: [up, down, left, right]
    var directionalSprites: [SKSpriteNode] = []
    
    init(sprite: SKSpriteNode, color: SKColor) {
        self.sprite = sprite
        self.color = color
    }
}
