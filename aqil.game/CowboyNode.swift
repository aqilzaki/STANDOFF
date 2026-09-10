//
//  CowboyNode.swift
//  aqil.game (Fixed Shoulder & Clear Pre-Shoot Edition)
//
import SpriteKit

class CowboyNode: SKNode {
    
    // Anatomi tubuh
    private let hatCrown = SKShapeNode()
    private let hatBrim = SKShapeNode()
    private let hatNode = SKNode()
    private let head = SKShapeNode(circleOfRadius: 8)
    private let torso = SKShapeNode()
    private let leftLeg = SKShapeNode(rectOf: CGSize(width: 6, height: 26), cornerRadius: 2)
    private let rightLeg = SKShapeNode(rectOf: CGSize(width: 6, height: 26), cornerRadius: 2)
    
    private let groundShadow = SKShapeNode(ellipseOf: CGSize(width: 28, height: 7.5))
    
    let leftHolster = SKShapeNode(rectOf: CGSize(width: 7, height: 11), cornerRadius: 1)
    let rightHolster = SKShapeNode(rectOf: CGSize(width: 7, height: 11), cornerRadius: 1)
    let leftGun = SKShapeNode(rectOf: CGSize(width: 9, height: 5), cornerRadius: 1)
    let rightGun = SKShapeNode(rectOf: CGSize(width: 9, height: 5), cornerRadius: 1)
    
    let leftArm = SKShapeNode()
    let rightArm = SKShapeNode()
    
    // 🔒 Titik Bahu Paten (Terkunci rapat di dalam Torso, tidak akan pernah lepas!)
    private let baseLeftShoulder = CGPoint(x: -10, y: 11)
    private let baseRightShoulder = CGPoint(x: 10, y: 11)
    
    // Posisi Tangan Sangat Lebar (Standby)
    private let wideLeftElbow = CGPoint(x: -37, y: 5)
    private let wideLeftHand  = CGPoint(x: -33, y: -4)
    private let wideRightElbow = CGPoint(x: 37, y: 5)
    private let wideRightHand  = CGPoint(x: 33, y: -4)
    
    // Posisi Tangan di Holster (Pinggang)
    private let nearLeftElbow = CGPoint(x: -20, y: -1)
    private let nearLeftHand  = CGPoint(x: -15, y: -5)
    private let nearRightElbow = CGPoint(x: 20, y: -1)
    private let nearRightHand  = CGPoint(x: 15, y: -5)
    
    // Posisi Siku & Tangan Terangkat Siaga (Siku yang naik, bukan bahu!)
    private let raisedLeftElbow = CGPoint(x: -36, y: 18)
    private let raisedLeftHand  = CGPoint(x: -30, y: 8)
    private let raisedRightElbow = CGPoint(x: 36, y: 18)
    private let raisedRightHand  = CGPoint(x: 30, y: 8)
    
    var color: SKColor = .black {
        didSet { applyColor() }
    }
    
    init(color: SKColor = .black) {
        self.color = color
        super.init()
        setupBodyParts()
        applyColor()
        setArmsToWideStance()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupBodyParts()
        applyColor()
        setArmsToWideStance()
    }
    
