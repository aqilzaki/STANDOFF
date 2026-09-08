
//
//  GameAssets.swift
//  aqil.game
//
import SpriteKit
import UIKit

// =============================================================================
// MARK: - PUSAT KONTROL ASET
// =============================================================================
struct GameAssets {
    
    static var useCustomSprites: Bool = true
    
        
    // Aset Karakter Pemain
    static let playerBodyImage: String = "player_body"
    static let playerBodyAlpha: CGFloat = 0.45
    static let playerBodyScale: CGFloat = 4.4
    
    
    // Background Arena
        static let backgroundImage: String = "BACKGROUND"
        
    static let playerSwordAtlas: String = "PlayerKatana"
    
    // 2. Aset Lawan (Bisa gambar diam atau nama Folder Atlas dari Aseprite)
    static let enemyIdleAtlas: String = "EnemyIdle"           // Folder Atlas di Assets
    static let enemyWindupAtlas: String = "EnemyWindup"
    static let enemySlashImage: String = "enemy_slash_blade"  // Pedang tebasan raksasa
    
    // 3. Efek Visual Tambahan
    static let sparkParticleImage: String = "spark_particle"
    static let slashTrailImage: String = "slash_trail"
}


// =============================================================================
// MARK: - ANIMATION HELPER
// =============================================================================
struct AnimationHelper {
    
    /// Memuat array SKTexture berurutan (misal: "slashing_right_side2" .. "slashing_right_side7")
    static func loadTextures(
        prefix: String,
        from startIndex: Int,
        to endIndex: Int,
        filteringMode: SKTextureFilteringMode = .nearest
    ) -> [SKTexture] {
        var textures: [SKTexture] = []
        for index in startIndex...endIndex {
            let textureName = "\(prefix)\(index)"
            let texture = SKTexture(imageNamed: textureName)
            texture.filteringMode = filteringMode
            textures.append(texture)
        }
        return textures
    }
    
    /// Membuat SKAction animasi frame-by-frame
    static func createAction(
        textures: [SKTexture],
        duration: TimeInterval,
        resize: Bool = true,
        restore: Bool = false
    ) -> SKAction {
        guard !textures.isEmpty else { return SKAction.wait(forDuration: duration) }
        let timePerFrame = duration / Double(textures.count)
        return SKAction.animate(with: textures, timePerFrame: timePerFrame, resize: resize, restore: restore)
    }
}

