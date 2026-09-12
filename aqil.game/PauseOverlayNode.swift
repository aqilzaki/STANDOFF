//
//  PauseOverlayNode.swift
//  aqil.game (Separate Pause Menu)
//
import SpriteKit

class PauseOverlayNode: SKNode {
    
    private(set) var resumeButton: SKShapeNode!
    private(set) var menuButton: SKShapeNode!
    
    private var onResumeAction: (() -> Void)?
    private var onMenuAction: (() -> Void)?
    
    private let fontHeavy = "AvenirNextCondensed-Heavy"
    private let fontBold  = "AvenirNextCondensed-Bold"
    
    init(size: CGSize, onResume: @escaping () -> Void, onMenu: @escaping () -> Void) {
        super.init()
        self.onResumeAction = onResume
        self.onMenuAction = onMenu
        zPosition = 230
        alpha = 0.0
        
        // 1. Dimmer Background Gelap
        let dimLayer = SKShapeNode(rectOf: size)
        dimLayer.fillColor = SKColor.black.withAlphaComponent(0.72)
        dimLayer.strokeColor = .clear
        dimLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(dimLayer)
        
        let cardWidth = min(290.0, size.width * 0.80)
        let cardHeight: CGFloat = 240.0
        
        // 2. Kartu Perkamen (Desain Serasi dengan Welcome Overlay)
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
        
        // 3. Teks Sub-header
        let subTitle = SKLabelNode(fontNamed: fontBold)
        subTitle.text = "• DUEL DIHENTIKAN •"
        subTitle.fontSize = 11.5
        subTitle.fontColor = SKColor(white: 0.45, alpha: 1.0)
        subTitle.position = CGPoint(x: 0, y: 64)
        card.addChild(subTitle)
        
        // 4. Judul "JEDA"
        let titleLabel = SKLabelNode(fontNamed: fontHeavy)
        titleLabel.text = "JEDA"
        titleLabel.fontSize = 38
        titleLabel.fontColor = SKColor(red: 0.18, green: 0.12, blue: 0.08, alpha: 1.0)
        titleLabel.position = CGPoint(x: 0, y: 20)
        card.addChild(titleLabel)
        
        let btnWidth: CGFloat = 185.0
        let btnHeight: CGFloat = 46.0
        
        // 5. Tombol "▶ LANJUTKAN"
        resumeButton = SKShapeNode(rectOf: CGSize(width: btnWidth, height: btnHeight), cornerRadius: 12)
        resumeButton.fillColor = SKColor(red: 0.18, green: 0.12, blue: 0.08, alpha: 1.0)
        resumeButton.strokeColor = .clear
        resumeButton.position = CGPoint(x: 0, y: -30)
        card.addChild(resumeButton)
        
        let resumeText = SKLabelNode(fontNamed: fontHeavy)
        resumeText.text = "LANJUTKAN"
        resumeText.fontSize = 16
        resumeText.fontColor = .white
        resumeText.verticalAlignmentMode = .center
        resumeButton.addChild(resumeText)
        
        resumeButton.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.04, duration: 0.45),
            SKAction.scale(to: 1.0, duration: 0.45)
        ])))
        
        // 6. Tombol "🏠 MENU UTAMA"
        menuButton = SKShapeNode(rectOf: CGSize(width: btnWidth, height: 38), cornerRadius: 10)
        menuButton.fillColor = SKColor.clear
        menuButton.strokeColor = SKColor(red: 0.22, green: 0.15, blue: 0.10, alpha: 0.35)
        menuButton.lineWidth = 1.0
        menuButton.position = CGPoint(x: 0, y: -80)
        card.addChild(menuButton)
        
        let menuText = SKLabelNode(fontNamed: fontBold)
        menuText.text = "MENU UTAMA"
        menuText.fontSize = 13.5
        menuText.fontColor = SKColor(red: 0.35, green: 0.25, blue: 0.15, alpha: 1.0)
        menuText.verticalAlignmentMode = .center
        menuButton.addChild(menuText)
        
        // Animasi Masuk
        let popIn = SKAction.group([
            SKAction.fadeIn(withDuration: 0.18),
            SKAction.run {
                card.run(SKAction.sequence([
                    SKAction.scale(to: 1.03, duration: 0.15),
                    SKAction.scale(to: 1.0, duration: 0.08)
                ]))
            }
        ])
        run(popIn)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func dismiss(then action: (() -> Void)? = nil) {
        run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.16),
            SKAction.removeFromParent(),
            SKAction.run { action?() }
        ]))
    }
}
