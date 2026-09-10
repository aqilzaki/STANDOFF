//
//  WelcomeOverlayNode.swift
//  aqil.game (Bold Western Edition)
//
import SpriteKit
import UIKit

class WelcomeOverlayNode: SKNode {
    
    private(set) var startButton: SKShapeNode!
    private var onStartAction: (() -> Void)?
    
    // Font bawaan iOS pilihan: "Chalkduster" (atau ganti "MarkerFelt-Wide" jika ingin lebih tebal pekat)
    private let baseFontName = "Chalkduster"
    
    init(size: CGSize, onStart: @escaping () -> Void) {
        super.init()
        self.onStartAction = onStart
        zPosition = 220
        alpha = 0.0
        
        let dimLayer = SKShapeNode(rectOf: size)
        dimLayer.fillColor = SKColor.black.withAlphaComponent(0.72)
        dimLayer.strokeColor = .clear
        dimLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(dimLayer)
        
        let cardWidth = min(300.0, size.width * 0.82)
        let cardHeight: CGFloat = 240.0
        
        // Kartu Perkamen
        let card = SKShapeNode(rectOf: CGSize(width: cardWidth, height: cardHeight), cornerRadius: 18)
        card.fillColor = SKColor(red: 0.95, green: 0.92, blue: 0.85, alpha: 1.0)
        card.strokeColor = SKColor(red: 0.22, green: 0.15, blue: 0.08, alpha: 1.0)
        card.lineWidth = 3.0
        card.position = CGPoint(x: size.width / 2, y: size.height * 0.52)
        card.setScale(0.90)
        addChild(card)
        
        let innerBorder = SKShapeNode(rectOf: CGSize(width: cardWidth - 14, height: cardHeight - 14), cornerRadius: 12)
        innerBorder.strokeColor = SKColor(red: 0.22, green: 0.15, blue: 0.08, alpha: 0.30)
        innerBorder.lineWidth = 1.5
        innerBorder.fillColor = .clear
        card.addChild(innerBorder)
        
        // 1. Sub-Header
        let subTitle = SKLabelNode(fontNamed: baseFontName)
        subTitle.text = "• WILD WEST •"
        subTitle.fontSize = 11.5
        subTitle.fontColor = SKColor(red: 0.55, green: 0.38, blue: 0.22, alpha: 1.0)
        subTitle.position = CGPoint(x: 0, y: 56)
        card.addChild(subTitle)
        
        // 2. Judul Utama "STANDOFF" (Ditebalkan Mantap / BOLD)
        let titleColor = UIColor(red: 0.18, green: 0.12, blue: 0.06, alpha: 1.0)
        let titleFont = UIFont(name: baseFontName, size: 38) ?? UIFont.boldSystemFont(ofSize: 38)
        
        let boldTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: titleColor,
            .strokeColor: titleColor,
            .strokeWidth: -3.5 // ➔ Nilai minus otomatis menebalkan outline & isi huruf
        ]
        
        let titleLabel = SKLabelNode()
        titleLabel.attributedText = NSAttributedString(string: "STANDOFF", attributes: boldTitleAttributes)
        titleLabel.position = CGPoint(x: 0, y: 8)
        card.addChild(titleLabel)
        
        // 3. Tombol Aksi "PLAY"
        let btnWidth: CGFloat = 175.0
        let btnHeight: CGFloat = 52.0
        
        startButton = SKShapeNode(rectOf: CGSize(width: btnWidth, height: btnHeight), cornerRadius: 14)
        startButton.fillColor = SKColor(red: 0.18, green: 0.12, blue: 0.06, alpha: 1.0)
        startButton.strokeColor = SKColor(red: 0.88, green: 0.75, blue: 0.40, alpha: 0.9)
        startButton.lineWidth = 1.5
        startButton.position = CGPoint(x: 0, y: -58)
        card.addChild(startButton)
        
        // Teks "PLAY" Ditebalkan
        let btnColor = UIColor(red: 0.98, green: 0.92, blue: 0.78, alpha: 1.0)
        let btnFont = UIFont(name: baseFontName, size: 21) ?? UIFont.boldSystemFont(ofSize: 21)
        
        let boldBtnAttributes: [NSAttributedString.Key: Any] = [
            .font: btnFont,
            .foregroundColor: btnColor,
            .strokeColor: btnColor,
            .strokeWidth: -3.0
        ]
        
        let btnText = SKLabelNode()
        btnText.attributedText = NSAttributedString(string: "PLAY", attributes: boldBtnAttributes)
        btnText.verticalAlignmentMode = .center
        btnText.position = CGPoint(x: 0, y: -1)
        startButton.addChild(btnText)
        
        // Animasi Denyut Nafas Tombol Play
        startButton.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.45),
            SKAction.scale(to: 1.0, duration: 0.45)
        ])))
        
        // Animasi Pop Masuk
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
    
    func dismiss() {
        run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.16),
            SKAction.removeFromParent()
        ]))
        onStartAction?()
    }
}
