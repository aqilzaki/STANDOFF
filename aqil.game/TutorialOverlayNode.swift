//
//  TutorialOverlayNode.swift
//  aqil.game (Pure Swipe Tutorial Edition)
//
import SpriteKit

enum CowboyTutorialStep: Int, Equatable {
    case dodgeRight = 1
    case dodgeLeft = 2
    case feintReaction = 3
    case perfectDodge = 4
    case completed = 5
}

class TutorialOverlayNode: SKNode {
    
    // Container utama di tengah layar
    private var swipeCenterContainer: SKNode!
    
    // Label teks petunjuk arah
    private var actionTitleLabel: SKLabelNode!
    private var subTitleLabel: SKLabelNode!
    
    // Lintasan & Panah Vektor Animasi
    private var arcPathNode: SKShapeNode!
    private var arrowHeadNode: SKShapeNode!
    private var fingerDotNode: SKShapeNode!
    private var handEmojiNode: SKLabelNode!
    
    private let swipeArcWidth: CGFloat = 110.0
    private var currentIsRight: Bool = true
    
    init(size: CGSize) {
        super.init()
        zPosition = 180
        alpha = 0.0
        
        setupSwipeVisuals(screenSize: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup Visual Swipe Murni
    private func setupSwipeVisuals(screenSize: CGSize) {
        swipeCenterContainer = SKNode()
        swipeCenterContainer.position = CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.38)
        addChild(swipeCenterContainer)
        
        // 1. Teks Judul Arah Swipe (Besar & Tegas)
        actionTitleLabel = SKLabelNode(fontNamed: "HelveticaNeue-Black")
        actionTitleLabel.fontSize = 24
        actionTitleLabel.fontColor = .white
        actionTitleLabel.position = CGPoint(x: 0, y: 55)
        swipeCenterContainer.addChild(actionTitleLabel)
        
        // 2. Sub-teks "SWIPE TO DODGE"
        subTitleLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        subTitleLabel.text = "SWIPE TO DODGE"
        subTitleLabel.fontSize = 12
        subTitleLabel.fontColor = SKColor(red: 0.95, green: 0.82, blue: 0.35, alpha: 1.0)
        subTitleLabel.position = CGPoint(x: 0, y: -45)
        swipeCenterContainer.addChild(subTitleLabel)
        
        // 3. Garis Lengkung Lintasan Geser (Kuning Emas)
        arcPathNode = SKShapeNode()
        arcPathNode.lineWidth = 4.5
        arcPathNode.strokeColor = SKColor(red: 0.98, green: 0.85, blue: 0.30, alpha: 0.90)
        arcPathNode.lineCap = .round
        swipeCenterContainer.addChild(arcPathNode)
        
        // 5. Titik Bercahaya Jari
        fingerDotNode = SKShapeNode(circleOfRadius: 10)
        fingerDotNode.fillColor = SKColor(red: 0.98, green: 0.88, blue: 0.45, alpha: 1.0)
        fingerDotNode.strokeColor = .white
        fingerDotNode.lineWidth = 2.0
        swipeCenterContainer.addChild(fingerDotNode)
        
        // 6. Ikon Tangan 👆
        handEmojiNode = SKLabelNode(fontNamed: "HelveticaNeue")
        handEmojiNode.text = "👆"
        handEmojiNode.fontSize = 32
        handEmojiNode.verticalAlignmentMode = .center
        handEmojiNode.horizontalAlignmentMode = .center
        swipeCenterContainer.addChild(handEmojiNode)
    }
    
    // MARK: - Fungsi Memunculkan Panduan Swipe
    func showSwipeGuide(isRight: Bool, title: String? = nil) {
        removeAllActions()
        swipeCenterContainer.removeAllActions()
        
        currentIsRight = isRight
        actionTitleLabel.text = title ?? (isRight ? "SWIPE KANAN ➔" : "⬅ SWIPE KIRI")
        actionTitleLabel.fontColor = isRight ? SKColor.systemYellow : SKColor.systemYellow
        
        let startX: CGFloat = isRight ? -swipeArcWidth / 2 : swipeArcWidth / 2
        let endX: CGFloat = isRight ? swipeArcWidth / 2 : -swipeArcWidth / 2
        let startPoint = CGPoint(x: startX, y: 0)
        let endPoint = CGPoint(x: endX, y: 0)
        let controlPoint = CGPoint(x: 0, y: 24)
        
        // Buat Jalur Busur
        let path = UIBezierPath()
        path.move(to: startPoint)
        path.addQuadCurve(to: endPoint, controlPoint: controlPoint)
        arcPathNode.path = path.cgPath
        
        // Buat Kepala Panah di Ujung
        let arrowPath = UIBezierPath()
        let arrowSize: CGFloat = 8.0
        let angle: CGFloat = isRight ? 0.35 : (.pi - 0.35)
        arrowPath.move(to: endPoint)
        arrowPath.addLine(to: CGPoint(x: endPoint.x - cos(angle - 0.5) * arrowSize * 2,
                                      y: endPoint.y - sin(angle - 0.5) * arrowSize * 2))
        arrowPath.addLine(to: CGPoint(x: endPoint.x - cos(angle + 0.5) * arrowSize * 2,
                                      y: endPoint.y - sin(angle + 0.5) * arrowSize * 2))
        arrowPath.close()
        
        // Jalankan Animasi Gerakan Tangan & Titik Geser
        let animateHand = SKAction.customAction(withDuration: 0.60) { [weak self] _, time in
            guard let self = self else { return }
            let t = time / 0.60
            let oneMinusT = 1.0 - t
            let posX = oneMinusT * oneMinusT * startPoint.x + 2 * oneMinusT * t * controlPoint.x + t * t * endPoint.x
            let posY = oneMinusT * oneMinusT * startPoint.y + 2 * oneMinusT * t * controlPoint.y + t * t * endPoint.y
            
            let currentPos = CGPoint(x: posX, y: posY)
            self.fingerDotNode.position = currentPos
            self.handEmojiNode.position = CGPoint(x: posX, y: posY - 18)
            
            let alphaVal = (t < 0.1) ? t * 10 : (t > 0.85 ? (1.0 - t) * 6.6 : 1.0)
            self.fingerDotNode.alpha = alphaVal
            self.handEmojiNode.alpha = alphaVal
        }
        
        let loop = SKAction.repeatForever(SKAction.sequence([
            animateHand,
            SKAction.wait(forDuration: 0.18)
        ]))
        
        swipeCenterContainer.run(loop)
        run(SKAction.fadeIn(withDuration: 0.15))
    }
    
    // MARK: - Kompatibilitas dengan GameScene
    func showFreezePrompt(action: String, sub: String, isRight: Bool, screenSize: CGSize) {
        showSwipeGuide(isRight: isRight, title: action)
    }
    
    func showDemoPhase(step: CowboyTutorialStep, title: String, isRight: Bool) {
        showSwipeGuide(isRight: isRight, title: title)
    }
    
    func showChallengePhase(step: CowboyTutorialStep, command: String, isRight: Bool) {
        showSwipeGuide(isRight: isRight, title: command)
    }
    
    func markStepSuccess(step: CowboyTutorialStep, completion: @escaping () -> Void) {
        actionTitleLabel.text = "BAGUS!"
        actionTitleLabel.fontColor = .systemGreen
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.run(completion)
        ]))
    }
    
    func hide() {
        removeAllActions()
        swipeCenterContainer.removeAllActions()
        run(SKAction.fadeOut(withDuration: 0.15))
    }
    
    func shakeBanner() {
        swipeCenterContainer.run(SKAction.sequence([
            SKAction.moveBy(x: -10, y: 0, duration: 0.03),
            SKAction.moveBy(x: 20, y: 0, duration: 0.03),
            SKAction.moveBy(x: -10, y: 0, duration: 0.03)
        ]))
    }
}
