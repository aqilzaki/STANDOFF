//
//  CombatEffects.swift
//  aqil.game
//
//  Created by muhammad aqil zaki on 08/09/26.
//


//
//  CombatEffects.swift
//  aqil.game
//
import SpriteKit
import UIKit

class CombatEffects {
    
    static func generateBloodVignetteTexture(screenSize: CGSize) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: screenSize)
        let img = renderer.image { context in
            let ctx = context.cgContext
            ctx.saveGState()
            let aspect = screenSize.height / screenSize.width
            ctx.scaleBy(x: 1.0, y: aspect)
            
            let colors = [
                UIColor.clear.cgColor,
                UIColor.clear.cgColor,
                UIColor(red: 0.95, green: 0.02, blue: 0.05, alpha: 0.60).cgColor,
                UIColor(red: 0.82, green: 0.00, blue: 0.02, alpha: 0.92).cgColor,
                UIColor(red: 0.45, green: 0.00, blue: 0.01, alpha: 1.00).cgColor
            ] as CFArray
            
            let locations: [CGFloat] = [0.0, 0.35, 0.58, 0.82, 1.0]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) else { return }
            
            let center = CGPoint(x: screenSize.width / 2, y: (screenSize.height / 2) / aspect)
            let radius = (screenSize.width / 2) * 1.85
            ctx.drawRadialGradient(gradient, startCenter: center, startRadius: radius * 0.25, endCenter: center, endRadius: radius, options: [.drawsAfterEndLocation])
            ctx.restoreGState()
        }
        return SKTexture(image: img)
    }
    
    static func spawnSparks(at pos: CGPoint, in scene: SKScene) {
        for _ in 0..<18 {
            let spark = SKShapeNode(circleOfRadius: .random(in: 2.0...4.5))
            spark.fillColor = .yellow
            spark.strokeColor = .white
            spark.position = pos
            spark.zPosition = 80
            scene.addChild(spark)
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 45...95)
            let move = SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.20)
            let fade = SKAction.fadeOut(withDuration: 0.20)
            
            spark.run(SKAction.sequence([
                SKAction.group([move, fade]),
                SKAction.removeFromParent()
            ]))
        }
    }
    
    static func spawnBlockSparks(at pos: CGPoint, in scene: SKScene) {
        for _ in 0..<5 {
            let spark = SKShapeNode(circleOfRadius: .random(in: 1.2...2.2))
            spark.fillColor = SKColor(white: 0.85, alpha: 1.0)
            spark.strokeColor = .clear
            spark.position = pos
            spark.zPosition = 80
            scene.addChild(spark)
            
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 15...35)
            let move = SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.12)
            let fade = SKAction.fadeOut(withDuration: 0.12)
            
            spark.run(SKAction.sequence([
                SKAction.group([move, fade]),
                SKAction.removeFromParent()
            ]))
        }
    }
    
    static func flashScreen(color: SKColor, in scene: SKScene) {
        let flash = SKShapeNode(rectOf: scene.size)
        flash.fillColor = color
        flash.alpha = 0.5
        flash.zPosition = 90
        flash.position = CGPoint(x: scene.size.width / 2, y: scene.size.height / 2)
        scene.addChild(flash)
        flash.run(SKAction.sequence([SKAction.fadeOut(withDuration: 0.1), SKAction.removeFromParent()]))
    }
}