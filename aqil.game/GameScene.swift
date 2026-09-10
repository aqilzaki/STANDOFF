//
//  GameScene.swift
//  aqil.game
//
import SpriteKit
import UIKit

class GameScene: SKScene {
    
    private enum FlowState: Equatable {
        case onboarding
        case tutorial(step: CowboyTutorialStep)
        case playing
        case gameOver
    }
    
    private enum DuelPhase {
        case standoff
        case handApproaching
        case shooting
    }
    
    private enum ShootSide {
        case left
        case right
        var opposite: ShootSide { self == .left ? .right : .left }
    }
    
    private enum FeintBehavior {
        case none
        case trueSwitch
        case fakeHesitation
    }
    
    // Nodes Karakter & Efek
    private var enemyCowboy: CowboyNode!
    private var playerCowboy: CowboyNode!
    private var bloodVignetteSprite: SKSpriteNode!
    private var flashOverlay: SKShapeNode!
    
    // Modul UI (Masing-masing di file terpisah)
    private var welcomeOverlay: WelcomeOverlayNode?
    private var tutorialOverlay: TutorialOverlayNode1!
    private var gameOverOverlay: GameOverOverlayNode?
    
    // State Duel
    private var flowState: FlowState = .onboarding
    private var duelPhase: DuelPhase = .standoff
    private var currentAimSide: ShootSide = .left
    private var currentFeintBehavior: FeintBehavior = .none
    private var playerDodgedSide: ShootSide? = nil
    
    private let dodgeOffsetDistance: CGFloat = 52.0
    private var scoreBoardSprite: SKSpriteNode!
    
    // State Tutorial
    private var isTutorialFrozen: Bool = false
    private var currentTutorialBullet: SKNode?
    private var isTutorialChallengeActive: Bool = false
    
    // Level Aktif
    private var activeLevelConfig: LevelConfig = LevelSystem.levels.first!
    
    // Timing Peluru & Dodge
    private var bulletFiredTime: TimeInterval = 0
    private var bulletFlightDuration: TimeInterval = 0.28
    private var playerDodgeTime: TimeInterval = 0
    private var isCloseCallDodge: Bool = false
    private var hasDodgedThisRound: Bool = false
    
    
    private var perfectBadgeTex: SKTexture?
    
    // Input Swipe
    private var touchStartPoint: CGPoint?
    private var hasSwipedInCurrentTouch: Bool = false
    private let minSwipeDistance: CGFloat = 26.0
    
    // Stats & Skor
    private var playerLives: Int = 3 { didSet { updateHeartsUI() } }
    private var score: Int = 0 { didSet { updateScoreUI() } }
    private var bestScore: Int = 0 { didSet { bestScoreLabel.text = "BEST: \(bestScore)" } }
    private var comboCount: Int = 0 {
        didSet {
            comboLabel.text = comboCount > 1 ? "KOMBO x\(comboCount)" : ""
            comboLabel.fontColor = .systemYellow
        }
    }
    private var maxComboInRun: Int = 0
    private var totalDuels: Int = 0
    
    // HUD Nodes Minimalis
    private let scoreLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
    private let bestScoreLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
    private let comboLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
    private let roundLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
    
    private var heartSprites: [SKSpriteNode] = []
    private var heartFullTexture: SKTexture!
    private var heartEmptyTexture: SKTexture!
    
    //color
    private let pureBlackColor = UIColor(red: 0.08, green: 0.07, blue: 0.06, alpha: 1.0) // Hex: #141210
    private let softWhiteColor = UIColor(red: 0.98, green: 0.97, blue: 0.94, alpha: 1.0) // Hex: #FAF7F0
    private let goldenAmberColor = UIColor(red: 0.96, green: 0.78, blue: 0.24, alpha: 1.0) // Hex: #F5C73D
    
    
    // Haptics
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationHaptic = UINotificationFeedbackGenerator()
    
    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        SoundManager.shared.preload("bgm.mp3")
        SoundManager.shared.preload("gunshot.mp3")
        SoundManager.shared.preload("lonceng.mp3")
        SoundManager.shared.preload("desert_wind.mp3")
        
        backgroundColor = SKColor(red: 0.94, green: 0.91, blue: 0.85, alpha: 1.0)
        view.isMultipleTouchEnabled = false
        
        lightHaptic.prepare()
        heavyHaptic.prepare()
        notificationHaptic.prepare()
        SoundManager.shared.play("bgm.mp3",volume: 0.3)
        bestScore = UserDefaults.standard.integer(forKey: "BestCowboyDodgeScore")
      
