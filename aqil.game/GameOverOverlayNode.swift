//
//  GameOverOverlayNode.swift
//  aqil.game
//
import SpriteKit

class GameOverOverlayNode: SKNode {
    
    private(set) var restartButton: SKShapeNode?
    
    init(size: CGSize, score: Int, bestScore: Int, duels: Int, combo: Int, textures: [SKTexture] = [], onFinish: (() -> Void)? = nil) {
        super.init()
        zPosition = 250
        alpha = 0.0
        
        let dimLayer = SKShapeNode(rectOf: size)
        dimLayer.fillColor = SKColor.black.withAlphaComponent(0.78)
        dimLayer.strokeColor = .clear
        dimLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(dimLayer)
        
        let cardWidth = min(320.0, size.width * 0.86)
        let cardHeight: CGFloat = 370.0
        
        let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 18)
        card.fillColor = SKColor(red: 0.95, green: 0.92, blue: 0.86, alpha: 1.0)
        card.strokeColor = SKColor(red: 0.25, green: 0.18, blue: 0.12, alpha: 1.0)
        card.lineWidth = 3.0
        card.position = CGPoint(x: size.width / 2, y: size.height * 0.52)
        card.setScale(0.88)
        addChild(card)
        
        let innerBorder = SKShapeNode(rectOf: CGSize(width: cardWidth - 14, height: cardHeight - 14), cornerRadius: 12)
        innerBorder.strokeColor = SKColor(red: 0.25, green: 0.18, blue: 0.12, alpha: 0.35)
        innerBorder.lineWidth = 1.2
        innerBorder.fillColor = .clear
        card.addChild(innerBorder)
        
        let subHeader = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        subHeader.text = "• WILD WEST STANDOFF •"
        subHeader.fontSize = 11
        subHeader.fontColor = SKColor(white: 0.4, alpha: 1.0)
        subHeader.position = CGPoint(x: 0, y: 142)
        card.addChild(subHeader)
        
        let titleLabel = SKLabelNode(fontNamed: "HelveticaNeue-Black")
        titleLabel.text = "TERTEMBAK!"
        titleLabel.fontSize = 28
        titleLabel.fontColor = SKColor(red: 0.72, green: 0.10, blue: 0.10, alpha: 1.0)
        titleLabel.position = CGPoint(x: 0, y: 110)
        card.addChild(titleLabel)
        
        let isNewRecord = (score >= bestScore && score > 0)
        if isNewRecord {
            let recordBadge = SKLabelNode(fontNamed: "HelveticaNeue-Black")
            recordBadge.text = "★ REKOR BARU! ★"
            recordBadge.fontSize = 12
            recordBadge.fontColor = SKColor(red: 0.82, green: 0.50, blue: 0.05, alpha: 1.0)
            recordBadge.position = CGPoint(x: 0, y: 88)
            card.addChild(recordBadge)
            
            let pulse = SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.15, duration: 0.35),
                SKAction.scale(to: 1.0, duration: 0.35)
            ]))
            recordBadge.run(pulse)
        }
        
        let scoreBox = SKShapeNode(rectOf: CGSize(width: cardWidth - 44, height: 75), cornerRadius: 10)
        scoreBox.fillColor = SKColor(white: 0.12, alpha: 0.06)
        scoreBox.strokeColor = SKColor(white: 0.2, alpha: 0.15)
        scoreBox.lineWidth = 1.0
        scoreBox.position = CGPoint(x: 0, y: 40)
        card.addChild(scoreBox)
        
        let scoreTitle = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        scoreTitle.text = "SKOR AKHIR"
        scoreTitle.fontSize = 11
        scoreTitle.fontColor = SKColor(white: 0.4, alpha: 1.0)
        scoreTitle.position = CGPoint(x: 0, y: 14)
        scoreBox.addChild(scoreTitle)
        
        let scoreValue = SKLabelNode(fontNamed: "HelveticaNeue-Black")
        scoreValue.text = "\(score)"
        scoreValue.fontSize = 36
        scoreValue.fontColor = SKColor(red: 0.18, green: 0.12, blue: 0.08, alpha: 1.0)
        scoreValue.position = CGPoint(x: 0, y: -22)
        scoreBox.addChild(scoreValue)
        
        let statsY: CGFloat = -42.0
        let colWidth = (cardWidth - 50) / 3.0
        let statsData: [(title: String, val: String)] = [
            ("TERBAIK", "\(bestScore)"),
            ("RONDE", "\(duels)"),
            ("MAX KOMBO", "x\(combo)")
        ]
        
        for (i, stat) in statsData.enumerated() {
            let posX = -colWidth + CGFloat(i) * colWidth
            let tLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
            tLabel.text = stat.title
            tLabel.fontSize = 10
            tLabel.fontColor = SKColor(white: 0.45, alpha: 1.0)
            tLabel.position = CGPoint(x: posX, y: statsY)
            card.addChild(tLabel)
            
            let vLabel = SKLabelNode(fontNamed: "HelveticaNeue-Black")
            vLabel.text = stat.val
            vLabel.fontSize = 16
            vLabel.fontColor = SKColor(red: 0.22, green: 0.14, blue: 0.10, alpha: 1.0)
            vLabel.position = CGPoint(x: posX, y: statsY - 20)
            card.addChild(vLabel)
        }
        
        let sepLine = SKShapeNode(rectOf: CGSize(width: cardWidth - 50, height: 1))
        sepLine.fillColor = SKColor(white: 0.25, alpha: 0.18)
        sepLine.strokeColor = .clear
        sepLine.position = CGPoint(x: 0, y: -80)
        card.addChild(sepLine)
        
        let btn = SKShapeNode(rectOf: CGSize(width: cardWidth - 50, height: 48), cornerRadius: 10)
        btn.fillColor = SKColor(red: 0.18, green: 0.12, blue: 0.08, alpha: 1.0)
        btn.strokeColor = .clear
        btn.position = CGPoint(x: 0, y: -125)
        card.addChild(btn)
        self.restartButton = btn
        
        let btnText = SKLabelNode(fontNamed: "HelveticaNeue-Black")
        btnText.text = "↺ MAIN LAGI"
        btnText.fontSize = 15
        btnText.fontColor = .white
        btnText.verticalAlignmentMode = .center
        btn.addChild(btnText)
        
        btn.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.04, duration: 0.4),
            SKAction.scale(to: 1.0, duration: 0.4)
        ])))
        
        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.run {
                card.run(SKAction.sequence([
                    SKAction.scale(to: 1.04, duration: 0.16),
                    SKAction.scale(to: 1.0, duration: 0.08)
                ]))
            }
        ])
        run(SKAction.sequence([popIn, SKAction.run { onFinish?() }]))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
