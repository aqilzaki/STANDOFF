//
//  GameScene.swift
//  aqil.game
//
import SpriteKit
import UIKit

class GameScene: SKScene {
    
    private enum FlowState: Equatable {
        case onboarding
        case tutorial(step: TutorialStep)
        case playing
        case gameOver
    }
    
    // Nodes & Sprites
    private var playerBodySprite: SKSpriteNode?
    private var playerSwordRoot: SKNode!
    private var playerSwordSprite: SKSpriteNode!
    private var enemySprite: SKSpriteNode!
    private var enemySwordSprite: SKSpriteNode!
    private var bloodVignetteSprite: SKSpriteNode!
    
    // Modul UI & Overlay
    private var tutorialOverlay: TutorialOverlayNode!
    private var gameOverOverlay: GameOverOverlayNode?
    
    // Texture Caching
    private var idleTexture: SKTexture!
    private var tiltTextures: [SKTexture] = []
    private var returnTextures: [SKTexture] = []
    private var enemyIdleTextures: [SKTexture] = []
    private var enemyWindupBodyTextures: [SKTexture] = []
    private var enemySlashBodyTextures: [SKTexture] = []
    private var enemyWindupTextures: [SKTexture] = []
    private var enemySlashTextures: [SKTexture] = []
    private var gameOverBannerTextures: [SKTexture] = []
    
    // State Game
    private var flowState: FlowState = .onboarding
    private var isTutorialFrozen: Bool = false
    private var duelPhase: DuelPhase = .idleStance
    private var currentAttack: AttackDirection = .rightToLeft
    private var isFeintAttack: Bool = false
    private var isPlayerTilting: Bool = false
    
    // Input State
    private var isHoldingLeft: Bool = false
    private var isHoldingRight: Bool = false
    
    // Score & Stats
    private var playerLives: Int = GameSettings.maxPlayerLives { didSet { updateHeartsUI() } }
    private var score: Int = 100 { didSet { scoreLabel.text = "\(score)" } }
    private var bestScore: Int = 0 { didSet { bestScoreLabel.text = "BEST: \(bestScore)" } }
    private var comboCount: Int = 0 { didSet { comboLabel.text = comboCount > 1 ? "KOMBO x\(comboCount)" : "" } }
    private var maxComboInRun: Int = 0
    private var duelCount: Int = 0
    
    // HUD Labels
    private let scoreLabel = SKLabelNode(fontNamed: "HelveticaNeue-Black")
    private let bestScoreLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
    private let comboLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
    private let statusLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
    private let feedbackLabel = SKLabelNode(fontNamed: "HelveticaNeue-Black")
    private let livesLabel = SKLabelNode(fontNamed: "HelveticaNeue-Black")
    
    // Haptics
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let heavyHaptic = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationHaptic = UINotificationFeedbackGenerator()
    
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(white: 0.08, alpha: 1.0)
        view.isMultipleTouchEnabled = true
        
        lightHaptic.prepare()
        heavyHaptic.prepare()
        notificationHaptic.prepare()
        
        bestScore = UserDefaults.standard.integer(forKey: "BestKatanaParryScore")
        
