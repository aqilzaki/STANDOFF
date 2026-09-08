//
//  WelcomeOverlayNode.swift
//  aqil.game
//
import SpriteKit

class WelcomeOverlayNode: SKNode {
    
    private(set) var startButton: SKShapeNode!
    private var onStartAction: (() -> Void)?
    
    init(size: CGSize, onStart: @escaping () -> Void) {
        super.init()
        self.onStartAction = onStart
        zPosition = 220
        alpha = 0.0
        
        let dimLayer = SKShapeNode(rectOf: size)
        dimLayer.fillColor = SKColor.black.withAlphaComponent(0.70)
        dimLayer.strokeColor = .clear
        dimLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(dimLayer)
        
        let cardWidth = min(290.0, size.width * 0.80)
        let cardHeight: CGFloat = 230.0
        
        let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 20)
        card.fillColor = SKColor(red: 0.95, green: 0.92, blue: 0.86, alpha: 1.0)
        card.strokeColor = SKColor(red: 0.22, green: 0.15, blue: 0.10, alpha: 1.0)
        card.lineWidth = 3.0
        card.position = CGPoint(x: size.width / 2, y: size.height * 0.52)
        card.setScale(0.9)
        addChild(card)
        
        let innerBorder = SKShapeNode(rectOf: CGSize(width: cardWidth - 14, height: cardHeight - 14), cornerRadius: 14)
        innerBorder.strokeColor = SKColor(red: 0.22, green: 0.15, blue: 0.10, alpha: 0.25)
        innerBorder.lineWidth = 1.2
        innerBorder.fillColor = .clear
        card.addChild(innerBorder)
        
        let subTitle = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        subTitle.text = "• WILD WEST •"
        subTitle.fontSize = 12
        subTitle.fontColor = SKColor(white: 0.45, alpha: 1.0)
        subTitle.position = CGPoint(x: 0, y: 50)
        card.addChild(subTitle)
        
        let titleLabel = SKLabelNode(fontNamed: "HelveticaNeue-Black")
        titleLabel.text = "STANDOFF"
        titleLabel.fontSize = 38
        titleLabel.fontColor = SKColor(red: 0.18, green: 0.12, blue: 0.08, alpha: 1.0)
        titleLabel.position = CGPoint(x: 0, y: 10)
        card.addChild(titleLabel)
        
        let btnWidth: CGFloat = 175.0
        let btnHeight: CGFloat = 52.0
        
        startButton = SKShapeNode(rectOf: CGSize(width: btnWidth, height: btnHeight), cornerRadius: 14)
        startButton.fillColor = SKColor(red: 0.18, green: 0.12, blue: 0.08, alpha: 1.0)
        startButton.strokeColor = .clear
        startButton.position = CGPoint(x: 0, y: -55)
        card.addChild(startButton)
        
        let btnText = SKLabelNode(fontNamed: "HelveticaNeue-Black")
        btnText.text = "PLAY"
        btnText.fontSize = 18
        btnText.fontColor = .white
        btnText.verticalAlignmentMode = .center
        startButton.addChild(btnText)
        
        startButton.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.04, duration: 0.45),
            SKAction.scale(to: 1.0, duration: 0.45)
        ])))
        
        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.run {
                card.run(SKAction.sequence([
                    SKAction.scale(to: 1.03, duration: 0.16),
                    SKAction.scale(to: 1.0, duration: 0.08)
                ]))
            }
        ])
        run(popIn)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func dismiss() {
        run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.18),
            SKAction.removeFromParent()
        ]))
        onStartAction?()
    }
}