    private func setupBodyParts() {
        // 0. Bayangan di Tanah (Di bawah kaki & badan)
                groundShadow.fillColor = SKColor.black.withAlphaComponent(0.22)
                groundShadow.strokeColor = .clear
                groundShadow.position = CGPoint(x: 0, y: -43) // Tepat di bawah telapak kaki
                groundShadow.zPosition = -1 // Di bawah semua anggota tubuh
                addChild(groundShadow)
        
        // 1. Kaki
        leftLeg.position = CGPoint(x: -6, y: -30)
        rightLeg.position = CGPoint(x: 6, y: -30)
        addChild(leftLeg)
        addChild(rightLeg)
        
        // 2. Torso (Tinggi Y: -18 s/d +14)
        let torsoPath = UIBezierPath(roundedRect: CGRect(x: -12, y: -18, width: 24, height: 32), cornerRadius: 4)
        torso.path = torsoPath.cgPath
        addChild(torso)
        
        // 3. Kepala
        head.position = CGPoint(x: 0, y: 19)
        addChild(head)
        
        // 4. Topi Koboi
        hatNode.position = CGPoint(x: 0, y: 24)
        addChild(hatNode)
        
        let brimPath = UIBezierPath(ovalIn: CGRect(x: -20, y: -2, width: 40, height: 7.5))
        hatBrim.path = brimPath.cgPath
        hatNode.addChild(hatBrim)
        
        let crownPath = UIBezierPath(roundedRect: CGRect(x: -7.5, y: 2, width: 15, height: 13), cornerRadius: 2)
        hatCrown.path = crownPath.cgPath
        hatNode.addChild(hatCrown)
        
        // 5. Holster & Senjata
        leftHolster.position = CGPoint(x: -15, y: -7)
        rightHolster.position = CGPoint(x: 15, y: -7)
        addChild(leftHolster)
        addChild(rightHolster)
        
        leftGun.position = CGPoint(x: -15, y: -5)
        rightGun.position = CGPoint(x: 15, y: -5)
        addChild(leftGun)
        addChild(rightGun)
        
        // 6. Lengan (Ketebalan 5.0 menutup sambungan dengan sempurna)
        leftArm.lineWidth = 5.0
        leftArm.lineCap = .round
        leftArm.lineJoin = .round
        addChild(leftArm)
        
        rightArm.lineWidth = 5.0
        rightArm.lineCap = .round
        rightArm.lineJoin = .round
        addChild(rightArm)
    }
    
    private func applyColor() {
        let parts = [hatCrown, hatBrim, head, torso, leftLeg, rightLeg, leftHolster, rightHolster, leftGun, rightGun]
        for part in parts {
            part.fillColor = color
            part.strokeColor = color
        }
        leftArm.strokeColor = color
        rightArm.strokeColor = color
    }
    
    private func updateArmCurvedPath(node: SKShapeNode, shoulder: CGPoint, elbowControl: CGPoint, hand: CGPoint) {
        let path = UIBezierPath()
        path.move(to: shoulder)
        path.addQuadCurve(to: hand, controlPoint: elbowControl)
        node.path = path.cgPath
    }
    
    func setArmsToWideStance() {
        leftArm.removeAllActions()
        rightArm.removeAllActions()
        leftGun.removeAllActions()
        rightGun.removeAllActions()
        torso.zRotation = 0
        head.zRotation = 0
        
        updateArmCurvedPath(node: leftArm, shoulder: baseLeftShoulder, elbowControl: wideLeftElbow, hand: wideLeftHand)
        updateArmCurvedPath(node: rightArm, shoulder: baseRightShoulder, elbowControl: wideRightElbow, hand: wideRightHand)
        
        leftGun.position = CGPoint(x: -15, y: -5)
        rightGun.position = CGPoint(x: 15, y: -5)
        leftGun.zRotation = 0
        rightGun.zRotation = 0
    }
    