        setupBackground()
        setupBloodVignette()
        setupPlayerBlade()
        setupPlayerCharacter()
        setupGameOverTextures()
        setupEnemyFighter()
        setupEnemySwordAnimation()
        setupHUD()
        setupTutorial()
        updateHeartsUI()
        
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.15),
            SKAction.run { [weak self] in self?.showSimplePlayOnboarding() }
        ]))
    }
    
    private func setupGameOverTextures() {
        gameOverBannerTextures = AnimationHelper.loadTextures(prefix: "ui_banner_gameover", from: 1, to: 4)
    }
    
    private func setupBackground() {
        let texture = SKTexture(imageNamed: GameAssets.backgroundImage)
        texture.filteringMode = .nearest
        let maxScale = max(size.width / texture.size().width, size.height / texture.size().height)
        let bg = SKSpriteNode(texture: texture)
        bg.size = CGSize(width: texture.size().width * maxScale, height: texture.size().height * maxScale)
        bg.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bg.zPosition = -5
        addChild(bg)
    }
    
    private func setupBloodVignette() {
        let texture = CombatEffects.generateBloodVignetteTexture(screenSize: size)
        bloodVignetteSprite = SKSpriteNode(texture: texture, size: size)
        bloodVignetteSprite.position = CGPoint(x: size.width / 2, y: size.height / 2)
        bloodVignetteSprite.zPosition = 85
        bloodVignetteSprite.alpha = 0.0
        addChild(bloodVignetteSprite)
    }
    
    private func setupPlayerCharacter() {
        let body = SKSpriteNode(imageNamed: GameAssets.playerBodyImage)
        body.texture?.filteringMode = .nearest
        body.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        body.position = CGPoint(x: size.width / 2, y: GameSettings.playerBodyBaseY)
        body.setScale(GameAssets.playerBodyScale)
        body.alpha = GameAssets.playerBodyAlpha
        body.zPosition = 30
        addChild(body)
        self.playerBodySprite = body
    }
    
    private func setupPlayerBlade() {
        playerSwordRoot = SKNode()
        playerSwordRoot.position = CGPoint(x: size.width / 2, y: 100)
        playerSwordRoot.zPosition = 27
        addChild(playerSwordRoot)
        
        let atlas = SKTextureAtlas(named: GameAssets.playerSwordAtlas)
        idleTexture = atlas.textureNamed("player_katana_idle1")
        idleTexture.filteringMode = .nearest
        
        tiltTextures = [atlas.textureNamed("player_katana_idle2"), atlas.textureNamed("player_katana_idle3"), atlas.textureNamed("player_katana_idle4")]
        for t in tiltTextures { t.filteringMode = .nearest }
        returnTextures = [tiltTextures[1], tiltTextures[0], idleTexture]
        
        let swordHeight: CGFloat = 280.0
        let swordWidth = swordHeight * (idleTexture.size().width / idleTexture.size().height)
        playerSwordSprite = SKSpriteNode(texture: idleTexture, size: CGSize(width: swordWidth, height: swordHeight))
        playerSwordSprite.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        playerSwordSprite.position = .zero
        playerSwordRoot.addChild(playerSwordSprite)
        
        startSwordIdleAnimation()
    }
    
    private func startSwordIdleAnimation() {
        guard let sword = playerSwordSprite, !isPlayerTilting else { return }
        sword.removeAction(forKey: "idleBob")
        let bobbing = SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 5, duration: 1.1),
            SKAction.moveBy(x: 0, y: -5, duration: 1.1)
        ]))
        sword.run(bobbing, withKey: "idleBob")
    }
    
    private func setupEnemyFighter() {
        enemyIdleTextures = AnimationHelper.loadTextures(prefix: "enemy", from: 1, to: 2)
        enemyWindupBodyTextures = AnimationHelper.loadTextures(prefix: "enemy", from: 3, to: 4)
        enemySlashBodyTextures = AnimationHelper.loadTextures(prefix: "enemy", from: 5, to: 6)
        
        guard let firstFrame = enemyIdleTextures.first else { return }
        enemySprite = SKSpriteNode(texture: firstFrame)
        enemySprite.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        enemySprite.position = CGPoint(x: size.width / 2, y: size.height * GameSettings.enemyPositionYRatio)
        enemySprite.setScale(GameSettings.enemyScale)
        enemySprite.zPosition = 10
        addChild(enemySprite)
        
        startEnemyIdleAnimation()
    }
    
    private func startEnemyIdleAnimation() {
        guard let enemy = enemySprite else { return }
        enemy.removeAction(forKey: "enemyIdle")
        let breathe = SKAction.repeatForever(
            SKAction.animate(with: enemyIdleTextures, timePerFrame: 0.35, resize: false, restore: false)
        )
        enemy.run(breathe, withKey: "enemyIdle")
    }
    
    private func setupEnemySwordAnimation() {
        enemyWindupTextures = AnimationHelper.loadTextures(prefix: "slashing_right_side", from: 2, to: 7)
        enemySlashTextures = AnimationHelper.loadTextures(prefix: "slashing_right_side", from: 8, to: 10)
        
        guard let firstFrame = enemyWindupTextures.first else { return }
        enemySwordSprite = SKSpriteNode(texture: firstFrame)
        enemySwordSprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        enemySwordSprite.position = CGPoint(x: size.width / 2, y: size.height * 0.42)
        enemySwordSprite.zPosition = 25
        enemySwordSprite.setScale(GameSettings.enemySwordScale)
        enemySwordSprite.isHidden = true
        addChild(enemySwordSprite)
    }
    
    private func setupHUD() {
        let topMargin: CGFloat = 60.0
        let sideMargin: CGFloat = 24.0
        
        bestScoreLabel.text = "BEST: \(bestScore)"
        bestScoreLabel.fontSize = 13
        bestScoreLabel.fontColor = .systemYellow
        bestScoreLabel.horizontalAlignmentMode = .left
        bestScoreLabel.position = CGPoint(x: sideMargin, y: size.height - topMargin)
        bestScoreLabel.zPosition = 100
        addChild(bestScoreLabel)
        
        livesLabel.text = "♥♥♥"
        livesLabel.fontSize = 16
        livesLabel.fontColor = .systemRed
        livesLabel.horizontalAlignmentMode = .right
        livesLabel.position = CGPoint(x: size.width - sideMargin, y: size.height - topMargin)
        livesLabel.zPosition = 100
        addChild(livesLabel)
        
        scoreLabel.text = "\(score)"
        scoreLabel.fontSize = 50
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - topMargin - 50)
        scoreLabel.zPosition = 100
        addChild(scoreLabel)
        
        comboLabel.text = ""
        comboLabel.fontSize = 15
        comboLabel.fontColor = .systemOrange
        comboLabel.position = CGPoint(x: size.width / 2, y: size.height - topMargin - 85)
        comboLabel.zPosition = 100
        addChild(comboLabel)
        
        statusLabel.text = "BERSIAP..."
        statusLabel.fontSize = 13
        statusLabel.fontColor = SKColor(white: 0.7, alpha: 1.0)
        statusLabel.position = CGPoint(x: size.width / 2, y: size.height - topMargin - 108)
        statusLabel.zPosition = 100
        addChild(statusLabel)
        
        feedbackLabel.text = ""
        feedbackLabel.fontSize = 26
        feedbackLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.52)
        feedbackLabel.zPosition = 120
        addChild(feedbackLabel)
    }
    
    private func updateHeartsUI() {
        var hearts = ""
        for i in 1...GameSettings.maxPlayerLives { hearts += (i <= playerLives) ? "♥ " : "♡ " }
        livesLabel.text = hearts.trimmingCharacters(in: .whitespaces)
        livesLabel.fontColor = (playerLives == 3) ? .systemGreen : ((playerLives == 2) ? .systemYellow : .systemRed)
        updateBloodVignette()
    }
    
    private func updateBloodVignette() {
        bloodVignetteSprite.removeAllActions()
        switch playerLives {
        case 3: bloodVignetteSprite.run(SKAction.fadeOut(withDuration: 0.35))
        case 2: bloodVignetteSprite.run(SKAction.fadeAlpha(to: 0.75, duration: 0.25))
        case 1:
            let pulse = SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 1.0, duration: 0.30),
                SKAction.fadeAlpha(to: 0.65, duration: 0.40)
            ]))
            bloodVignetteSprite.run(pulse)
        default: bloodVignetteSprite.alpha = 1.0
        }
    }
    
    private func triggerBloodImpact() {
        bloodVignetteSprite.removeAllActions()
        bloodVignetteSprite.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 1.0, duration: 0.03),
            SKAction.wait(forDuration: 0.12),
            SKAction.run { [weak self] in self?.updateBloodVignette() }
        ]))
    }
    
    private func setupTutorial() {
        tutorialOverlay = TutorialOverlayNode(size: size)
        addChild(tutorialOverlay)
    }
    
    // MARK: - Native Onboarding
    private func showSimplePlayOnboarding() {
        flowState = .onboarding
        presentNativeAlert(title: "KATANA CLASH", message: "Tangkis dan potong silang tebasan pedang musuh!", actionTitle: "PLAY") { [weak self] in
            self?.startTutorialFlow()
        }
    }
    
    private func presentNativeAlert(title: String, message: String, actionTitle: String, handler: @escaping () -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let view = self?.view else { return }
            var responder: UIResponder? = view
            while responder != nil {
                if let vc = responder as? UIViewController {
                    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: actionTitle, style: .default) { _ in handler() })
                    var topVC = vc
                    while let presented = topVC.presentedViewController { topVC = presented }
                    topVC.present(alert, animated: true)
                    return
                }
                responder = responder?.next
            }
        }
    }
    
    // MARK: - Tutorial Flow
    private func startTutorialFlow() {
        flowState = .tutorial(step: .parryRight)
        statusLabel.text = "TUTORIAL DIMULAI..."
        statusLabel.fontColor = .systemYellow
        
        run(SKAction.sequence([
            SKAction.wait(forDuration: 0.6),
            SKAction.run { [weak self] in self?.executeTutorialStep(step: .parryRight) }
        ]))
    }
    
    private func executeTutorialStep(step: TutorialStep) {
        flowState = .tutorial(step: step)
        isTutorialFrozen = false
        tutorialOverlay.hide()
        returnPlayerSwordToNeutral()
        
        switch step {
        case .parryRight:
            currentAttack = .leftToRight
            statusLabel.text = "TUTORIAL 1/4: PARRY KANAN"
            statusLabel.fontColor = .systemOrange
            launchParryTutorialAttack(step: step)
        case .parryLeft:
            currentAttack = .rightToLeft
            statusLabel.text = "TUTORIAL 2/4: PARRY KIRI"
            statusLabel.fontColor = .systemOrange
            launchParryTutorialAttack(step: step)
        case .holdRight:
            currentAttack = .leftToRight
            statusLabel.text = "TUTORIAL 3/4: BLOK KANAN (HOLD)"
            statusLabel.fontColor = .systemCyan
            startHoldTutorial(step: step)
        case .holdLeft:
            currentAttack = .rightToLeft
            statusLabel.text = "TUTORIAL 4/4: BLOK KIRI (HOLD)"
            statusLabel.fontColor = .systemCyan
            startHoldTutorial(step: step)
        case .completed:
            completeTutorialAndStartGame()
        }
    }
    
    private func launchParryTutorialAttack(step: TutorialStep) {
        let isRightSide = (currentAttack == .rightToLeft)
        enemySwordSprite.removeAllActions()
        enemySwordSprite.xScale = isRightSide ? GameSettings.enemySwordScale : -GameSettings.enemySwordScale
        enemySwordSprite.yScale = GameSettings.enemySwordScale
        enemySwordSprite.position = CGPoint(x: size.width / 2, y: size.height * 0.42)
        enemySwordSprite.texture = enemyWindupTextures.first
        enemySwordSprite.alpha = 1.0
        enemySwordSprite.isHidden = false
        
        let windup = AnimationHelper.createAction(textures: enemyWindupTextures, duration: 0.35)
        enemySwordSprite.run(windup) { [weak self] in
            guard let self = self else { return }
            self.duelPhase = .slashing
            self.enemySwordSprite.texture = self.enemySlashTextures.first
            let freezePos = CGPoint(x: self.size.width / 2, y: self.size.height * 0.35)
            self.enemySwordSprite.run(SKAction.move(to: freezePos, duration: 0.12)) {
                self.isTutorialFrozen = true
                self.tutorialOverlay.showParryPrompt(step: step, screenSize: self.size)
            }
        }
    }
    
    private func startHoldTutorial(step: TutorialStep) {
        duelPhase = .idleStance
        isTutorialFrozen = true
        enemySwordSprite.removeAllActions()
        enemySwordSprite.isHidden = true
        tutorialOverlay.showHoldPrompt(step: step, screenSize: size)
    }
    
    private func triggerEnemyAttackWhileHolding(step: TutorialStep, nextStep: TutorialStep) {
        isTutorialFrozen = false
        tutorialOverlay.updatePromptText("TETAP TAHAN! LAWAN MENYERANG...", color: .systemGreen)
        let isRightSide = (step == .holdLeft)
        
        enemySwordSprite.removeAllActions()
        enemySwordSprite.xScale = isRightSide ? GameSettings.enemySwordScale : -GameSettings.enemySwordScale
        enemySwordSprite.yScale = GameSettings.enemySwordScale
        enemySwordSprite.position = CGPoint(x: size.width / 2, y: size.height * 0.42)
        enemySwordSprite.texture = enemySlashTextures.first
        enemySwordSprite.alpha = 1.0
        enemySwordSprite.isHidden = false
        
        let slashAnimation = AnimationHelper.createAction(textures: enemySlashTextures, duration: 0.24)
        let moveAction = SKAction.move(to: CGPoint(x: size.width / 2, y: size.height * 0.32), duration: 0.24)
        
        enemySwordSprite.run(SKAction.group([slashAnimation, moveAction])) { [weak self] in
            guard let self = self else { return }
            self.tutorialOverlay.hide()
            self.finishTutorialClash(isParry: false, nextStep: nextStep)
        }
    }
    
    private func finishTutorialClash(isParry: Bool, nextStep: TutorialStep) {
        if isParry {
            heavyHaptic.impactOccurred(intensity: 1.0)
            notificationHaptic.notificationOccurred(.success)
            CombatEffects.flashScreen(color: .white, in: self)
            
            let isLeftToRight = (currentAttack == .leftToRight)
            let clashPoint = CGPoint(x: size.width / 2 + (isLeftToRight ? 22 : -22), y: size.height * 0.33)
            CombatEffects.spawnSparks(at: clashPoint, in: self)
            
            showFeedback(text: "PERFECT PARRY!", color: .systemYellow)
            statusLabel.text = "BERHASIL PARRY MENYILANG!"
            statusLabel.fontColor = .systemYellow
            
            let knockback = SKAction.sequence([
                SKAction.moveBy(x: isLeftToRight ? -45 : 45, y: 35, duration: 0.08),
                SKAction.fadeOut(withDuration: 0.1)
            ])
            enemySwordSprite.run(knockback)
        } else {
            lightHaptic.impactOccurred(intensity: 0.7)
            showFeedback(text: "BLOK BERHASIL (AMAN)!", color: .systemCyan)
            statusLabel.text = "SERANGAN DITAHAN DULUAN!"
            statusLabel.fontColor = .systemCyan
            enemySwordSprite.run(SKAction.fadeOut(withDuration: 0.15))
        }
        
        run(SKAction.sequence([
            SKAction.wait(forDuration: 1.2),
            SKAction.run { [weak self] in
                guard let self = self else { return }
                self.returnPlayerSwordToNeutral()
                self.executeTutorialStep(step: nextStep)
            }
        ]))
    }
    
    private func completeTutorialAndStartGame() {
        tutorialOverlay.hide()
        statusLabel.text = "TUTORIAL SELESAI!"
        statusLabel.fontColor = .systemGreen
        
        presentNativeAlert(title: "⚔️ SIAP BERTARUNG!", message: "Tutorial selesai! Sekarang bertarunglah di duel yang sesungguhnya!", actionTitle: "MULAI DUEL") { [weak self] in
            guard let self = self else { return }
            self.flowState = .playing
            self.score = 100
            self.duelCount = 0
            self.comboCount = 0
            self.resetToIdle()
        }
    }
    
    // MARK: - Input Pemain
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let midX = size.width / 2.0
        let isLeftSide = (loc.x < midX)
        
        if flowState == .gameOver {
            if let restartBtn = gameOverOverlay?.restartButton {
                let touchedNodes = nodes(at: loc)
                if touchedNodes.contains(where: { $0 == restartBtn || $0.inParentHierarchy(restartBtn) }) {
                    lightHaptic.impactOccurred(intensity: 0.8)
                    resetGame()
                } else {
                    restartBtn.run(SKAction.sequence([
                        SKAction.moveBy(x: -10, y: 0, duration: 0.03),
                        SKAction.moveBy(x: 20, y: 0, duration: 0.03),
                        SKAction.moveBy(x: -10, y: 0, duration: 0.03)
                    ]))
                }
            }
            return
        }
        
        if isTutorialFrozen {
            if case .tutorial(let step) = flowState {
                switch step {
                case .parryRight:
                    if !isLeftSide {
                        isTutorialFrozen = false
                        tutorialOverlay.hide()
                        tiltPlayerSword(targetAngle: -GameSettings.playerTiltAngle)
                        finishTutorialClash(isParry: true, nextStep: .parryLeft)
                    } else {
                        showFeedback(text: "TAP SISI KANAN!", color: .systemOrange)
                        tutorialOverlay.shakeBox()
                    }
                case .parryLeft:
                    if isLeftSide {
                        isTutorialFrozen = false
                        tutorialOverlay.hide()
                        tiltPlayerSword(targetAngle: GameSettings.playerTiltAngle)
                        finishTutorialClash(isParry: true, nextStep: .holdRight)
                    } else {
                        showFeedback(text: "TAP SISI KIRI!", color: .systemOrange)
                        tutorialOverlay.shakeBox()
                    }
                case .holdRight:
                    if isLeftSide {
                        showFeedback(text: "TAHAN SISI KANAN!", color: .systemCyan)
                        tutorialOverlay.shakeBox()
                    } else {
                        isHoldingRight = true
                        tiltPlayerSword(targetAngle: -GameSettings.playerTiltAngle)
                        triggerEnemyAttackWhileHolding(step: .holdRight, nextStep: .holdLeft)
                    }
                case .holdLeft:
                    if !isLeftSide {
                        showFeedback(text: "TAHAN SISI KIRI!", color: .systemCyan)
                        tutorialOverlay.shakeBox()
                    } else {
                        isHoldingLeft = true
                        tiltPlayerSword(targetAngle: GameSettings.playerTiltAngle)
                        triggerEnemyAttackWhileHolding(step: .holdLeft, nextStep: .completed)
                    }
                case .completed: break
                }
            }
            return
        }
        
        guard flowState == .playing else { return }
        let tappedSide: CombatSide = isLeftSide ? .left : .right
        
        if isLeftSide {
            isHoldingLeft = true
            isHoldingRight = false
            tiltPlayerSword(targetAngle: GameSettings.playerTiltAngle)
        } else {
            isHoldingRight = true
            isHoldingLeft = false
            tiltPlayerSword(targetAngle: -GameSettings.playerTiltAngle)
        }
        
        // Instant Tap Parry
        if duelPhase == .slashing {
            let requiresRight = (currentAttack == .leftToRight)
            let isCorrectSide = (tappedSide == (requiresRight ? .right : .left))
            if isCorrectSide {
                enemySwordSprite.removeAllActions()
                triggerPerfectParry()
                return
            } else {
                enemySwordSprite.removeAllActions()
                handlePlayerTakeDamage()
                return
            }
        }
        lightHaptic.impactOccurred(intensity: 0.4)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouchRelease(event: event) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { updateTouchRelease(event: event) }
    
    private func updateTouchRelease(event: UIEvent?) {
        guard let allTouches = event?.allTouches else {
            isHoldingLeft = false; isHoldingRight = false
            returnPlayerSwordToNeutral()
            return
        }
        
        var left = false; var right = false
        let midX = size.width / 2.0
        for touch in allTouches where touch.phase == .began || touch.phase == .moved || touch.phase == .stationary {
            if touch.location(in: self).x < midX { left = true } else { right = true }
        }
        
        isHoldingLeft = left
        isHoldingRight = right
        
        if !left && !right {
            returnPlayerSwordToNeutral()
        } else if left && !right {
            tiltPlayerSword(targetAngle: GameSettings.playerTiltAngle)
        } else if right && !left {
            tiltPlayerSword(targetAngle: -GameSettings.playerTiltAngle)
        }
    }
    
    private func tiltPlayerSword(targetAngle: CGFloat) {
        guard let sword = playerSwordSprite else { return }
        isPlayerTilting = true
        sword.removeAction(forKey: "idleBob")
        sword.removeAction(forKey: "tiltAction")
        sword.removeAction(forKey: "returnAction")
        
        let isTiltLeft = (targetAngle > 0)
        sword.xScale = isTiltLeft ? -1.0 : 1.0
        
        let animateTilt = SKAction.animate(with: tiltTextures, timePerFrame: 0.015, resize: false, restore: false)
        let rotateAction = SKAction.rotate(toAngle: targetAngle, duration: GameSettings.playerTiltDuration)
        rotateAction.timingMode = .easeOut
        
        let guardOffset = CGPoint(x: isTiltLeft ? -15.0 : 15.0, y: 20.0)
        let moveAction = SKAction.move(to: guardOffset, duration: GameSettings.playerTiltDuration)
        moveAction.timingMode = .easeOut
        
        sword.run(SKAction.group([animateTilt, rotateAction, moveAction]), withKey: "tiltAction")
    }
    
    private func returnPlayerSwordToNeutral() {
        guard !isHoldingLeft && !isHoldingRight else { return }
        guard let sword = playerSwordSprite else { return }
        
        if isPlayerTilting {
            sword.removeAction(forKey: "tiltAction")
            sword.removeAction(forKey: "returnAction")
            
            let animateReturn = SKAction.animate(with: returnTextures, timePerFrame: 0.02, resize: false, restore: false)
            let rotateBack = SKAction.rotate(toAngle: 0, duration: GameSettings.playerResetDuration)
            let moveBack = SKAction.move(to: .zero, duration: GameSettings.playerResetDuration)
            
            let onComplete = SKAction.run { [weak self] in
                guard let self = self else { return }
                self.isPlayerTilting = false
                self.playerSwordSprite.texture = self.idleTexture
                self.playerSwordSprite.xScale = 1.0
                self.playerSwordSprite.zRotation = 0
                self.playerSwordSprite.position = .zero
                self.startSwordIdleAnimation()
            }
            sword.run(SKAction.sequence([SKAction.group([animateReturn, rotateBack, moveBack]), onComplete]), withKey: "returnAction")
        } else {
            sword.texture = idleTexture
            sword.xScale = 1.0
            sword.zRotation = 0
            sword.position = .zero
            startSwordIdleAnimation()
        }
    }
    
    // MARK: - Siklus Duel
    private func resetToIdle() {
        duelPhase = .idleStance
        statusLabel.text = "BERSIAP..."
        statusLabel.fontColor = SKColor(white: 0.7, alpha: 1.0)
        removeAction(forKey: "duelTimer")
        
        enemySwordSprite.removeAllActions()
        enemySwordSprite.isHidden = true
        enemySwordSprite.alpha = 1.0
        
        enemySprite.removeAllActions()
        enemySprite.xScale = GameSettings.enemyScale
        startEnemyIdleAnimation()
        
        if !isHoldingLeft && !isHoldingRight {
            returnPlayerSwordToNeutral()
        }
        
        let idleDelay: TimeInterval
        if duelCount < 3 {
            idleDelay = GameSettings.phase1IdleDuration
            isFeintAttack = false
        } else if duelCount < 6 {
            isFeintAttack = (Double.random(in: 0...1) < GameSettings.feintChancePhase2)
            idleDelay = (Double.random(in: 0...1) < 0.25) ? 0.6 : GameSettings.phase2NormalWindup + 0.4
        } else {
            isFeintAttack = (Double.random(in: 0...1) < GameSettings.feintChancePhase3)
            let roll = Double.random(in: 0...1)
            if roll < 0.35 { idleDelay = 0.45 }
            else if roll < 0.70 { idleDelay = 0.80 }
            else { idleDelay = Double.random(in: GameSettings.phase3LongStandoff) }
        }
        
        let waitAndStart = SKAction.sequence([
            SKAction.wait(forDuration: idleDelay),
            SKAction.run { [weak self] in
                guard let self = self, self.flowState == .playing else { return }
                self.startWindup()
            }
        ])
        run(waitAndStart, withKey: "duelTimer")
    }
    
    private func startWindup() {
        duelPhase = .windup
        currentAttack = Bool.random() ? .leftToRight : .rightToLeft
        let isRightSide = (currentAttack == .rightToLeft)
        
        statusLabel.text = isRightSide ? "AWAS! TEBASAN DARI KANAN!" : "AWAS! TEBASAN DARI KIRI!"
        statusLabel.fontColor = .systemOrange

        enemySwordSprite.removeAllActions()
        let startX = isRightSide ? (size.width * 0.65) : (size.width * 0.35)
        let startY = size.height * 0.44
        enemySwordSprite.position = CGPoint(x: startX, y: startY)
        enemySwordSprite.xScale = isRightSide ? GameSettings.enemySwordScale : -GameSettings.enemySwordScale
        enemySwordSprite.yScale = GameSettings.enemySwordScale
        enemySwordSprite.texture = enemyWindupTextures.first
        enemySwordSprite.alpha = 1.0
        enemySwordSprite.isHidden = false

        let windupDuration = (duelCount < 3) ? GameSettings.phase1WindupDuration : ((duelCount < 6) ? GameSettings.phase2NormalWindup : GameSettings.phase3BlitzDuration)

        enemySprite.removeAction(forKey: "enemyIdle")
        let baseScale = GameSettings.enemyScale
        enemySprite.xScale = isRightSide ? baseScale : -baseScale
        enemySprite.run(AnimationHelper.createAction(textures: enemyWindupBodyTextures, duration: windupDuration))

        let animateWindup = AnimationHelper.createAction(textures: enemyWindupTextures, duration: windupDuration)
        enemySwordSprite.run(animateWindup) { [weak self] in
            guard let self = self, self.flowState == .playing else { return }
            if self.isFeintAttack {
                self.executeFeintSequence()
            } else {
                self.triggerIncomingSlash()
            }
        }
    }
    
    private func executeFeintSequence() {
        heavyHaptic.impactOccurred(intensity: 0.4)
        showFeedback(text: "EITSS!", color: .systemOrange)
        statusLabel.text = "EITSS! TAHAN DULU!"
        statusLabel.fontColor = .systemOrange
        
        let pause = SKAction.sequence([
            SKAction.wait(forDuration: GameSettings.feintPauseDelay),
            SKAction.run { [weak self] in
                guard let self = self, self.flowState == .playing else { return }
                self.triggerIncomingSlash()
            }
        ])
        enemySwordSprite.run(pause)
    }
    
    private func triggerIncomingSlash() {
        duelPhase = .slashing
        let isRightSide = (currentAttack == .rightToLeft)
        statusLabel.text = isRightSide ? "TEKAN KIRI UNTUK PARRY!" : "TEKAN KANAN UNTUK PARRY!"
        statusLabel.fontColor = .systemRed

        enemySwordSprite.removeAllActions()
        let slashDuration: TimeInterval = max(GameSettings.slashDurationMinimum, GameSettings.slashDurationInitial - Double(duelCount) * GameSettings.slashScaling)

        let startX = isRightSide ? (size.width * 0.65) : (size.width * 0.35)
        enemySwordSprite.position = CGPoint(x: startX, y: size.height * 0.44)
        enemySwordSprite.alpha = 1.0
        enemySwordSprite.isHidden = false

        let fullCrossTarget = CGPoint(x: isRightSide ? (size.width * 0.20) : (size.width * 0.80), y: size.height * 0.16)
        enemySprite.run(AnimationHelper.createAction(textures: enemySlashBodyTextures, duration: slashDuration))

        let slashAnim = AnimationHelper.createAction(textures: enemySlashTextures, duration: slashDuration)
        let slashMove = SKAction.move(to: fullCrossTarget, duration: slashDuration)
        slashMove.timingMode = .easeIn

        enemySwordSprite.run(SKAction.group([slashAnim, slashMove])) { [weak self] in
            guard let self = self, self.flowState == .playing else { return }
            self.evaluateBlockOrDamageResult()
        }
    }
    
    private func evaluateBlockOrDamageResult() {
        guard duelPhase == .slashing else { return }
        let requiresRight = (currentAttack == .leftToRight)
        let isCorrectHolding = requiresRight ? isHoldingRight : isHoldingLeft
        if isCorrectHolding { triggerBlock() } else { handlePlayerTakeDamage() }
    }
    
    private func triggerPerfectParry() {
        duelPhase = .idleStance
        heavyHaptic.impactOccurred(intensity: 1.0)
        notificationHaptic.notificationOccurred(.success)
        CombatEffects.flashScreen(color: .white, in: self)
        
        let isRightSide = (currentAttack == .rightToLeft)
        let clashPoint = CGPoint(x: size.width / 2 + (isRightSide ? 18 : -18), y: size.height * 0.33)
        
        enemySprite.run(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 8, duration: 0.05),
            SKAction.moveBy(x: 0, y: -8, duration: 0.08)
        ]))
        
        enemySwordSprite.removeAllActions()
        enemySwordSprite.position = clashPoint
        CombatEffects.spawnSparks(at: clashPoint, in: self)
        
        comboCount += 1
        maxComboInRun = max(maxComboInRun, comboCount)
        let gained = GameSettings.baseScorePerParry * max(1, comboCount)
        score += gained
        duelCount += 1
        
        if score > bestScore {
            bestScore = score
            UserDefaults.standard.set(bestScore, forKey: "BestKatanaParryScore")
        }
        
        showFeedback(text: "PERFECT PARRY! +\(gained)", color: .systemYellow)
        statusLabel.text = "PARRY MENYILANG TELAK!"
        statusLabel.fontColor = .systemYellow
        
        let knockback = SKAction.sequence([
            SKAction.moveBy(x: isRightSide ? 45 : -45, y: 35, duration: 0.08),
            SKAction.fadeOut(withDuration: 0.1)
        ])
        enemySwordSprite.run(knockback) { [weak self] in
            guard let self = self else { return }
            if !self.isHoldingLeft && !self.isHoldingRight { self.returnPlayerSwordToNeutral() }
            self.resetToIdle()
        }
    }
    
    private func triggerBlock() {
        let isRightSide = (currentAttack == .rightToLeft)
        let blockPoint = CGPoint(x: size.width / 2 + (isRightSide ? 16 : -16), y: size.height * 0.32)
        
        enemySwordSprite.removeAllActions()
        enemySwordSprite.position = blockPoint
        
        lightHaptic.impactOccurred(intensity: 0.5)
        comboCount = 0
        showFeedback(text: "BLOK (AMAN)", color: .systemCyan)
        statusLabel.text = "TERTAHAN!"
        statusLabel.fontColor = .systemCyan
        
        CombatEffects.spawnBlockSparks(at: blockPoint, in: self)
        
        let pushAngle: CGFloat = isRightSide ? -0.06 : 0.06
        playerSwordSprite?.run(SKAction.sequence([
            SKAction.rotate(byAngle: pushAngle, duration: 0.04),
            SKAction.rotate(byAngle: -pushAngle, duration: 0.06)
        ]))
        
        let stallAndSlide = SKAction.sequence([
            SKAction.wait(forDuration: 0.08),
            SKAction.group([
                SKAction.moveBy(x: isRightSide ? 15 : -15, y: 12, duration: 0.14),
                SKAction.fadeOut(withDuration: 0.14)
            ])
        ])
        
        enemySwordSprite.run(stallAndSlide) { [weak self] in
            guard let self = self else { return }
            if !self.isHoldingLeft && !self.isHoldingRight { self.returnPlayerSwordToNeutral() }
            self.resetToIdle()
        }
    }
    
    private func handlePlayerTakeDamage() {
        playerLives -= 1
        comboCount = 0
        triggerBloodImpact()
        
        if playerLives > 0 {
            heavyHaptic.impactOccurred(intensity: 0.9)
            notificationHaptic.notificationOccurred(.warning)
            CombatEffects.flashScreen(color: SKColor.systemRed.withAlphaComponent(0.6), in: self)
            
            run(SKAction.sequence([
                SKAction.moveBy(x: -14, y: 0, duration: 0.04),
                SKAction.moveBy(x: 28, y: 0, duration: 0.04),
                SKAction.moveBy(x: -14, y: 0, duration: 0.04)
            ]))
            
            showFeedback(text: "TERLUKA! (-1 NYAWA)", color: .systemRed)
            statusLabel.text = "KENA TEBAS! SISA NYAWA: \(playerLives)"
            statusLabel.fontColor = .systemRed
            
            enemySwordSprite.run(SKAction.fadeOut(withDuration: 0.15)) { [weak self] in
                self?.resetToIdle()
            }
        } else {
            triggerGameOver()
        }
    }
    
    private func triggerGameOver() {
        flowState = .gameOver
        removeAction(forKey: "duelTimer")
        
        heavyHaptic.impactOccurred(intensity: 1.0)
        notificationHaptic.notificationOccurred(.error)
        
        run(SKAction.sequence([
            SKAction.moveBy(x: -16, y: 0, duration: 0.04),
            SKAction.moveBy(x: 32, y: 0, duration: 0.04),
            SKAction.moveBy(x: -16, y: 0, duration: 0.04)
        ]))
        
        gameOverOverlay?.removeFromParent()
        let overlay = GameOverOverlayNode(
            size: size,
            score: score,
            bestScore: bestScore,
            duels: duelCount,
            combo: maxComboInRun,
            textures: gameOverBannerTextures,
            onFinish: {}
        )
        addChild(overlay)
        self.gameOverOverlay = overlay
    }
    
    private func resetGame() {
        removeAction(forKey: "duelTimer")
        gameOverOverlay?.removeFromParent()
        gameOverOverlay = nil
        
        flowState = .playing
        playerLives = GameSettings.maxPlayerLives
        score = 100
        comboCount = 0
        maxComboInRun = 0
        duelCount = 0
        
        returnPlayerSwordToNeutral()
        resetToIdle()
    }
    
    private func showFeedback(text: String, color: SKColor) {
        feedbackLabel.removeAllActions()
        feedbackLabel.text = text
        feedbackLabel.fontColor = color
        feedbackLabel.setScale(1.3)
        feedbackLabel.alpha = 1.0
        feedbackLabel.run(SKAction.sequence([
            SKAction.scale(to: 1.0, duration: 0.1),
            SKAction.wait(forDuration: 0.35),
            SKAction.fadeOut(withDuration: 0.2)
        ]))
    }
}
