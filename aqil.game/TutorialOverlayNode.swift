//
//  TutorialOverlayNode.swift
//  aqil.game
//
//  Created by muhammad aqil zaki on 08/09/26.
//


//
//  TutorialOverlay.swift
//  aqil.game
//
import SpriteKit

class TutorialOverlayNode: SKNode {
    
    private var tutorialBox: SKShapeNode!
    private var titleLabel: SKLabelNode!
    private var descLabel: SKLabelNode!
    private var promptLabel: SKLabelNode!
    private var handHint: SKLabelNode!
    
    init(size: CGSize) {
        super.init()
        zPosition = 180
        alpha = 0.0
        
        let dimLayer = SKShapeNode(rectOf: size)
        dimLayer.fillColor = SKColor.black.withAlphaComponent(0.68)
        dimLayer.strokeColor = .clear
        dimLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(dimLayer)
        
        let boxWidth = size.width * 0.88
        let boxHeight: CGFloat = 140
        tutorialBox = SKShapeNode(rectOf: CGSize(width: boxWidth, height: boxHeight), cornerRadius: 16)
        tutorialBox.fillColor = SKColor(white: 0.12, alpha: 0.95)
        tutorialBox.strokeColor = .systemYellow
        tutorialBox.lineWidth = 2.0
        tutorialBox.position = CGPoint(x: size.width / 2, y: size.height * 0.70)
        addChild(tutorialBox)
        
        titleLabel = SKLabelNode(fontNamed: "HelveticaNeue-Black")
        titleLabel.fontSize = 17
        titleLabel.fontColor = .systemYellow
        titleLabel.position = CGPoint(x: 0, y: 35)
        tutorialBox.addChild(titleLabel)
        
        descLabel = SKLabelNode(fontNamed: "HelveticaNeue-Medium")
        descLabel.fontSize = 13.5
        descLabel.numberOfLines = 3
        descLabel.fontColor = .white
        descLabel.position = CGPoint(x: 0, y: -8)
        tutorialBox.addChild(descLabel)
        
        promptLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        promptLabel.fontSize = 14
        promptLabel.fontColor = .systemGreen
        promptLabel.position = CGPoint(x: 0, y: -50)
        tutorialBox.addChild(promptLabel)
        
        handHint = SKLabelNode(fontNamed: "HelveticaNeue-Black")
        handHint.fontSize = 42
        addChild(handHint)
        
        let bounce = SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.25, duration: 0.35),
            SKAction.scale(to: 1.0, duration: 0.35)
        ]))
        handHint.run(bounce)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showParryPrompt(step: TutorialStep, screenSize: CGSize) {
        removeAllActions()
        run(SKAction.fadeIn(withDuration: 0.2))
        let midX = screenSize.width / 2.0
        
        if step == .parryRight {
            titleLabel.text = "TUTORIAL 1/4: PARRY KANAN"
            descLabel.text = "Lawan menyerang dari KIRI ke KANAN!\nPedang kita harus menyambut menyilang ke kanan."
            promptLabel.text = "👉 TAP LAYAR KANAN SEKARANG!"
            promptLabel.fontColor = .systemYellow
            handHint.text = "👉"
            handHint.position = CGPoint(x: midX + 85, y: screenSize.height * 0.32)
        } else {
            titleLabel.text = "TUTORIAL 2/4: PARRY KIRI"
            descLabel.text = "Lawan menyerang dari KANAN ke KIRI!\nPedang kita menyambut menyilang ke kiri."
            promptLabel.text = "👈 TAP LAYAR KIRI SEKARANG!"
            promptLabel.fontColor = .systemYellow
            handHint.text = "👈"
            handHint.position = CGPoint(x: midX - 85, y: screenSize.height * 0.32)
        }
    }
    
    func showHoldPrompt(step: TutorialStep, screenSize: CGSize) {
        removeAllActions()
        run(SKAction.fadeIn(withDuration: 0.2))
        let midX = screenSize.width / 2.0
        
        if step == .holdRight {
            titleLabel.text = "TUTORIAL 3/4: BLOK KANAN (HOLD)"
            descLabel.text = "Lawan BELUM menyerang!\nPasang kuda-kuda nangkis duluan di sisi kanan."
            promptLabel.text = "👉 TAHAN (HOLD) JARI DI SISI KANAN SEKARANG!"
            promptLabel.fontColor = .systemCyan
            handHint.text = "👉"
            handHint.position = CGPoint(x: midX + 85, y: screenSize.height * 0.32)
        } else {
            titleLabel.text = "TUTORIAL 4/4: BLOK KIRI (HOLD)"
            descLabel.text = "Lawan BELUM menyerang!\nPasang kuda-kuda nangkis duluan di sisi kiri."
            promptLabel.text = "👈 TAHAN (HOLD) JARI DI SISI KIRI SEKARANG!"
            promptLabel.fontColor = .systemCyan
            handHint.text = "👈"
            handHint.position = CGPoint(x: midX - 85, y: screenSize.height * 0.32)
        }
    }
    
    func updatePromptText(_ text: String, color: SKColor) {
        promptLabel.text = text
        promptLabel.fontColor = color
    }
    
    func hide() {
        removeAllActions()
        alpha = 0.0
    }
    
    func shakeBox() {
        tutorialBox.run(SKAction.sequence([
            SKAction.moveBy(x: -10, y: 0, duration: 0.03),
            SKAction.moveBy(x: 20, y: 0, duration: 0.03),
            SKAction.moveBy(x: -10, y: 0, duration: 0.03)
        ]))
    }
}