    // MARK: - Gerakan Tangan Merapat (Bahu Tetap Menempel di Badan)
    func animateApproachWithShoulderShift(isLeft: Bool, duration: TimeInterval, completion: @escaping () -> Void) {
        let activeArm = isLeft ? leftArm : rightArm
        let oppArm = isLeft ? rightArm : leftArm
        
        let startActiveShoulder = isLeft ? baseLeftShoulder : baseRightShoulder
        let targetActiveShoulder = CGPoint(x: startActiveShoulder.x, y: 10.0) // Tetap di dalam torso
        
        let startOppShoulder = isLeft ? baseRightShoulder : baseLeftShoulder
        let targetOppShoulder = CGPoint(x: startOppShoulder.x, y: 12.5) // Naik sedikit, tidak keluar torso!
        
        let startActiveElbow = isLeft ? wideLeftElbow : wideRightElbow
        let targetActiveElbow = isLeft ? nearLeftElbow : nearRightElbow
        
        let startActiveHand = isLeft ? wideLeftHand : wideRightHand
        let targetActiveHand = isLeft ? nearLeftHand : nearRightHand
        
        let startOppElbow = isLeft ? wideRightElbow : wideLeftElbow
        let targetOppElbow = isLeft ? raisedRightElbow : raisedLeftElbow
        
        let startOppHand = isLeft ? wideRightHand : wideLeftHand
        let targetOppHand = isLeft ? raisedRightHand : raisedLeftHand
        
        let shiftAction = SKAction.customAction(withDuration: duration) { [weak self] _, time in
            guard let self = self else { return }
            let progress = time / CGFloat(duration)
            let easeT = 0.5 * (1.0 - cos(progress * .pi))
            
            // 1. Tangan aktif turun ke holster
            let curActShoulder = CGPoint(x: startActiveShoulder.x, y: startActiveShoulder.y + (targetActiveShoulder.y - startActiveShoulder.y) * easeT)
            let curActElbow = CGPoint(x: startActiveElbow.x + (targetActiveElbow.x - startActiveElbow.x) * easeT,
                                      y: startActiveElbow.y + (targetActiveElbow.y - startActiveElbow.y) * easeT)
            let curActHand = CGPoint(x: startActiveHand.x + (targetActiveHand.x - startActiveHand.x) * easeT,
                                     y: startActiveHand.y + (targetActiveHand.y - startActiveHand.y) * easeT)
            self.updateArmCurvedPath(node: activeArm, shoulder: curActShoulder, elbowControl: curActElbow, hand: curActHand)
            
            // 2. Lengan seberang siku terangkat naik (Pangkal tetap di torso)
            let curOppShoulder = CGPoint(x: startOppShoulder.x, y: startOppShoulder.y + (targetOppShoulder.y - startOppShoulder.y) * easeT)
            let curOppElbow = CGPoint(x: startOppElbow.x + (targetOppElbow.x - startOppElbow.x) * easeT,
                                      y: startOppElbow.y + (targetOppElbow.y - startOppElbow.y) * easeT)
            let curOppHand = CGPoint(x: startOppHand.x + (targetOppHand.x - startOppHand.x) * easeT,
                                     y: startOppHand.y + (targetOppHand.y - startOppHand.y) * easeT)
            self.updateArmCurvedPath(node: oppArm, shoulder: curOppShoulder, elbowControl: curOppElbow, hand: curOppHand)
            
            self.torso.zRotation = (isLeft ? 0.045 : -0.045) * easeT
            self.head.zRotation = (isLeft ? 0.03 : -0.03) * easeT
        }
        
        run(SKAction.sequence([shiftAction, SKAction.run(completion)]))
    }
    
    // MARK: - Kedutan Bahu Antisipasi Feint
    func playRaisedShoulderAnticipation(isLeftGoingToSwitch: Bool, completion: @escaping () -> Void) {
        let raisedArm = isLeftGoingToSwitch ? rightArm : leftArm
        let shoulderX: CGFloat = isLeftGoingToSwitch ? 10.0 : -10.0
        let elbow = isLeftGoingToSwitch ? raisedRightElbow : raisedLeftElbow
        let hand = isLeftGoingToSwitch ? raisedRightHand : raisedLeftHand
        
        let pulseDuration: TimeInterval = 0.16
        let twitchPulse = SKAction.customAction(withDuration: pulseDuration) { [weak self] _, time in
            guard let self = self else { return }
            let p = time / CGFloat(pulseDuration)
            let sineWave = sin(p * .pi)
            
            // Siku berdenyut jelas, bahu tetap aman di dalam batas torso
            let curShoulderY: CGFloat = 12.0 + 1.2 * sineWave
            let curElbowY = elbow.y + 4.0 * sineWave
            let curElbowX = elbow.x + (isLeftGoingToSwitch ? 3.0 : -3.0) * sineWave
            
            self.updateArmCurvedPath(node: raisedArm, shoulder: CGPoint(x: shoulderX, y: curShoulderY), elbowControl: CGPoint(x: curElbowX, y: curElbowY), hand: hand)
        }
        raisedArm.run(SKAction.sequence([twitchPulse, SKAction.run(completion)]))
    }
    
