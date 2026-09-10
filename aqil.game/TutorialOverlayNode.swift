//
//  TutorialOverlayNode.swift
//  aqil.game (Straight Swipe, No-Line Edition)
//
import SpriteKit
import UIKit


enum CowboyTutorialStep: Int, Equatable {
    case dodgeRight = 1
    case dodgeLeft = 2
    case feintReaction = 3
    case perfectDodge = 4
    case completed = 5
}

// MARK: - Helper Pengubah SF Symbols ke SKTexture
private struct SFSymbolHelper {
    static func texture(systemName: String, pointSize: CGFloat, color: UIColor = .white, weight: UIImage.SymbolWeight = .bold) -> SKTexture {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        if let baseImage = UIImage(systemName: systemName, withConfiguration: config) {
            let tinted = baseImage.withTintColor(color, renderingMode: .alwaysOriginal)
            let tex = SKTexture(image: tinted)
            tex.filteringMode = .linear
            return tex
        }
        return SKTexture()
    }
}

class TutorialOverlayNode1: SKNode {
    
    // Container utama di tengah layar
    private var centerContainer: SKNode!
    
    // Teks perintah & ikon SF Symbols status
    private var promptLabel: SKLabelNode!
    private var statusIconSprite: SKSpriteNode!
    
    // Elemen animasi tangan lurus (Tanpa Garis)
    private var handSprite: SKSpriteNode!
    private var fingerDotNode: SKShapeNode!
    
    // Cincin emas khusus momen Perfect Dodge
    private var slowMoHaloNode: SKShapeNode!
    
    // Jarak lintasan swipe lurus (horizontal)
    private let swipeDistance: CGFloat = 110.0
    
