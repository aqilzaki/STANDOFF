//
//  TutorialOverlayNode.swift
//  aqil.game (Upright Font & Minimal Monochrome Edition)
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

class TutorialOverlayNode: SKNode {
    
    private let customFontName = "AvenirNextCondensed-Heavy"
    
    private let pureWhiteColor = UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0)
    
    // Container utama di tengah layar
    private var centerContainer: SKNode!
    
    // Teks perintah & ikon status
    private var promptLabel: SKLabelNode!
    private var statusIconSprite: SKSpriteNode!
    
    // Elemen animasi tangan & panah SF Symbols lurus
    private var handSprite: SKSpriteNode!
    private var fingerDotNode: SKShapeNode!
    private var swipeArrowSprite: SKSpriteNode!
    
    // MARK: - Elemen Highlight Peluru (Monokrom Bersih)
    private var bulletHighlightContainer: SKNode!
    private var bulletMainRing: SKShapeNode!
    private var bulletPulseWave: SKShapeNode!
    private weak var trackedBulletNode: SKNode?
    
    private let swipeDistance: CGFloat = 110.0
    
    init(size: CGSize) {
        super.init()
        zPosition = 180
        alpha = 0.0
        
        setupStraightSwipeUI(screenSize: size)
        setupBulletHighlightUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup UI Swipe Lurus Tegak
    private func setupStraightSwipeUI(screenSize: CGSize) {
        centerContainer = SKNode()
        centerContainer.position = CGPoint(x: screenSize.width / 2, y: screenSize.height * 0.40)
        addChild(centerContainer)
        
        // 1. Teks Perintah Utama (Tegak Lurus, Tebal, Warna Putih Bersih)
        promptLabel = SKLabelNode(fontNamed: customFontName)
        promptLabel.fontSize = 24
        promptLabel.fontColor = pureWhiteColor
        promptLabel.position = CGPoint(x: 10, y: 44)
        centerContainer.addChild(promptLabel)
        
        // 2. Ikon Status SF Symbols di Samping Teks (Putih Bersih)
        statusIconSprite = SKSpriteNode()
        statusIconSprite.position = CGPoint(x: -70, y: 52)
        statusIconSprite.alpha = 0.0
        centerContainer.addChild(statusIconSprite)
        
        // 3. Titik Sentuh Jari (Putih Bersih)
        fingerDotNode = SKShapeNode(circleOfRadius: 8.0)
        fingerDotNode.fillColor = pureWhiteColor
        fingerDotNode.strokeColor = .clear
        centerContainer.addChild(fingerDotNode)
        
        // 4. Ikon Tangan SF Symbols (Putih Bersih)
        let handTex = SFSymbolHelper.texture(systemName: "hand.point.up.fill", pointSize: 28, color: pureWhiteColor)
        handSprite = SKSpriteNode(texture: handTex)
        handSprite.size = CGSize(width: 28, height: 32)
        centerContainer.addChild(handSprite)
        
        // 5. Ikon Panah SF Symbols (Putih Bersih)
        swipeArrowSprite = SKSpriteNode()
        swipeArrowSprite.zPosition = 2
        centerContainer.addChild(swipeArrowSprite)
    }
    
    // MARK: - Setup UI Highlight Peluru (Cincin Putih Minimalis)
    private func setupBulletHighlightUI() {
        bulletHighlightContainer = SKNode()
        bulletHighlightContainer.zPosition = 185
        bulletHighlightContainer.alpha = 0.0
        addChild(bulletHighlightContainer)
        
        // Cincin Peluru Putih Transparan (Bukan Merah / Kuning)
        bulletMainRing = SKShapeNode(circleOfRadius: 24)
        bulletMainRing.strokeColor = pureWhiteColor
        bulletMainRing.lineWidth = 2.5
        bulletMainRing.fillColor = pureWhiteColor.withAlphaComponent(0.12)
        bulletHighlightContainer.addChild(bulletMainRing)
        
        bulletPulseWave = SKShapeNode(circleOfRadius: 24)
        bulletPulseWave.strokeColor = pureWhiteColor.withAlphaComponent(0.60)
        bulletPulseWave.lineWidth = 1.5
        bulletPulseWave.fillColor = .clear
        bulletHighlightContainer.addChild(bulletPulseWave)
    }
    
    func showBulletHighlight(at position: CGPoint) {
        bulletHighlightContainer.removeAllActions()
        bulletMainRing.removeAllActions()
        bulletPulseWave.removeAllActions()
        
        bulletHighlightContainer.position = position
        bulletHighlightContainer.alpha = 1.0
        
        let pulseMain = SKAction.sequence([
            SKAction.scale(to: 1.10, duration: 0.25),
            SKAction.scale(to: 1.0, duration: 0.25)
        ])
        bulletMainRing.run(SKAction.repeatForever(pulseMain))
        
        bulletPulseWave.setScale(1.0)
        bulletPulseWave.alpha = 0.7
        let sonarWave = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.80, duration: 0.55),
                SKAction.fadeOut(withDuration: 0.55)
            ]),
            SKAction.run { [weak self] in
                self?.bulletPulseWave.setScale(1.0)
                self?.bulletPulseWave.alpha = 0.7
            }
        ])
        bulletPulseWave.run(SKAction.repeatForever(sonarWave))
    }
    
    func followBullet(_ bulletNode: SKNode) {
        trackedBulletNode = bulletNode
        showBulletHighlight(at: bulletNode.position)
        
        let followAction = SKAction.repeatForever(SKAction.run { [weak self] in
            guard let self = self, let target = self.trackedBulletNode else { return }
            self.bulletHighlightContainer.position = target.position
        })
        bulletHighlightContainer.run(followAction, withKey: "followBulletAction")
    }
    
    func hideBulletHighlight() {
        trackedBulletNode = nil
        bulletHighlightContainer.removeAction(forKey: "followBulletAction")
        bulletHighlightContainer.run(SKAction.fadeOut(withDuration: 0.15))
    }
    
    // MARK: - Menjalankan Animasi Swipe Tegak Lurus Monokrom
    private func playStraightSwipeAnimation(isRight: Bool, text: String, isPerfect: Bool = false) {
        removeAllActions()
        centerContainer.removeAllActions()
        
        promptLabel.text = text
        promptLabel.fontColor = pureWhiteColor // 🔒 Selalu Putih Bersih
        
        if isPerfect {
            statusIconSprite.texture = SFSymbolHelper.texture(systemName: "bolt.fill", pointSize: 20, color: pureWhiteColor)
            statusIconSprite.size = CGSize(width: 18, height: 22)
            statusIconSprite.position = CGPoint(x: -75, y: 52)
            statusIconSprite.alpha = 1.0
        } else {
            statusIconSprite.alpha = 0.0
        }
        
        // Panah SF Symbol Putih Bersih
        let arrowSystemName = isRight ? "arrow.right" : "arrow.left"
        swipeArrowSprite.texture = SFSymbolHelper.texture(systemName: arrowSystemName, pointSize: 22, color: pureWhiteColor, weight: .black)
        swipeArrowSprite.size = CGSize(width: 24, height: 20)
        
        let startX: CGFloat = isRight ? -swipeDistance / 2 : swipeDistance / 2
        let endX: CGFloat = isRight ? swipeDistance / 2 : -swipeDistance / 2
        let swipeY: CGFloat = 0.0
        
        let duration: TimeInterval = isPerfect ? 0.65 : 0.90
        let arrowLeadOffset: CGFloat = isRight ? 26.0 : -26.0
        
        let animateStraightSwipe = SKAction.customAction(withDuration: duration) { [weak self] _, time in
            guard let self = self else { return }
            let t = time / CGFloat(duration)
            
            let smoothstep = t * t * (3.0 - 2.0 * t)
            let currentX = startX + (endX - startX) * smoothstep
            
            self.fingerDotNode.position = CGPoint(x: currentX, y: swipeY)
            self.handSprite.position = CGPoint(x: currentX, y: swipeY - 18)
            self.swipeArrowSprite.position = CGPoint(x: currentX + arrowLeadOffset, y: swipeY - 4)
            
            let alphaVal: CGFloat
            if t < 0.20 {
                alphaVal = t / 0.20
            } else if t > 0.80 {
                alphaVal = (1.0 - t) / 0.20
            } else {
                alphaVal = 1.0
            }
            
            self.fingerDotNode.alpha = alphaVal
            self.handSprite.alpha = alphaVal
            self.swipeArrowSprite.alpha = alphaVal
        }
        
        let swipeLoop = SKAction.repeatForever(SKAction.sequence([
            animateStraightSwipe,
            SKAction.wait(forDuration: 0.38)
        ]))
        
        centerContainer.run(swipeLoop)
        run(SKAction.fadeIn(withDuration: 0.15))
    }
    
    // MARK: - Integrasi Otomatis dengan GameScene
    
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
        hideBulletHighlight()
        
        promptLabel.text = (step == .perfectDodge) ? "PERFECT!" : "BAGUS!"
        promptLabel.fontColor = pureWhiteColor
        
        // Ikon Centang Putih Bersih
        statusIconSprite.texture = SFSymbolHelper.texture(systemName: "checkmark.circle.fill", pointSize: 22, color: pureWhiteColor)
        statusIconSprite.size = CGSize(width: 22, height: 22)
        statusIconSprite.position = CGPoint(x: -65, y: 52)
        statusIconSprite.alpha = 1.0
        
        statusIconSprite.run(SKAction.sequence([
            SKAction.scale(to: 1.35, duration: 0.10),
            SKAction.scale(to: 1.0, duration: 0.10)
        ]))
        
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.38),
            SKAction.run(completion)
        ]))
    }
    
    func hide() {
        hideBulletHighlight()
        removeAllActions()
        centerContainer.removeAllActions()
        run(SKAction.fadeOut(withDuration: 0.12))
    }
    
    func shakeBanner() {
        promptLabel.text = "SALAH ARAH!"
        promptLabel.fontColor = pureWhiteColor
        
        // Ikon Silang Putih Bersih (Tanpa Merah Mencolok)
        statusIconSprite.texture = SFSymbolHelper.texture(systemName: "xmark.circle.fill", pointSize: 20, color: pureWhiteColor)
        statusIconSprite.size = CGSize(width: 20, height: 20)
        statusIconSprite.position = CGPoint(x: -80, y: 52)
        statusIconSprite.alpha = 1.0
        
        centerContainer.run(SKAction.sequence([
            SKAction.moveBy(x: -10, y: 0, duration: 0.03),
            SKAction.moveBy(x: 20, y: 0, duration: 0.03),
            SKAction.moveBy(x: -10, y: 0, duration: 0.03)
        ]))
    }
}

typealias TutorialOverlayNode1 = TutorialOverlayNode
