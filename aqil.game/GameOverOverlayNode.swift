//
//  GameOverOverlayNode.swift
//  aqil.game (AvenirNextCondensed Font & Eye-Friendly Palette)
//
import SpriteKit

class GameOverOverlayNode: SKNode {
    
    private let fontHeavy = "AvenirNextCondensed-Heavy"
    private let fontBold  = "AvenirNextCondensed-Bold"
    
    private let pureBlackColor    = SKColor(red: 0.08, green: 0.07, blue: 0.06, alpha: 1.0) // Hitam arang teduh (#141210)
    private let softWhiteColor    = SKColor(red: 0.98, green: 0.97, blue: 0.94, alpha: 1.0) // Putih mutiara lembut (#FAF7F0)
    private let goldenAmberColor  = SKColor(red: 0.96, green: 0.78, blue: 0.24, alpha: 1.0) // Emas koin gurun (#F5C73D)
    private let westernRedColor   = SKColor(red: 0.76, green: 0.18, blue: 0.14, alpha: 1.0) // Merah klasik teduh
    
    private(set) var restartButton: SKShapeNode?
    
    init(size: CGSize, score: Int, bestScore: Int, duels: Int, combo: Int, textures: [SKTexture] = [], onFinish: (() -> Void)? = nil) {
        super.init()
        zPosition = 250
        alpha = 0.0
        
        let dimLayer = SKShapeNode(rectOf: size)
        dimLayer.fillColor = SKColor.black.withAlphaComponent(0.75)
        dimLayer.strokeColor = .clear
        dimLayer.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(dimLayer)
        
        let cardWidth = min(320.0, size.width * 0.86)
        let cardHeight: CGFloat = 370.0
        
        // Kartu Perkamen
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
        
        // 1. Sub-Header
        let subHeader = SKLabelNode(fontNamed: fontBold)
        subHeader.text = "• WILD WEST STANDOFF •"
        subHeader.fontSize = 12
        subHeader.fontColor = SKColor(white: 0.45, alpha: 1.0)
        subHeader.position = CGPoint(x: 0, y: 142)
        card.addChild(subHeader)
        
        // 2. Judul Utama "TERTEMBAK!"
        let titleLabel = SKLabelNode(fontNamed: fontHeavy)
        titleLabel.text = "TERTEMBAK!"
        titleLabel.fontSize = 32
        titleLabel.fontColor = westernRedColor
        titleLabel.position = CGPoint(x: 0, y: 108)
        card.addChild(titleLabel)
        
        // 3. Rekor Baru (Jika tercapai)
        let isNewRecord = (score >= bestScore && score > 0)
        if isNewRecord {
            let recordBadge = SKLabelNode(fontNamed: fontHeavy)
            recordBadge.text = "★ REKOR BARU! ★"
            recordBadge.fontSize = 13
            recordBadge.fontColor = goldenAmberColor
            recordBadge.position = CGPoint(x: 0, y: 86)
            card.addChild(recordBadge)
            
            let pulse = SKAction.repeatForever(SKAction.sequence([
                SKAction.scale(to: 1.12, duration: 0.35),
                SKAction.scale(to: 1.0, duration: 0.35)
            ]))
            recordBadge.run(pulse)
        }
        
        // 4. Kotak Nilai Skor Akhir
        let scoreBox = SKShapeNode(rectOf: CGSize(width: cardWidth - 44, height: 75), cornerRadius: 10)
        scoreBox.fillColor = SKColor(white: 0.12, alpha: 0.06)
        scoreBox.strokeColor = SKColor(white: 0.2, alpha: 0.15)
        scoreBox.lineWidth = 1.0
        scoreBox.position = CGPoint(x: 0, y: 40)
        card.addChild(scoreBox)
        
        let scoreTitle = SKLabelNode(fontNamed: fontBold)
        scoreTitle.text = "SKOR AKHIR"
        scoreTitle.fontSize = 11.5
        scoreTitle.fontColor = SKColor(white: 0.45, alpha: 1.0)
        scoreTitle.position = CGPoint(x: 0, y: 14)
        scoreBox.addChild(scoreTitle)
        
        let scoreValue = SKLabelNode(fontNamed: fontHeavy)
        scoreValue.text = "\(score)"
        scoreValue.fontSize = 38
        scoreValue.fontColor = pureBlackColor
        scoreValue.position = CGPoint(x: 0, y: -22)
        scoreBox.addChild(scoreValue)
        
        // 5. Rincian Statistik (Terbaik, Ronde, Max Kombo)
        let statsY: CGFloat = -42.0
        let colWidth = (cardWidth - 50) / 3.0
        let statsData: [(title: String, val: String)] = [
            ("TERBAIK", "\(bestScore)"),
            ("RONDE", "\(duels)"),
            ("MAX KOMBO", "x\(combo)")
        ]
        
        for (i, stat) in statsData.enumerated() {
            let posX = -colWidth + CGFloat(i) * colWidth
            
            let tLabel = SKLabelNode(fontNamed: fontBold)
            tLabel.text = stat.title
            tLabel.fontSize = 11
            tLabel.fontColor = SKColor(white: 0.45, alpha: 1.0)
            tLabel.position = CGPoint(x: posX, y: statsY)
            card.addChild(tLabel)
            
            let vLabel = SKLabelNode(fontNamed: fontHeavy)
            vLabel.text = stat.val
            vLabel.fontSize = 18
            vLabel.fontColor = pureBlackColor
            vLabel.position = CGPoint(x: posX, y: statsY - 20)
            card.addChild(vLabel)
        }
        
        // Garis Pembatas
        let sepLine = SKShapeNode(rectOf: CGSize(width: cardWidth - 50, height: 1))
        sepLine.fillColor = SKColor(white: 0.25, alpha: 0.18)
        sepLine.strokeColor = .clear
        sepLine.position = CGPoint(x: 0, y: -80)
        card.addChild(sepLine)
        
        // 6. Tombol "MAIN LAGI"
        let btn = SKShapeNode(rectOf: CGSize(width: cardWidth - 50, height: 48), cornerRadius: 12)
        btn.fillColor = pureBlackColor
        btn.strokeColor = goldenAmberColor.withAlphaComponent(0.40)
        btn.lineWidth = 1.0
        btn.position = CGPoint(x: 0, y: -125)
        card.addChild(btn)
        self.restartButton = btn
        
        let btnText = SKLabelNode(fontNamed: fontHeavy)
        btnText.text = "↺ MAIN LAGI"
        btnText.fontSize = 16
        btnText.fontColor = softWhiteColor
        btnText.verticalAlignmentMode = .center
        btn.addChild(btnText)
        
        btn.run(SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.04, duration: 0.45),
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
        run(SKAction.sequence([popIn, SKAction.run { onFinish?() }]))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