    init(size: CGSize) {
        super.init()
        zPosition = 180
        alpha = 0.0
        
        setupStraightSwipeUI(screenSize: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI Swipe Lurus (Bebas Garis)
    private func setupStraightSwipeUI(screenSize: CGSize) {
        centerContainer = SKNode()
        centerContainer.position = CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.40)
        addChild(centerContainer)
        
        // 1. Teks Perintah Utama (Tebal & Bersih)
        promptLabel = SKLabelNode(fontNamed: "HelveticaNeue-Black")
        promptLabel.fontSize = 24
        promptLabel.fontColor = SKColor(red: 0.98, green: 0.85, blue: 0.30, alpha: 1.0)
        promptLabel.position = CGPoint(x: 14, y: 44)
        centerContainer.addChild(promptLabel)
        
        // 2. Ikon Status SF Symbols (Petir / Centang / Silang)
        statusIconSprite = SKSpriteNode()
        statusIconSprite.position = CGPoint(x: -65, y: 52)
        statusIconSprite.alpha = 0.0
        centerContainer.addChild(statusIconSprite)
        
        // 3. Titik Sentuh Jari (Glowing Tap Dot)
        fingerDotNode = SKShapeNode(circleOfRadius: 8.5)
        fingerDotNode.fillColor = SKColor(red: 0.98, green: 0.88, blue: 0.45, alpha: 0.9)
        fingerDotNode.strokeColor = .white
        fingerDotNode.lineWidth = 1.5
        centerContainer.addChild(fingerDotNode)
        
        // 4. Ikon Tangan SF Symbols ("hand.point.up.fill")
        let handTex = SFSymbolHelper.texture(systemName: "hand.point.up.fill", pointSize: 28, color: .white)
        handSprite = SKSpriteNode(texture: handTex)
        handSprite.size = CGSize(width: 30, height: 34)
        centerContainer.addChild(handSprite)
        
        // 5. Cincin Emas Berdenyut (Khusus Perfect Dodge)
        slowMoHaloNode = SKShapeNode(circleOfRadius: 36)
        slowMoHaloNode.strokeColor = SKColor(red: 0.98, green: 0.85, blue: 0.25, alpha: 0.95)
        slowMoHaloNode.lineWidth = 3.0
        slowMoHaloNode.fillColor = SKColor(red: 0.98, green: 0.85, blue: 0.25, alpha: 0.15)
        slowMoHaloNode.zPosition = -1
        slowMoHaloNode.alpha = 0.0
        centerContainer.addChild(slowMoHaloNode)
    }
    
    // MARK: - Menjalankan Animasi Swipe Lurus Murni
    private func playStraightSwipeAnimation(isRight: Bool, text: String, isPerfect: Bool = false) {
        removeAllActions()
        centerContainer.removeAllActions()
        
        promptLabel.text = text
        promptLabel.fontColor = isPerfect ? SKColor(red: 1.0, green: 0.85, blue: 0.20, alpha: 1.0) : (isRight ? SKColor.systemYellow : SKColor.systemCyan)
        
        if isPerfect {
            statusIconSprite.texture = SFSymbolHelper.texture(systemName: "bolt.fill", pointSize: 22, color: UIColor(red: 1.0, green: 0.85, blue: 0.20, alpha: 1.0))
            statusIconSprite.size = CGSize(width: 20, height: 24)
            statusIconSprite.position = CGPoint(x: -80, y: 52)
            statusIconSprite.alpha = 1.0
        } else {
            statusIconSprite.alpha = 0.0
        }
        
        // Titik Awal & Akhir Garis Lurus Horizontal (Y selalu 0)
        let startX: CGFloat = isRight ? -swipeDistance / 2 : swipeDistance / 2
        let endX: CGFloat = isRight ? swipeDistance / 2 : -swipeDistance / 2
        let swipeY: CGFloat = 0.0
        
        let duration: TimeInterval = isPerfect ? 0.38 : 0.50
        
        let animateStraightSwipe = SKAction.customAction(withDuration: duration) { [weak self] _, time in
            guard let self = self else { return }
            let t = time / CGFloat(duration)
            
            // Easing kuadratik untuk akselerasi lurus yang natural (cepat meluncur lalu melambat di ujung)
            let easeOut = 1.0 - pow(1.0 - t, 2.5)
            let currentX = startX + (endX - startX) * easeOut
            
            self.fingerDotNode.position = CGPoint(x: currentX, y: swipeY)
            self.handSprite.position = CGPoint(x: currentX, y: swipeY - 18)
            
            // Efek muncul halus di awal dan memudar di ujung geseran
            let alphaVal = (t < 0.12) ? t * 8.3 : (t > 0.80 ? (1.0 - t) * 5.0 : 1.0)
            self.fingerDotNode.alpha = alphaVal
            self.handSprite.alpha = alphaVal
        }
        
        let swipeLoop = SKAction.repeatForever(SKAction.sequence([
            animateStraightSwipe,
            SKAction.wait(forDuration: 0.22) // Jeda sebentar sebelum mengulang gesekan berikutnya
        ]))
        
        centerContainer.run(swipeLoop)
        run(SKAction.fadeIn(withDuration: 0.12))
    }
    
    // MARK: - Integrasi Otomatis dengan GameScene (Fungsi Tetap Sama)
    
    func showChallengePhase(step: CowboyTutorialStep, command: String, isRight: Bool) {
        switch step {
        case .dodgeRight:
            playStraightSwipeAnimation(isRight: true, text: "SWIPE KANAN")
            
        case .dodgeLeft:
            playStraightSwipeAnimation(isRight: false, text: "SWIPE KIRI")
            
        case .feintReaction:
            playStraightSwipeAnimation(isRight: false, text: "BACA TIPUAN!")
            
        case .perfectDodge:
            playStraightSwipeAnimation(isRight: true, text: "SEKARANG!", isPerfect: true)
            
        case .completed:
            hide()
        }
    }
    
    func showDemoPhase(step: CowboyTutorialStep, title: String, isRight: Bool) {
        showChallengePhase(step: step, command: title, isRight: isRight)
    }
    
    func showSwipeGuide(isRight: Bool, title: String? = nil) {
        playStraightSwipeAnimation(isRight: isRight, text: title ?? (isRight ? "SWIPE KANAN" : "SWIPE KIRI"))
    }
    
    func showFreezePrompt(action: String, sub: String, isRight: Bool, screenSize: CGSize) {
        playStraightSwipeAnimation(isRight: isRight, text: action)
    }
    
    func markStepSuccess(step: CowboyTutorialStep, completion: @escaping () -> Void) {
        promptLabel.text = (step == .perfectDodge) ? "PERFECT!" : "BAGUS!"
        promptLabel.fontColor = .systemGreen
        
        statusIconSprite.texture = SFSymbolHelper.texture(systemName: "checkmark.circle.fill", pointSize: 24, color: .systemGreen)
        statusIconSprite.size = CGSize(width: 24, height: 24)
        statusIconSprite.position = CGPoint(x: -70, y: 52)
        statusIconSprite.alpha = 1.0
        
        statusIconSprite.run(SKAction.sequence([
            SKAction.scale(to: 1.4, duration: 0.10),
            SKAction.scale(to: 1.0, duration: 0.10)
        ]))
        
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.38),
            SKAction.run(completion)
        ]))
    }
    
    func hide() {
        removeAllActions()
        centerContainer.removeAllActions()
        run(SKAction.fadeOut(withDuration: 0.12))
    }
    
    func shakeBanner() {
        promptLabel.text = "SALAH ARAH!"
        promptLabel.fontColor = .systemRed
        
        statusIconSprite.texture = SFSymbolHelper.texture(systemName: "xmark.circle.fill", pointSize: 22, color: .systemRed)
        statusIconSprite.size = CGSize(width: 22, height: 22)
        statusIconSprite.position = CGPoint(x: -85, y: 52)
        statusIconSprite.alpha = 1.0
        
        centerContainer.run(SKAction.sequence([
            SKAction.moveBy(x: -10, y: 0, duration: 0.03),
            SKAction.moveBy(x: 20, y: 0, duration: 0.03),
            SKAction.moveBy(x: -10, y: 0, duration: 0.03)
        ]))
    }
}