    // MARK: - Ganti Tangan Kilat (Feint)
    func snapSwitchHands(fromLeftToRight: Bool, duration: TimeInterval, completion: @escaping () -> Void) {
        let oldArm = fromLeftToRight ? leftArm : rightArm
        let newArm = fromLeftToRight ? rightArm : leftArm
        let oldShoulderX: CGFloat = fromLeftToRight ? -10.0 : 10.0
        let newShoulderX: CGFloat = fromLeftToRight ? 10.0 : -10.0
        
        let targetNewElbow = fromLeftToRight ? nearRightElbow : nearLeftElbow
        let targetNewHand = fromLeftToRight ? nearRightHand : nearLeftHand
        let targetOldElbow = fromLeftToRight ? raisedLeftElbow : raisedRightElbow
        let targetOldHand = fromLeftToRight ? raisedLeftHand : raisedRightHand
        
        let switchAction = SKAction.customAction(withDuration: duration) { [weak self] _, time in
            guard let self = self else { return }
            let progress = time / CGFloat(duration)
            let easeT = 0.5 * (1.0 - cos(progress * .pi))
            
            let newS = CGPoint(x: newShoulderX, y: 12.5 - 2.5 * easeT)
            let newE = CGPoint(x: (fromLeftToRight ? self.raisedRightElbow.x : self.raisedLeftElbow.x) + (targetNewElbow.x - (fromLeftToRight ? self.raisedRightElbow.x : self.raisedLeftElbow.x)) * easeT,
                               y: (fromLeftToRight ? self.raisedRightElbow.y : self.raisedLeftElbow.y) + (targetNewElbow.y - (fromLeftToRight ? self.raisedRightElbow.y : self.raisedLeftElbow.y)) * easeT)
            let newH = CGPoint(x: (fromLeftToRight ? self.raisedRightHand.x : self.raisedLeftHand.x) + (targetNewHand.x - (fromLeftToRight ? self.raisedRightHand.x : self.raisedLeftHand.x)) * easeT,
                               y: (fromLeftToRight ? self.raisedRightHand.y : self.raisedLeftHand.y) + (targetNewHand.y - (fromLeftToRight ? self.raisedRightHand.y : self.raisedLeftHand.y)) * easeT)
            self.updateArmCurvedPath(node: newArm, shoulder: newS, elbowControl: newE, hand: newH)
            
            let oldS = CGPoint(x: oldShoulderX, y: 10.0 + 2.5 * easeT)
            let oldE = CGPoint(x: (fromLeftToRight ? self.nearLeftElbow.x : self.nearRightElbow.x) + (targetOldElbow.x - (fromLeftToRight ? self.nearLeftElbow.x : self.nearRightElbow.x)) * easeT,
                               y: (fromLeftToRight ? self.nearLeftElbow.y : self.nearRightElbow.y) + (targetOldElbow.y - (fromLeftToRight ? self.nearLeftElbow.y : self.nearRightElbow.y)) * easeT)
            let oldH = CGPoint(x: (fromLeftToRight ? self.nearLeftHand.x : self.nearRightHand.x) + (targetOldHand.x - (fromLeftToRight ? self.nearLeftHand.x : self.nearRightHand.x)) * easeT,
                               y: (fromLeftToRight ? self.nearLeftHand.y : self.nearRightHand.y) + (targetOldHand.y - (fromLeftToRight ? self.nearLeftHand.y : self.nearRightHand.y)) * easeT)
            self.updateArmCurvedPath(node: oldArm, shoulder: oldS, elbowControl: oldE, hand: oldH)
            
            self.torso.zRotation = (fromLeftToRight ? -0.045 : 0.045) * easeT
            self.head.zRotation = (fromLeftToRight ? -0.03 : 0.03) * easeT
        }
        
        run(SKAction.sequence([switchAction, SKAction.run(completion)]))
    }
    
    /// Tangan & moncong senjata terangkat jelas (+10 pt) selama 0.15 detik sebelum menembak
    func playPreShootAnticipation(isLeft: Bool, duration: TimeInterval = 0.15, completion: @escaping () -> Void) {
        let arm = isLeft ? leftArm : rightArm
        let gun = isLeft ? leftGun : rightGun
        let shoulder = CGPoint(x: isLeft ? -10 : 10, y: 10.5) // Terkunci aman di torso
        
        let startHand = isLeft ? nearLeftHand : nearRightHand
        let startElbow = isLeft ? nearLeftElbow : nearRightElbow
        
        // 🎯 Tangan naik +10 pt, siku melebar +6 pt, pistol mendongak tajam
        let targetHand = CGPoint(x: startHand.x + (isLeft ? 2.0 : -2.0), y: startHand.y + 10.0)
        let targetElbow = CGPoint(x: startElbow.x + (isLeft ? -3.5 : 3.5), y: startElbow.y + 6.0)
        let targetRotation: CGFloat = isLeft ? 0.22 : -0.22
        
        let liftAction = SKAction.customAction(withDuration: duration) { [weak self] _, time in
            guard let self = self else { return }
            let p = time / CGFloat(duration)
            let easeOut = 1.0 - pow(1.0 - p, 2.5) // Akselerasi cepat mencabut
            
            let curHand = CGPoint(
                x: startHand.x + (targetHand.x - startHand.x) * easeOut,
                y: startHand.y + (targetHand.y - startHand.y) * easeOut
            )
            let curElbow = CGPoint(
                x: startElbow.x + (targetElbow.x - startElbow.x) * easeOut,
                y: startElbow.y + (targetElbow.y - startElbow.y) * easeOut
            )
            
            self.updateArmCurvedPath(node: arm, shoulder: shoulder, elbowControl: curElbow, hand: curHand)
            gun.position = curHand
            gun.zRotation = targetRotation * easeOut
        }
        
        let holdPeak = SKAction.wait(forDuration: 0.03)
        run(SKAction.sequence([liftAction, holdPeak, SKAction.run(completion)]))
    }
    