        setupBackground()
        setupVisualOverlays()
        setupCharacters()
        setupHUD()
        setupTutorial()
        updateHeartsUI()
    
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.20),
            SKAction.run { [weak self] in self?.showWelcomeScreen() }
        ]))
    }
    
    private func setupVisualOverlays() {
        let bloodTexture = BloodVignetteHelper.generateTexture(screenSize: size)
        bloodVignetteSprite = SKSpriteNode(texture: bloodTexture, size: size)
        bloodVignetteSprite.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bloodVignetteSprite.zPosition = 85
        bloodVignetteSprite.alpha = 0.0
        addChild(bloodVignetteSprite)
        
        flashOverlay = SKShapeNode(rectOf: size)
        flashOverlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        flashOverlay.fillColor = SKColor.white.withAlphaComponent(0.50)
        flashOverlay.strokeColor = .clear
        flashOverlay.zPosition = 86
        flashOverlay.alpha = 0.0
        addChild(flashOverlay)
    }
    
    private func setupCharacters() {
        enemyCowboy = CowboyNode(color: .black)
        enemyCowboy.position = CGPoint(x: size.width / 2, y: size.height * 0.68)
        enemyCowboy.setScale(1.35)
        enemyCowboy.zPosition = 20
        addChild(enemyCowboy)
        
        playerCowboy = CowboyNode(color: SKColor(white: 0.12, alpha: 1.0))
        playerCowboy.position = CGPoint(x: size.width / 2, y: 140)
        playerCowboy.setScale(1.75)
        playerCowboy.zPosition = 25
        addChild(playerCowboy)
    }
    
    private func setupHUD() {
        let topMargin: CGFloat = 60.0
        let sideMargin: CGFloat = 24.0
            
        bestScoreLabel.text = "BEST: \(bestScore)"
        bestScoreLabel.fontSize = 14
        bestScoreLabel.fontColor = SKColor(red: 0.50, green: 0.35, blue: 0.20, alpha: 1.0) // Warna cokelat kulit klasik
        bestScoreLabel.horizontalAlignmentMode = .left
        bestScoreLabel.verticalAlignmentMode = .center
        bestScoreLabel.position = CGPoint(x: sideMargin, y: size.height - topMargin - 4)
        bestScoreLabel.zPosition = 100
        addChild(bestScoreLabel)
         
        let boardTexture = SKTexture(imageNamed: "score_board")
        boardTexture.filteringMode = .nearest
            
        let boardSize = CGSize(width: 124, height: 72)
        scoreBoardSprite = SKSpriteNode(texture: boardTexture, size: boardSize)
        scoreBoardSprite.position = CGPoint(x: size.width / 2, y: size.height - topMargin - 42)
        scoreBoardSprite.zPosition = 100
        addChild(scoreBoardSprite)
            
        scoreLabel.text = "\(score)"
        scoreLabel.fontSize = 32
        scoreLabel.fontColor = SKColor(red: 0.98, green: 0.94, blue: 0.82, alpha: 1.0) // Krem gading terang
        scoreLabel.verticalAlignmentMode = .center
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: 0, y: -2)
        scoreLabel.zPosition = 1
        scoreBoardSprite.addChild(scoreLabel)
            
          
        heartFullTexture = SKTexture(imageNamed: "heart_full")
        heartEmptyTexture = SKTexture(imageNamed: "heart_empty")
        heartFullTexture.filteringMode = .nearest
        heartEmptyTexture.filteringMode = .nearest
            
        let heartSize = CGSize(width: 26, height: 26)
        let spacing: CGFloat = 28.0
        let startX = size.width - sideMargin - (spacing * 2)
        let heartY = size.height - topMargin - 4
        
        heartSprites.removeAll()
        for i in 0..<3 {
        let heart = SKSpriteNode(texture: heartFullTexture)
        heart.size = heartSize
        heart.position = CGPoint(x: startX + CGFloat(i) * spacing, y: heartY)
        heart.zPosition = 100
        addChild(heart)
        heartSprites.append(heart)
        }

        roundLabel.text = "RONDE 1"
        roundLabel.fontSize = 12.5
        roundLabel.fontColor = self.pureBlackColor
        roundLabel.horizontalAlignmentMode = .center
        roundLabel.position = CGPoint(x: size.width / 2, y: size.height - topMargin - 86)
        roundLabel.zPosition = 100
        addChild(roundLabel)
            
        comboLabel.text = ""
        comboLabel.fontSize = 15
        comboLabel.fontColor = self.pureBlackColor
        comboLabel.horizontalAlignmentMode = .center
        comboLabel.position = CGPoint(x: size.width / 2, y: size.height - topMargin - 106)
        comboLabel.zPosition = 100
        addChild(comboLabel)
    }
    
    private func setupTutorial() {
        tutorialOverlay = TutorialOverlayNode1(size: size)
        addChild(tutorialOverlay)
    }
    
    // MARK: - Setup Background Tunggal Ilustrasi Gurun
        private func setupBackground() {
            // Warna dasar gelap jika ada sisa ruang di notch/bezel
            backgroundColor = SKColor(red: 0.10, green: 0.08, blue: 0.06, alpha: 1.0)
            
            let bg = SKSpriteNode(imageNamed: "desert_background")
            bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
            bg.zPosition = -10 // Paling belakang di balik semua karakter dan peluru
            
            // Teknik Aspect Fill: Gambar otomatis memenuhi layar tanpa tertarik/gepeng
            if let textureSize = bg.texture?.size() {
                let maxScale = max(size.width / textureSize.width, size.height / textureSize.height)
                bg.size = CGSize(width: textureSize.width * maxScale, height: textureSize.height * maxScale)
            } else {
                bg.size = size
            }
            
            bg.texture?.filteringMode = .nearest
            addChild(bg)
        }
    
        /// Helper untuk memunculkan objek kaktus/batu lengkap dengan bayangan tanah
        private func spawnProp(imageName: String,
                               fallbackCactus: String?,
                               fallbackRock: String?,
                               at point: CGPoint,
                               scale: CGFloat,
                               alpha: CGFloat = 1.0,
                               zPosition: CGFloat) {
            
            let container = SKNode()
            container.position = point
            container.zPosition = zPosition
            container.alpha = alpha
            addChild(container)
            
            // 1. Bayangan Oval di Tanah (Membuat objek menapak di tanah)
            let shadowWidth: CGFloat = 68.0 * scale
            let shadowHeight: CGFloat = 18.0 * scale
            let shadow = SKShapeNode(ellipseOf: CGSize(width: shadowWidth, height: shadowHeight))
            shadow.fillColor = SKColor.black.withAlphaComponent(0.14)
            shadow.strokeColor = .clear
            shadow.position = CGPoint(x: 0, y: -10 * scale)
            container.addChild(shadow)
            
            // 2. Sprite Objek
            let sprite = SKSpriteNode(imageNamed: imageName)
            sprite.texture?.filteringMode = .nearest // Menjaga detail pixel tetap tajam
            sprite.setScale(scale)
            sprite.anchorPoint = CGPoint(x: 0.5, y: 0.15)
            container.addChild(sprite)
        }
    
    private func updateHeartsUI() {
            guard heartSprites.count == 3 else { return }
            
            for (index, heart) in heartSprites.enumerated() {
                let shouldBeFull = (index < playerLives)
                
                if shouldBeFull {
                    heart.texture = heartFullTexture
                    heart.alpha = 1.0
                } else {
                    // Efek Juice: Jika hati baru saja hilang, beri animasi membal & ganti ke hati kosong
                    if heart.texture == heartFullTexture {
                        heart.run(SKAction.sequence([
                            SKAction.group([
                                SKAction.scale(to: 1.35, duration: 0.08),
                                SKAction.colorize(with: .systemRed, colorBlendFactor: 1.0, duration: 0.08)
                            ]),
                            SKAction.run { [weak self] in
                                heart.texture = self?.heartEmptyTexture
                                heart.colorBlendFactor = 0.0
                            },
                            SKAction.scale(to: 1.0, duration: 0.12),
                            SKAction.fadeAlpha(to: 0.75, duration: 0.1)
                        ]))
                    } else {
                        heart.texture = heartEmptyTexture
                        heart.alpha = 0.75
                    }
                }
            }
            
            updateBloodVignetteState()
        }
    
    private func updateBloodVignetteState() {
        bloodVignetteSprite.removeAllActions()
        switch playerLives {
        case 3:
            bloodVignetteSprite.run(SKAction.fadeOut(withDuration: 0.35))
        case 2:
            bloodVignetteSprite.run(SKAction.fadeAlpha(to: 0.58, duration: 0.25))
        case 1:
            let heartbeat = SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 1.0, duration: 0.35),
                SKAction.fadeAlpha(to: 0.52, duration: 0.45)
            ]))
            bloodVignetteSprite.run(heartbeat)
        default:
            bloodVignetteSprite.alpha = 1.0
        }
    }
    
    private func updateScoreUI() {
            scoreLabel.text = "\(score)"
            
            // Animasi pop/membal pada seluruh papan kayu
            scoreBoardSprite?.removeAction(forKey: "scoreBounce")
            let popUp = SKAction.scale(to: 1.12, duration: 0.06)
            let popDown = SKAction.scale(to: 1.0, duration: 0.08)
            scoreBoardSprite?.run(SKAction.sequence([popUp, popDown]), withKey: "scoreBounce")
        }
    
    // MARK: - JUICE: Pop-Up Stiker "PERFECT" 
        private func triggerPerfectDodgeBadgeJuice(texture: SKTexture) {
            let midX = size.width / 2.0
            let midY = size.height * 0.50
            
            let container = SKNode()
            container.position = CGPoint(x: midX, y: midY)
            container.zPosition = 160
            addChild(container)
            
            // 1. Gelombang Kejut Cepat (Shockwave Ring)
            let shockwave = SKShapeNode(circleOfRadius: 28)
            shockwave.strokeColor = SKColor(red: 0.98, green: 0.85, blue: 0.28, alpha: 0.95)
            shockwave.lineWidth = 4.0
            shockwave.fillColor = .clear
            container.addChild(shockwave)
            
            shockwave.run(SKAction.sequence([
                SKAction.group([
                    SKAction.scale(to: 4.8, duration: 0.16),
                    SKAction.fadeOut(withDuration: 0.16)
                ]),
                SKAction.removeFromParent()
            ]))
            
            // 2. Percikan Bintang Emas Cepat
            for i in 0..<8 {
                let spark = SKShapeNode(rectOf: CGSize(width: 4.0, height: 12.0))
                spark.fillColor = SKColor(red: 0.98, green: 0.75, blue: 0.15, alpha: 1.0)
                spark.strokeColor = .white
                spark.lineWidth = 0.5
                
                let angle = (CGFloat(i) / 8.0) * CGFloat.pi * 2.0
                spark.zRotation = angle - CGFloat.pi / 2.0
                container.addChild(spark)
                
                let distance: CGFloat = 85.0
                let targetPoint = CGPoint(x: cos(angle) * distance, y: sin(angle) * distance)
                spark.run(SKAction.sequence([
                    SKAction.group([
                        SKAction.move(to: targetPoint, duration: 0.15),
                        SKAction.fadeOut(withDuration: 0.15)
                    ]),
                    SKAction.removeFromParent()
                ]))
            }
            
            // 3. Stiker Gambar Utama (Besar, Tegak Lurus, Pop Cepat)
            texture.filteringMode = .nearest
            let badge = SKSpriteNode(texture: texture)
            badge.size = CGSize(width: 220, height: 220)
            badge.zRotation = 0
            badge.alpha = 0.0
            badge.setScale(1.8)
            container.addChild(badge)
            
            // Animasi Cepat & Renyah (Tanpa jeda lama)
            let slamIn = SKAction.group([
                SKAction.fadeIn(withDuration: 0.04),
                SKAction.scale(to: 0.95, duration: 0.07)
            ])
            slamIn.timingMode = .easeIn
            
            let bounceUp = SKAction.scale(to: 1.05, duration: 0.05)
            let settle = SKAction.scale(to: 1.0, duration: 0.04)
            
            let quickHold = SKAction.wait(forDuration: 0.18) // Tampil singkat, langsung lanjut
            
            let quickFadeOut = SKAction.group([
                SKAction.moveBy(x: 0, y: 20, duration: 0.14),
                SKAction.scale(to: 1.15, duration: 0.14),
                SKAction.fadeOut(withDuration: 0.14)
            ])
            
            badge.run(SKAction.sequence([
                slamIn,
                bounceUp,
                settle,
                quickHold,
                quickFadeOut,
                SKAction.removeFromParent()
            ])) {
                container.removeFromParent()
            }
        }
    
    // MARK: - Welcome & Tutorial Flow
    private func showWelcomeScreen() {
        flowState = .onboarding
        welcomeOverlay?.removeFromParent()
        
        let overlay = WelcomeOverlayNode(size: size) { [weak self] in
            self?.startTutorialFlow()
        }
        addChild(overlay)
        self.welcomeOverlay = overlay
    }
    
    private func startTutorialFlow() {
        roundLabel.text = "TUTORIAL"
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.run { [weak self] in self?.executeTutorialStep(step: .dodgeRight) }
        ]))
    }
    
        private func executeTutorialStep(step: CowboyTutorialStep) {
            flowState = .tutorial(step: step)
            playerDodgedSide = nil
            hasDodgedThisRound = false
            hasSwipedInCurrentTouch = false
            isTutorialChallengeActive = false
            
            currentTutorialBullet?.removeFromParent()
            currentTutorialBullet = nil
            
            enemyCowboy.removeAllActions()
            enemyCowboy.position = CGPoint(x: size.width / 2, y: size.height * 0.68)
            enemyCowboy.setArmsToWideStance()
            playerCowboy.run(SKAction.move(to: CGPoint(x: size.width / 2, y: 140), duration: 1.15))
            
            // Jeda 0.4 detik agar pemain siap, lalu musuh LANGSUNG MENEMBAK & PEMAIN SWIPE SENDIRI!
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.40),
                SKAction.run { [weak self] in
                    guard let self = self else { return }
                    switch step {
                    case .dodgeRight:
                        self.startChallengeForStep(step: step, command: "SWIPE KANAN ➔", isRight: true)
                        
                    case .dodgeLeft:
                        self.startChallengeForStep(step: step, command: "⬅ SWIPE KIRI", isRight: false)
                        
                    case .feintReaction:
                        self.startChallengeForStep(step: step, command: "⬅ BACA TIPUAN!", isRight: false)
                        
                    case .perfectDodge:
                        self.startChallengeForStep(step: step, command: "⚡ SEKARANG!", isRight: true)
                        
                    case .completed:
                        self.completeTutorialAndStartGame()
                    }
                }
            ]))
        }
    
    /// Menjalankan Tembakan Nyata saat Pemain Simulasi
    private func startChallengeForStep(step: CowboyTutorialStep, command: String, isRight: Bool) {
            isTutorialChallengeActive = true
            tutorialOverlay.showChallengePhase(step: step, command: command, isRight: isRight)
            fireChallengeShot(step: step, command: command, isRight: isRight)
        }
    /// Menembakkan peluru challenge dengan deteksi kena tembak otomatis
        private func fireChallengeShot(step: CowboyTutorialStep, command: String, isRight: Bool) {
            guard case .tutorial(let curStep) = flowState, curStep == step else { return }
            
            // Reset state ronde tantangan
            playerDodgedSide = nil
            hasDodgedThisRound = false
            hasSwipedInCurrentTouch = false
            
            let isLeftShoot = (step == .dodgeRight || step == .perfectDodge)
            currentAimSide = isLeftShoot ? .left : .right
            let safeSide: ShootSide = isLeftShoot ? .right : .left
            
            enemyCowboy.animateApproachWithShoulderShift(isLeft: isLeftShoot, duration: 0.38) { [weak self] in
                guard let self = self, self.isTutorialChallengeActive else { return }
                
                if step == .feintReaction {
                    // Tipuan Eitss: Tangan kiri turun -> batal ganti tembak kanan
                    self.popEitssJuice()
                    self.heavyHaptic.impactOccurred(intensity: 0.6)
                    self.enemyCowboy.snapSwitchHands(fromLeftToRight: true, duration: 0.20) {
                        self.currentAimSide = .right
                        self.enemyCowboy.drawGunAndShoot(isLeft: false)
                        self.triggerEnemyFireJuice(fromLeft: false)
                        self.launchChallengeBullet(fromLeft: false, safeSide: .left, duration: 1.0, step: step, command: command, isRight: isRight)
                    }
                } else if step == .perfectDodge {
                    // Peluru melambat di depan dada memberi jendela Perfect Dodge
                    self.enemyCowboy.drawGunAndShoot(isLeft: true)
                    self.triggerEnemyFireJuice(fromLeft: true)
                    self.launchChallengeBullet(fromLeft: true, safeSide: .right, duration: 1.45, isSlowMo: true, step: step, command: command, isRight: isRight)
                } else {
                    self.enemyCowboy.drawGunAndShoot(isLeft: isLeftShoot)
                    self.triggerEnemyFireJuice(fromLeft: isLeftShoot)
                    self.launchChallengeBullet(fromLeft: isLeftShoot, safeSide: safeSide, duration: 1.10, step: step, command: command, isRight: isRight)
                }
            }
        }
    
    /// Penanganan saat pemain gagal/tertembak di tutorial (Reset & Tembak Ulang)
        private func handleTutorialChallengeFailure(for step: CowboyTutorialStep, command: String, isRight: Bool) {
            guard isTutorialChallengeActive else { return }
            
            // 1. Efek kena tembak ringan (tanpa mengurangi nyawa asli)
            lightHaptic.impactOccurred(intensity: 0.8)
            notificationHaptic.notificationOccurred(.warning)
            tutorialOverlay.shakeBanner()
            
            playerCowboy.run(SKAction.sequence([
                SKAction.colorize(with: .systemRed, colorBlendFactor: 0.8, duration: 0.08),
                SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.12)
            ]))
            
            // 2. Kembalikan posisi pemain ke tengah
            playerCowboy.run(SKAction.move(to: CGPoint(x: size.width / 2, y: 140), duration: 0.15))
            
            // 3. Jeda sejenak, lalu musuh otomatis MENEMBAK ULANG!
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.75),
                SKAction.run { [weak self] in
                    guard let self = self, self.isTutorialChallengeActive else { return }
                    self.fireChallengeShot(step: step, command: command, isRight: isRight)
                }
            ]))
        }
    
    // MARK: - Peluru Challenge dengan Highlight Terang & Cincin Target
        private func launchChallengeBullet(fromLeft: Bool, safeSide: ShootSide, duration: TimeInterval, isSlowMo: Bool = false, step: CowboyTutorialStep, command: String, isRight: Bool) {
            let bulletX = enemyCowboy.position.x + (fromLeft ? -22 : 22)
            let startY = enemyCowboy.position.y - 18
            let targetY: CGFloat = 110.0
            
            let container = SKNode()
            container.position = CGPoint(x: bulletX, y: startY)
            container.zPosition = 45 // Di atas karakter agar selalu terlihat jelas
            addChild(container)
            self.currentTutorialBullet = container
            
            let isPerfectStep = (step == .perfectDodge || isSlowMo)
            
            // 1. Ekor Jejak Peluru (Menyala Emas saat Perfect Dodge)
            let trail = SKShapeNode(rectOf: CGSize(width: isPerfectStep ? 3.5 : 2.5, height: 32), cornerRadius: 1.5)
            trail.fillColor = isPerfectStep ? SKColor(red: 1.0, green: 0.85, blue: 0.20, alpha: 0.55) : SKColor(white: 0.2, alpha: 0.35)
            trail.strokeColor = .clear
            trail.position = CGPoint(x: 0, y: 14)
            container.addChild(trail)
            
            // 2. Batang Peluru Utama (Outline Emas Menyala)
            let bullet = SKShapeNode(rectOf: CGSize(width: isPerfectStep ? 4.5 : 3.5, height: 18), cornerRadius: 2.0)
            bullet.fillColor = .black
            bullet.strokeColor = isPerfectStep ? SKColor(red: 1.0, green: 0.88, blue: 0.25, alpha: 1.0) : .clear
            bullet.lineWidth = isPerfectStep ? 2.0 : 0.0
            container.addChild(bullet)
            
            if isPerfectStep {
                // A. Cincin Target Utama
                let targetRing = SKShapeNode(circleOfRadius: 26)
                targetRing.strokeColor = SKColor(red: 1.0, green: 0.85, blue: 0.20, alpha: 0.95)
                targetRing.lineWidth = 3.5
                targetRing.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.20, alpha: 0.18)
                targetRing.position = .zero
                container.addChild(targetRing)
                
                // B. 4 Garis Pembidik Target (Crosshair Ticks)
                for angle in [0.0, Double.pi / 2, Double.pi, Double.pi * 1.5] {
                    let tick = SKShapeNode(rectOf: CGSize(width: 2.5, height: 8))
                    tick.fillColor = SKColor(red: 1.0, green: 0.88, blue: 0.25, alpha: 1.0)
                    tick.strokeColor = .clear
                    tick.position = CGPoint(x: cos(angle) * 26, y: sin(angle) * 26)
                    tick.zRotation = CGFloat(angle)
                    container.addChild(tick)
                }
                
                // C. Gelombang Sonar Radar Membesar (Pulsing Sonar Wave)
                let sonarWave = SKShapeNode(circleOfRadius: 26)
                sonarWave.strokeColor = SKColor(red: 1.0, green: 0.85, blue: 0.20, alpha: 0.8)
                sonarWave.lineWidth = 2.0
                sonarWave.fillColor = .clear
                container.addChild(sonarWave)
                
                let pulseLoop = SKAction.repeatForever(SKAction.sequence([
                    SKAction.group([
                        SKAction.scale(to: 1.85, duration: 0.40),
                        SKAction.fadeOut(withDuration: 0.40)
                    ]),
                    SKAction.run {
                        sonarWave.setScale(1.0)
                        sonarWave.alpha = 0.8
                    }
                ]))
                sonarWave.run(pulseLoop)
                
                // Denyut Cincin Utama
                targetRing.run(SKAction.repeatForever(SKAction.sequence([
                    SKAction.scale(to: 1.15, duration: 0.20),
                    SKAction.scale(to: 1.0, duration: 0.20)
                ])))
            }
            
            // 4. Pergerakan Peluru (Cepat lalu Slow-Mo di Depan Dada)
            let flyAction: SKAction
            if isSlowMo {
                let fastToChest = SKAction.move(to: CGPoint(x: bulletX, y: 195), duration: 0.38)
                let triggerSlowMo = SKAction.run { [weak self] in
                    self?.lightHaptic.impactOccurred(intensity: 0.8)
                }
                let slowMoPass = SKAction.move(to: CGPoint(x: bulletX, y: targetY), duration: duration) // Merayap lambat di depan dada
                flyAction = SKAction.sequence([fastToChest, triggerSlowMo, slowMoPass])
            } else {
                flyAction = SKAction.move(to: CGPoint(x: bulletX, y: targetY), duration: duration)
            }
            
            let evaluateHit = SKAction.run { [weak self] in
                guard let self = self, self.isTutorialChallengeActive else { return }
                self.spawnGroundImpactJuice(at: CGPoint(x: bulletX, y: targetY))
                
                let isSafe = (self.hasDodgedThisRound && self.playerDodgedSide == safeSide)
                if !isSafe {
                    self.handleTutorialChallengeFailure(for: step, command: command, isRight: isRight)
                }
            }
            
            container.run(SKAction.sequence([flyAction, evaluateHit, SKAction.removeFromParent()]))
        }
    
    /// Peluru khusus Step 4: Lingkaran emas berdenyut MENEMPEL pada peluru yang merayap lambat
        private func spawnTutorialSlowMoBullet(fromLeft: Bool) {
            let bulletX = enemyCowboy.position.x + (fromLeft ? -22 : 22)
            let startY = enemyCowboy.position.y - 18
            let slowMoY: CGFloat = 195.0
            let targetY: CGFloat = 110.0
            
            let bulletContainer = SKNode()
            bulletContainer.position = CGPoint(x: bulletX, y: startY)
            bulletContainer.zPosition = 35
            addChild(bulletContainer)
            self.currentTutorialBullet = bulletContainer
            
            // Ekor Jejak Peluru
            let trail = SKShapeNode(rectOf: CGSize(width: 2.5, height: 28), cornerRadius: 1)
            trail.fillColor = SKColor(white: 0.2, alpha: 0.35)
            trail.strokeColor = .clear
            trail.position = CGPoint(x: 0, y: 12)
            bulletContainer.addChild(trail)
            
            // Batang Peluru
            let bullet = SKShapeNode(rectOf: CGSize(width: 3.5, height: 16), cornerRadius: 1.5)
            bullet.fillColor = .black
            bullet.strokeColor = .clear
            bulletContainer.addChild(bullet)
            
            // 💫 1. LINGKARAN BERDENYUT EMAS (Menempel langsung di Peluru)
            let haloRing = SKShapeNode(circleOfRadius: 22)
            haloRing.strokeColor = SKColor(red: 0.98, green: 0.85, blue: 0.25, alpha: 0.95)
            haloRing.lineWidth = 3.0
            haloRing.fillColor = SKColor(red: 0.98, green: 0.85, blue: 0.25, alpha: 0.18)
            haloRing.position = CGPoint(x: 0, y: 0) // Pas di titik tengah peluru!
            haloRing.zPosition = -1
            haloRing.alpha = 0.0
            bulletContainer.addChild(haloRing)
            
            // 1. Terbang Cepat Menuju Dada
            let flyFast = SKAction.move(to: CGPoint(x: bulletX, y: slowMoY), duration: 0.20)
            
            // 2. Momen Slow-Mo: Lingkaran aktif berdenyut mengikuti peluru yang merayap!
            let enterSlowMo = SKAction.run { [weak self] in
                self?.lightHaptic.impactOccurred(intensity: 0.8)
                haloRing.alpha = 1.0
                
                // Denyut membesar-mengecil mengikuti peluru
                let pulse = SKAction.repeatForever(SKAction.sequence([
                    SKAction.group([
                        SKAction.scale(to: 1.45, duration: 0.22),
                        SKAction.fadeAlpha(to: 0.35, duration: 0.22)
                    ]),
                    SKAction.group([
                        SKAction.scale(to: 0.95, duration: 0.18),
                        SKAction.fadeAlpha(to: 1.0, duration: 0.18)
                    ])
                ]))
                haloRing.run(pulse)
            }
            
            let flySlowMo = SKAction.move(to: CGPoint(x: bulletX, y: targetY), duration: 1.25)
            
            bulletContainer.run(SKAction.sequence([
                flyFast,
                enterSlowMo,
                flySlowMo,
                SKAction.run { [weak self] in self?.spawnGroundImpactJuice(at: CGPoint(x: bulletX, y: targetY)) },
                SKAction.removeFromParent()
            ]))
        }
    
    // MARK: - Deteksi Swipe Pemain di Challenge
        private func handleTutorialSwipe(side: ShootSide, step: CowboyTutorialStep) {
            guard isTutorialChallengeActive, !hasDodgedThisRound else { return }
            
            let safeSide: ShootSide = (currentAimSide == .left) ? .right : .left
            let isCorrect = (side == safeSide)
            
            hasDodgedThisRound = true
            playerDodgedSide = side
            dodgePlayer(to: side)
            
            if isCorrect {
                isTutorialChallengeActive = false
                
                if step == .perfectDodge {
                    playerCowboy.playHatGrazedAnimation(isLeftBullet: currentAimSide == .left)
                    if let tex = perfectBadgeTex {
                        triggerPerfectDodgeBadgeJuice(texture: tex)
                    }
                }
                
                heavyHaptic.impactOccurred(intensity: 0.9)
                notificationHaptic.notificationOccurred(.success)
                
                // Nyalakan indikator kotak hijau, lalu lanjut ke step berikutnya
                tutorialOverlay.markStepSuccess(step: step) { [weak self] in
                    guard let self = self else { return }
                    switch step {
                    case .dodgeRight:    self.executeTutorialStep(step: .dodgeLeft)
                    case .dodgeLeft:     self.executeTutorialStep(step: .feintReaction)
                    case .feintReaction: self.executeTutorialStep(step: .perfectDodge)
                    case .perfectDodge:  self.executeTutorialStep(step: .completed)
                    case .completed: break
                    }
                }
            } else {
                lightHaptic.impactOccurred(intensity: 0.6)
            }
        }
    
    private func completeTutorialAndStartGame() {
        tutorialOverlay.hide()
        heavyHaptic.impactOccurred(intensity: 0.9)
        notificationHaptic.notificationOccurred(.success)
        
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.6),
            SKAction.run { [weak self] in self?.startGame() }
        ]))
    }
    
    private func startGame() {
        SoundManager.shared.play("lonceng.mp3")
        flowState = .playing
        playerLives = 3
        score = 0
        totalDuels = 0
        comboCount = 0
        maxComboInRun = 0
        activeLevelConfig = LevelSystem.levels.first!
        SoundManager.shared.playBGM("desert_wind.mp3",volume: 0.15)
        updateBloodVignetteState()
        resetStandoff()
    }
    
    // MARK: - Siklus Duel Utama
    private func resetStandoff() {
        duelPhase = .standoff
        playerDodgedSide = nil
        playerCowboy.animateJumpShadow(isJumping: false)
        hasDodgedThisRound = false
        hasSwipedInCurrentTouch = false
        touchStartPoint = nil
        isCloseCallDodge = false
        
        let newLevel = LevelSystem.currentLevel(for: totalDuels)
        activeLevelConfig = newLevel
        
        roundLabel.text = "RONDE \(totalDuels + 1)"
        
        removeAction(forKey: "duelTimer")
        enemyCowboy.setArmsToWideStance()
        playerCowboy.run(SKAction.move(to: CGPoint(x: size.width / 2, y: 140), duration: 0.15))
        
        let standoffDelay = Double.random(in: activeLevelConfig.standoffDelay)
        run(SKAction.sequence([
            SKAction.wait(forDuration: standoffDelay),
            SKAction.run { [weak self] in
                guard let self = self, self.flowState == .playing else { return }
                self.startHandApproachingGun()
            }
        ]), withKey: "duelTimer")
    }
    
    private func startHandApproachingGun() {
        duelPhase = .handApproaching
        
        currentAimSide = Bool.random() ? .left : .right
        
        let roll = Double.random(in: 0...1)
        if roll < activeLevelConfig.feintChance {
            currentFeintBehavior = .trueSwitch
        } else if roll < (activeLevelConfig.feintChance + activeLevelConfig.fakeHesitationChance) {
            currentFeintBehavior = .fakeHesitation
        } else {
            currentFeintBehavior = .none
        }
        
        let isLeft = (currentAimSide == .left)
        enemyCowboy.animateApproachWithShoulderShift(isLeft: isLeft, duration: activeLevelConfig.handApproachDuration) { [weak self] in
            guard let self = self, self.flowState == .playing else { return }
            
            switch self.currentFeintBehavior {
            case .none:
                self.executeEnemyFire()
            case .trueSwitch:
                self.executeAnticipatedSwitch(fromLeft: isLeft)
            case .fakeHesitation:
                self.executeFakeHesitation(fromLeft: isLeft)
            }
        }
    }
    
    private func executeAnticipatedSwitch(fromLeft: Bool) {
        lightHaptic.impactOccurred(intensity: 0.35)
        enemyCowboy.playRaisedShoulderAnticipation(isLeftGoingToSwitch: fromLeft) { [weak self] in
            guard let self = self, self.flowState == .playing else { return }
            
            self.heavyHaptic.impactOccurred(intensity: 0.6)
            self.popEitssJuice()
            
            let switchSpeed = max(0.08, self.activeLevelConfig.handApproachDuration * 0.6)
            self.enemyCowboy.snapSwitchHands(fromLeftToRight: fromLeft, duration: switchSpeed) {
                self.currentAimSide = self.currentAimSide.opposite
                guard self.flowState == .playing else { return }
                self.executeEnemyFire()
            }
        }
    }
    
    private func executeFakeHesitation(fromLeft: Bool) {
        lightHaptic.impactOccurred(intensity: 0.35)
        enemyCowboy.playRaisedShoulderAnticipation(isLeftGoingToSwitch: fromLeft) { [weak self] in
            guard let self = self, self.flowState == .playing else { return }
            
            self.run(SKAction.sequence([
                SKAction.wait(forDuration: 0.08),
                SKAction.run {
                    self.executeEnemyFire()
                }
            ]))
        }
    }
    
    private func executeEnemyFire() {
        SoundManager.shared.play("gunshot.mp3")
        duelPhase = .shooting
        let isLeft = (currentAimSide == .left)
        
        enemyCowboy.playPreShootAnticipation(isLeft: isLeft, duration: 0.15) { [weak self] in
            guard let self = self, self.flowState == .playing else { return }
            
            // 2. Tembak & Peluru Meluncur!
            self.enemyCowboy.drawGunAndShoot(isLeft: isLeft)
            self.triggerEnemyFireJuice(fromLeft: isLeft)
            
            self.bulletFiredTime = CACurrentMediaTime()
            self.bulletFlightDuration = self.activeLevelConfig.bulletSpeedDuration
            
            self.spawnStraightBullet(fromLeft: isLeft, duration: self.bulletFlightDuration)
            
            self.run(SKAction.sequence([
                SKAction.wait(forDuration: self.bulletFlightDuration),
                SKAction.run { [weak self] in self?.evaluateDodgeResult() }
            ]))
        }
    }
    
 
    
    private func triggerEnemyFireJuice(fromLeft: Bool) {
        let gunX = enemyCowboy.position.x + (fromLeft ? -22 : 22)
        let gunY = enemyCowboy.position.y - 18
        
        spawnBulletCasingJuice(gunX: gunX, gunY: gunY, fromLeft: fromLeft)
        
        let flash = SKShapeNode(circleOfRadius: 9)
        flash.fillColor = SKColor(red: 0.98, green: 0.88, blue: 0.35, alpha: 0.95)
        flash.strokeColor = .white
        flash.lineWidth = 1.5
        flash.position = CGPoint(x: gunX, y: gunY)
        flash.zPosition = 40
        addChild(flash)
        
        flash.run(SKAction.sequence([
            SKAction.scale(to: 1.8, duration: 0.04),
            SKAction.fadeOut(withDuration: 0.06),
            SKAction.removeFromParent()
        ]))
        
        enemyCowboy.run(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 6, duration: 0.04),
            SKAction.moveBy(x: 0, y: -6, duration: 0.08)
        ]))
        
        for i in 0..<3 {
            let smoke = SKShapeNode(circleOfRadius: 2.8)
            smoke.fillColor = SKColor(white: 0.35, alpha: 0.5)
            smoke.strokeColor = .clear
            smoke.position = CGPoint(x: gunX + CGFloat.random(in: -3...3), y: gunY + CGFloat(i * 3))
            smoke.zPosition = 38
            addChild(smoke)
            
            smoke.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: CGFloat.random(in: -5...5), y: 18, duration: 0.35),
                    SKAction.scale(to: 2.2, duration: 0.35),
                    SKAction.fadeOut(withDuration: 0.35)
                ]),
                SKAction.removeFromParent()
            ]))
        }
        
        lightHaptic.impactOccurred(intensity: 0.6)
    }
    
    private func spawnBulletCasingJuice(gunX: CGFloat, gunY: CGFloat, fromLeft: Bool) {
        let casing = SKShapeNode(rectOf: CGSize(width: 3.2, height: 7.0), cornerRadius: 1.0)
        casing.fillColor = SKColor(red: 0.92, green: 0.78, blue: 0.28, alpha: 1.0)
        casing.strokeColor = SKColor(red: 0.50, green: 0.38, blue: 0.10, alpha: 1.0)
        casing.lineWidth = 0.5
        casing.position = CGPoint(x: gunX, y: gunY)
        casing.zPosition = 36
        addChild(casing)
        
        let ejectDir: CGFloat = fromLeft ? -1.0 : 1.0
        let tossPeak = CGPoint(x: gunX + ejectDir * 24, y: gunY + 20)
        let landPoint = CGPoint(x: gunX + ejectDir * 42, y: gunY - 14)
        
        let arcUp = SKAction.move(to: tossPeak, duration: 0.10)
        arcUp.timingMode = .easeOut
        let arcDown = SKAction.move(to: landPoint, duration: 0.14)
        arcDown.timingMode = .easeIn
        let spin = SKAction.rotate(byAngle: ejectDir * CGFloat.pi * 3.5, duration: 0.24)
        
        let bounce = SKAction.sequence([
            SKAction.moveBy(x: ejectDir * 6, y: 5, duration: 0.06),
            SKAction.moveBy(x: ejectDir * 4, y: -5, duration: 0.06)
        ])
        
        let toss = SKAction.group([SKAction.sequence([arcUp, arcDown, bounce]), spin])
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)
        casing.run(SKAction.sequence([toss, fadeOut, SKAction.removeFromParent()]))
    }
    
    private func triggerEnemyShockReaction() {
        enemyCowboy.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: -8, duration: 0.07),
                SKAction.scaleX(to: 1.45, y: 1.25, duration: 0.07)
            ]),
            SKAction.group([
                SKAction.moveBy(x: 0, y: 8, duration: 0.12),
                SKAction.scale(to: 1.35, duration: 0.12)
            ])
        ]))
    }
    
    private func popEitssJuice() {
        let eitssLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
        eitssLabel.text = "EITSS!"
        eitssLabel.fontSize = 26
        eitssLabel.fontColor = SKColor.systemOrange
        eitssLabel.position = CGPoint(x: enemyCowboy.position.x, y: enemyCowboy.position.y + 46)
        eitssLabel.zPosition = 140
        eitssLabel.setScale(0.4)
        addChild(eitssLabel)
        
        let pop = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.3, duration: 0.08),
                SKAction.moveBy(x: 0, y: 12, duration: 0.08)
            ]),
            SKAction.scale(to: 1.0, duration: 0.06),
            SKAction.wait(forDuration: 0.28),
            SKAction.group([
                SKAction.moveBy(x: 0, y: 16, duration: 0.18),
                SKAction.fadeOut(withDuration: 0.18)
            ]),
            SKAction.removeFromParent()
        ])
        eitssLabel.run(pop)
    }
    
    // MARK: - Efek Peluru & Tumbukan
    private func spawnStraightBullet(fromLeft: Bool, duration: TimeInterval) {
        let bulletX = enemyCowboy.position.x + (fromLeft ? -22 : 22)
        let startY = enemyCowboy.position.y - 18
        let targetY: CGFloat = 110.0
        
        let bulletContainer = SKNode()
        bulletContainer.position = CGPoint(x: bulletX, y: startY)
        bulletContainer.zPosition = 35
        addChild(bulletContainer)
        
        let trail = SKShapeNode(rectOf: CGSize(width: 2.5, height: 28), cornerRadius: 1)
        trail.fillColor = SKColor(white: 0.2, alpha: 0.35)
        trail.strokeColor = .clear
        trail.position = CGPoint(x: 0, y: 12)
        bulletContainer.addChild(trail)
        
        let bullet = SKShapeNode(rectOf: CGSize(width: 3.5, height: 16), cornerRadius: 1.5)
        bullet.fillColor = .black
        bullet.strokeColor = .clear
        bulletContainer.addChild(bullet)
        
        let flyAction = SKAction.move(to: CGPoint(x: bulletX, y: targetY), duration: duration)
        let groundHitAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.spawnGroundImpactJuice(at: CGPoint(x: bulletX, y: targetY))
        }
        
        bulletContainer.run(SKAction.sequence([flyAction, groundHitAction, SKAction.removeFromParent()]))
    }
    
    private func spawnGroundImpactJuice(at point: CGPoint) {
        let crater = SKShapeNode(circleOfRadius: 4.5)
        crater.fillColor = SKColor(white: 0.25, alpha: 0.7)
        crater.strokeColor = .clear
        crater.position = point
        crater.zPosition = 22
        addChild(crater)
        
        crater.run(SKAction.sequence([
            SKAction.scale(to: 1.6, duration: 0.12),
            SKAction.fadeOut(withDuration: 0.35),
            SKAction.removeFromParent()
        ]))
        
        for angle in stride(from: 0.0, to: Double.pi * 2, by: Double.pi / 2) {
            let spark = SKShapeNode(circleOfRadius: 1.8)
            spark.fillColor = SKColor(white: 0.3, alpha: 0.8)
            spark.strokeColor = .clear
            spark.position = point
            spark.zPosition = 23
            addChild(spark)
            
            let dist: CGFloat = 16.0
            let target = CGPoint(x: point.x + CGFloat(cos(angle)) * dist, y: point.y + CGFloat(sin(angle)) * dist * 0.5)
            spark.run(SKAction.sequence([
                SKAction.move(to: target, duration: 0.15),
                SKAction.fadeOut(withDuration: 0.15),
                SKAction.removeFromParent()
            ]))
        }
    }
    
    private func spawnDodgeDust(at point: CGPoint) {
        for i in [-1.0, 1.0] {
            let dust = SKShapeNode(circleOfRadius: 3.5)
            dust.fillColor = SKColor(white: 0.5, alpha: 0.45)
            dust.strokeColor = .clear
            dust.position = CGPoint(x: point.x + CGFloat(i * 6), y: point.y - 20)
            dust.zPosition = 24
            addChild(dust)
            
            dust.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: CGFloat(i * 14), y: 4, duration: 0.18),
                    SKAction.scale(to: 1.8, duration: 0.18),
                    SKAction.fadeOut(withDuration: 0.18)
                ]),
                SKAction.removeFromParent()
            ]))
        }
    }
    
    private func spawnCloseCallSparks(at point: CGPoint) {
        for _ in 0..<7 {
            let spark = SKShapeNode(rectOf: CGSize(width: 2, height: 6))
            spark.fillColor = SKColor(red: 0.98, green: 0.85, blue: 0.30, alpha: 0.95)
            spark.strokeColor = .white
            spark.lineWidth = 0.5
            spark.position = point
            spark.zPosition = 60
            addChild(spark)
            
            let randAngle = Double.random(in: -Double.pi * 0.4...Double.pi * 0.4)
            let randDist = CGFloat.random(in: 18...38)
            let endPoint = CGPoint(x: point.x + CGFloat(sin(randAngle)) * randDist,
                                   y: point.y + CGFloat(cos(randAngle)) * randDist)
            
            spark.zRotation = CGFloat(randAngle)
            spark.run(SKAction.sequence([
                SKAction.move(to: endPoint, duration: 0.14),
                SKAction.fadeOut(withDuration: 0.10),
                SKAction.removeFromParent()
            ]))
        }
    }
    
    private func spawnFloatingScorePopup(text: String, color: SKColor, at point: CGPoint) {
        let popup = SKLabelNode(fontNamed: "AvenirNextCondensed-Heavy")
        popup.text = text
        popup.fontSize = 20
        popup.fontColor = color
        popup.position = CGPoint(x: point.x, y: point.y + 40)
        popup.zPosition = 130
        popup.setScale(0.5)
        addChild(popup)
        
        let popAnimation = SKAction.group([
            SKAction.sequence([
                SKAction.scale(to: 1.25, duration: 0.08),
                SKAction.scale(to: 1.0, duration: 0.08),
                SKAction.moveBy(x: 0, y: 35, duration: 0.45)
            ]),
            SKAction.sequence([
                SKAction.wait(forDuration: 0.35),
                SKAction.fadeOut(withDuration: 0.25)
            ])
        ])
        popup.run(SKAction.sequence([popAnimation, SKAction.removeFromParent()]))
    }
    
    private func triggerScreenShake(intensity: CGFloat, duration: TimeInterval) {
        let numberOfShakes = Int(duration / 0.03)
        var actions: [SKAction] = []
        for _ in 0..<numberOfShakes {
            let dx = CGFloat.random(in: -intensity...intensity)
            let dy = CGFloat.random(in: -intensity * 0.5...intensity * 0.5)
            actions.append(SKAction.moveBy(x: dx, y: dy, duration: 0.03))
            actions.append(SKAction.moveBy(x: -dx, y: -dy, duration: 0.03))
        }
        run(SKAction.sequence(actions))
    }
    
    // MARK: - Input Pemain
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        
        if flowState == .onboarding {
            if let btn = welcomeOverlay?.startButton,
               nodes(at: loc).contains(where: { $0 == btn || $0.inParentHierarchy(btn) }) {
                lightHaptic.impactOccurred(intensity: 0.8)
                welcomeOverlay?.dismiss()
                welcomeOverlay = nil
            }
            return
        }
        
        if flowState == .gameOver {
            if let btn = gameOverOverlay?.restartButton,
               nodes(at: loc).contains(where: { $0 == btn || $0.inParentHierarchy(btn) }) {
                lightHaptic.impactOccurred(intensity: 0.8)
                gameOverOverlay?.removeFromParent()
                gameOverOverlay = nil
                startGame()
            }
            return
        }
        
        guard !hasDodgedThisRound else { return }
        touchStartPoint = loc
        hasSwipedInCurrentTouch = false
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !hasDodgedThisRound, !hasSwipedInCurrentTouch,
              let start = touchStartPoint, let touch = touches.first else { return }
        
        let current = touch.location(in: self)
        let deltaX = current.x - start.x
        let deltaY = current.y - start.y
        
        if abs(deltaX) > minSwipeDistance && abs(deltaX) > abs(deltaY) {
            hasSwipedInCurrentTouch = true
            handleSwipeAction(side: deltaX > 0 ? .right : .left)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !hasDodgedThisRound, !hasSwipedInCurrentTouch,
           let start = touchStartPoint, let touch = touches.first {
            let current = touch.location(in: self)
            let deltaX = current.x - start.x
            let deltaY = current.y - start.y
            
            if abs(deltaX) > minSwipeDistance && abs(deltaX) > abs(deltaY) {
                hasSwipedInCurrentTouch = true
                handleSwipeAction(side: deltaX > 0 ? .right : .left)
            }
        }
        touchStartPoint = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchStartPoint = nil
        hasSwipedInCurrentTouch = false
    }
    
    private func handleSwipeAction(side: ShootSide) {
        if case .tutorial(let step) = flowState {
            handleTutorialSwipe(side: side, step: step)
            return
        }
        guard flowState == .playing else { return }
        dodgePlayer(to: side)
    }
    
    private func dodgePlayer(to side: ShootSide) {
        hasDodgedThisRound = true
        playerDodgedSide = side
        playerDodgeTime = CACurrentMediaTime()
        
        if duelPhase == .shooting {
            let timeElapsed = playerDodgeTime - bulletFiredTime
            let timeRemaining = bulletFlightDuration - timeElapsed
            let perfectWindow = max(0.060, bulletFlightDuration * 0.42)
            
            if timeRemaining > 0 && timeRemaining <= perfectWindow {
                isCloseCallDodge = true
            } else {
                isCloseCallDodge = false
            }
        } else {
            isCloseCallDodge = false
        }
        
        spawnDodgeDust(at: playerCowboy.position)
        
        playerCowboy.removeAction(forKey: "dodge")
        playerCowboy.removeAction(forKey: "squash")
        
        let midX = size.width / 2.0
        let targetX = midX + (side == .left ? -dodgeOffsetDistance : dodgeOffsetDistance)
        
        playerCowboy.animateJumpShadow(isJumping: true, jumpHeight: 22.0)
        
        let squashTakeoff = SKAction.scaleX(to: 1.95, y: 1.55, duration: 0.04)
        let stretchAir = SKAction.scaleX(to: 1.55, y: 1.95, duration: 0.09)
        let landSquash = SKAction.scaleX(to: 1.95, y: 1.60, duration: 0.06)
        let settleNormal = SKAction.scale(to: 1.75, duration: 0.08)
        
        playerCowboy.run(SKAction.sequence([squashTakeoff, stretchAir, landSquash, settleNormal]), withKey: "squash")
        
        let jumpUp = SKAction.move(to: CGPoint(x: targetX, y: 162), duration: 0.09)
        jumpUp.timingMode = .easeOut
        let jumpDown = SKAction.move(to: CGPoint(x: targetX, y: 140), duration: 0.08)
        jumpDown.timingMode = .easeIn
        
        let onLanded = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.playerCowboy.animateJumpShadow(isJumping: false)
            self.spawnDodgeDust(at: CGPoint(x: targetX, y: 140))
        }
        
        playerCowboy.run(SKAction.sequence([jumpUp, jumpDown, onLanded]), withKey: "dodge")
        lightHaptic.impactOccurred(intensity: 0.4)
    }
    
    // MARK: - Evaluasi & Skor
    private func evaluateDodgeResult() {
        guard duelPhase == .shooting else { return }
        
        let safeSide: ShootSide = (currentAimSide == .left) ? .right : .left
        let isSuccess = (playerDodgedSide == safeSide)
        
        if isSuccess {
            handleSuccessfulDodge()
        } else {
            handlePlayerHit()
        }
    }
    
    private func handleSuccessfulDodge() {
            duelPhase = .standoff
            totalDuels += 1
            
            if isCloseCallDodge {
                comboCount += 1
                maxComboInRun = max(maxComboInRun, comboCount)
                let earnedScore = 100 * comboCount
                score += earnedScore
                
                // Pop-up badge menggunakan tekstur yang sudah di-cache (tanpa lag)
                if let tex = perfectBadgeTex {
                    triggerPerfectDodgeBadgeJuice(texture: tex)
                }
                
                playerCowboy.playHatGrazedAnimation(isLeftBullet: currentAimSide == .left)
                
                self.speed = 0.2
                let sloMoDuration = 0.1
                self.run(SKAction.sequence([
                    SKAction.wait(forDuration: sloMoDuration),
                    SKAction.run { [weak self] in
                        self?.speed = 1.0
                    }
                ]))
                
                // Efek Flash diperbesar opacity-nya sedikit biar lebih dramatis saat slo-mo
               flashOverlay.alpha = 0.25
                flashOverlay.run(SKAction.fadeOut(withDuration: 0.10)) // Akan melambat juga karena self.speed
                
                let sparkPoint = CGPoint(x: playerCowboy.position.x + (currentAimSide == .left ? -18 : 18), y: playerCowboy.position.y + 15)
                spawnCloseCallSparks(at: sparkPoint)
                
                triggerEnemyShockReaction()
                
                spawnFloatingScorePopup(text: "+\(earnedScore)!", color: self.goldenAmberColor, at: playerCowboy.position)
                heavyHaptic.impactOccurred(intensity: 1.0)
                notificationHaptic.notificationOccurred(.success)
            } else {
                comboCount = 0
                score += 100
                heavyHaptic.impactOccurred(intensity: 0.6)
                spawnFloatingScorePopup(text: "+100", color: self.softWhiteColor, at: playerCowboy.position)
            }
            
            if score > bestScore {
                bestScore = score
                UserDefaults.standard.set(bestScore, forKey: "BestCowboyDodgeScore")
            }
            
            // Jeda menuju ronde berikutnya (Karena ada slo-mo, waktu jeda ini otomatis
            // terasa lebih panjang jika bertabrakan dengan timing slo-mo, memberi 'breathing room' yang pas)
            let nextRoundDelay = max(0.50, 0.75 - Double(activeLevelConfig.level) * 0.05)
            run(SKAction.sequence([
                SKAction.wait(forDuration: nextRoundDelay),
                SKAction.run { [weak self] in self?.resetStandoff() }
            ]))
        }
    
    private func handlePlayerHit() {
        playerLives -= 1
        comboCount = 0
        
        heavyHaptic.impactOccurred(intensity: 1.0)
        notificationHaptic.notificationOccurred(.warning)
        
        bloodVignetteSprite.removeAllActions()
        bloodVignetteSprite.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 1.0, duration: 0.04),
            SKAction.wait(forDuration: 0.15),
            SKAction.run { [weak self] in
                self?.updateBloodVignetteState()
            }
        ]))
        
        triggerScreenShake(intensity: 14.0, duration: 0.22)
        
        playerCowboy.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: (currentAimSide == .left ? 12 : -12), y: -8, duration: 0.06),
                SKAction.colorize(with: .systemRed, colorBlendFactor: 0.8, duration: 0.06)
            ]),
            SKAction.group([
                SKAction.moveBy(x: (currentAimSide == .left ? -12 : 12), y: 8, duration: 0.12),
                SKAction.colorize(withColorBlendFactor: 0.0, duration: 0.12)
            ])
        ]))
        
        if playerLives > 0 {
            run(SKAction.sequence([
                SKAction.wait(forDuration: 0.85),
                SKAction.run { [weak self] in self?.resetStandoff() }
            ]))
        } else {
            triggerGameOver()
        }
    }
    
    private func triggerGameOver() {
        SoundManager.shared.stopBGM()
        flowState = .gameOver
        removeAction(forKey: "duelTimer")
        
        triggerScreenShake(intensity: 18.0, duration: 0.35)
        notificationHaptic.notificationOccurred(.error)
        
        gameOverOverlay?.removeFromParent()
        let overlay = GameOverOverlayNode(
            size: size,
            score: score,
            bestScore: bestScore,
            duels: totalDuels,
            combo: maxComboInRun,
            onFinish: {}
        )
        addChild(overlay)
        self.gameOverOverlay = overlay
    }
}
