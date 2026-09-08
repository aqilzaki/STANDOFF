//
//  GameOverOverlayNode.swift
//  aqil.game
//
//  Created by muhammad aqil zaki on 08/09/26.
//


//
//  GameOverOverlay.swift
//  aqil.game
//
import SpriteKit

class GameOverOverlayNode: SKNode {
    
    private(set) var restartButton: SKShapeNode?
    
    init(size: CGSize, score: Int, bestScore: Int, duels: Int, combo: Int, textures: [SKTexture], onFinish: @escaping () -> Void) {
        super.init()
        zPosition = 250
        
        let dimLayer = SKShapeNode(rectOf: size)
        dimLayer.fillColor = SKColor.black.withAlphaComponent(0.82)
        dimLayer.strokeColor = .clear
        dimLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(dimLayer)
        
        guard let firstFrame = textures.first else { return }
        
        let banner = SKSpriteNode(texture: firstFrame)
        banner.setScale(2.8)
        banner.anchorPoint = CGPoint(x: 0.5, y: 0.85)
        banner.position = CGPoint(x: size.width / 2, y: size.height * 0.68)
        addChild(banner)
        
        let unfold = SKAction.animate(with: textures, timePerFrame: 0.08, resize: true, restore: false)
        banner.run(unfold) { [weak self] in
            self?.populateContent(on: banner, score: score, bestScore: bestScore, duels: duels, combo: combo)
            onFinish()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func populateContent(on banner: SKSpriteNode, score: Int, bestScore: Int, duels: Int, combo: Int) {
        let isNewRecord = (score >= bestScore && score > 0)
        let contentNode = SKNode()
        contentNode.alpha = 0.0
        contentNode.zPosition = 10
        banner.addChild(contentNode)
        
        let titleLabel = SKLabelNode(fontNamed: "HelveticaNeue-Black")
        titleLabel.text = "TERTEBAS!"
        titleLabel.fontSize = 13
        titleLabel.fontColor = SKColor(red: 0.65, green: 0.08, blue: 0.08, alpha: 1.0)
        titleLabel.position = CGPoint(x: 0, y: -30)
        contentNode.addChild(titleLabel)
        
        if isNewRecord {
            let badge = SKLabelNode(fontNamed: "HelveticaNeue-Black")
            badge.text = "★ REKOR BARU! ★"
            badge.fontSize = 6
            badge.fontColor = SKColor(red: 0.78, green: 0.45, blue: 0.0, alpha: 1.0)
            badge.position = CGPoint(x: 0, y: -38)
            contentNode.addChild(badge)
        }
        
        let inkColor = SKColor(red: 0.22, green: 0.12, blue: 0.08, alpha: 1.0)
        let stats = ["SKOR: \(score)", "BEST: \(bestScore)", "LAWAN: \(duels)", "KOMBO: x\(combo)"]
        for (index, text) in stats.enumerated() {
            let label = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
            label.text = text
            label.fontSize = 6
            label.fontColor = inkColor
            label.position = CGPoint(x: 0, y: -45 - CGFloat(index * 10))
            contentNode.addChild(label)
        }
        
        let btn = SKShapeNode(rectOf: CGSize(width: 85, height: 26), cornerRadius: 5)
        btn.fillColor = SKColor(red: 0.72, green: 0.08, blue: 0.08, alpha: 1.0)
        btn.strokeColor = .white
        btn.lineWidth = 1.2
        btn.position = CGPoint(x: 0, y: -118)
        contentNode.addChild(btn)
        self.restartButton = btn
        
        let btnText = SKLabelNode(fontNamed: "HelveticaNeue-Black")
        btnText.text = "MAIN LAGI"
        btnText.fontSize = 9.5
        btnText.fontColor = .white
        btnText.verticalAlignmentMode = .center
        btn.addChild(btnText)
        
        btn.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.06, duration: 0.4),
            SKAction.scale(to: 1.0, duration: 0.4)
        ])))
        
        contentNode.run(SKAction.fadeIn(withDuration: 0.25))
    }
}