    // MARK: - Cabut Pistol & Tembak ke Depan
    func drawGunAndShoot(isLeft: Bool, duration: TimeInterval = 0.09) {
        let arm = isLeft ? leftArm : rightArm
        let gun = isLeft ? leftGun : rightGun
        let shoulder = CGPoint(x: isLeft ? -10 : 10, y: 10.5)
        
        let aimElbow = CGPoint(x: isLeft ? -13 : 13, y: 1)
        let aimHand  = CGPoint(x: isLeft ? -12 : 12, y: -16)
        
        updateArmCurvedPath(node: arm, shoulder: shoulder, elbowControl: aimElbow, hand: aimHand)
        
        gun.run(SKAction.group([
            SKAction.move(to: aimHand, duration: duration),
            SKAction.rotate(toAngle: isLeft ? -0.05 : 0.05, duration: duration)
        ]))
    }
    
    // MARK: - Juice Topi Terpental
    func playHatGrazedAnimation(isLeftBullet: Bool) {
        hatNode.removeAction(forKey: "hatGraze")
        let tiltAngle: CGFloat = isLeftBullet ? -0.42 : 0.42
        let liftX: CGFloat = isLeftBullet ? 7.0 : -7.0
        
        let flyUp = SKAction.group([
            SKAction.move(to: CGPoint(x: liftX, y: 34.0), duration: 0.08),
            SKAction.rotate(toAngle: tiltAngle, duration: 0.08)
        ])
        flyUp.timingMode = .easeOut
        
        let fallBack = SKAction.group([
            SKAction.move(to: CGPoint(x: 0, y: 24.0), duration: 0.14),
            SKAction.rotate(toAngle: 0, duration: 0.14)
        ])
        fallBack.timingMode = .easeIn
        
        let bounce = SKAction.sequence([
            SKAction.moveBy(x: 0, y: -3, duration: 0.04),
            SKAction.moveBy(x: 0, y: 3, duration: 0.04)
        ])
        
        hatNode.run(SKAction.sequence([flyUp, fallBack, bounce]), withKey: "hatGraze")
    }
    
    // MARK: - Animasi Bayangan Saat Karakter Melompat
        func animateJumpShadow(isJumping: Bool, jumpHeight: CGFloat = 22.0) {
            groundShadow.removeAction(forKey: "shadowJump")
            
            if isJumping {
                // Saat melayang ke udara: bayangan tetap di tanah & mengecil tipis
                let moveDown = SKAction.move(to: CGPoint(x: 0, y: -43 - jumpHeight), duration: 0.09)
                let shrink = SKAction.scale(to: 0.68, duration: 0.09)
                let fade = SKAction.fadeAlpha(to: 0.10, duration: 0.09)
                groundShadow.run(SKAction.group([moveDown, shrink, fade]), withKey: "shadowJump")
            } else {
                // Saat mendarat: bayangan kembali pas di bawah telapak kaki
                let moveUp = SKAction.move(to: CGPoint(x: 0, y: -43), duration: 0.08)
                let expand = SKAction.scale(to: 1.0, duration: 0.08)
                let unFade = SKAction.fadeAlpha(to: 0.22, duration: 0.08)
                groundShadow.run(SKAction.group([moveUp, expand, unFade]), withKey: "shadowJump")
            }
        }
}
