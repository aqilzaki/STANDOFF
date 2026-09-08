//
//  TutorialOverlayNode.swift
//  aqil.game
//
import SpriteKit

enum CowboyTutorialStep: Equatable {
    case dodgeRight
    case dodgeLeft
    case feintReaction
    case perfectDodge
    case completed
}

class TutorialOverlayNode: SKNode {
    
    private var bannerPill: SKShapeNode!
    private var actionLabel: SKLabelNode!
    private var subLabel: SKLabelNode!
    
    private var swipeGuideNode: SKNode!
    private var swipePathNode: SKShapeNode!
    private var swipeFingerDot: SKShapeNode!
    private var arrowHead: SKShapeNode!
    
    private let dodgeDistance: CGFloat = 52.0
    
    init(size: CGSize) {
        super.init()
        zPosition = 180
        alpha = 0.0
        
        setupSimpleBanner(screenSize: size)
        setupSwipeGuide()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSimpleBanner(screenSize: CGSize) {
        let bannerWidth = min(280.0, screenSize.width * 0.78)
        let bannerHeight: CGFloat = 64.0
        
        bannerPill = SKShapeNode(rectOf: CGSize(width: bannerWidth, height: bannerHeight), cornerRadius: 16)
        bannerPill.fillColor = SKColor(red: 0.14, green: 0.10, blue: 0.08, alpha: 0.94)
        bannerPill.strokeColor = SKColor(red: 0.90, green: 0.75, blue: 0.40, alpha: 0.90)
        bannerPill.lineWidth = 2.0
        bannerPill.position = CGPoint(x: screenSize.width / 2, y: screenSize.height - 115)
        addChild(bannerPill)
        
        actionLabel = SKLabelNode(fontNamed: "HelveticaNeue-Black")
        actionLabel.fontSize = 20
        actionLabel.fontColor = .white
        actionLabel.position = CGPoint(x: 0, y: 3)
        bannerPill.addChild(actionLabel)
        
        subLabel = SKLabelNode(fontNamed: "HelveticaNeue-Bold")
        subLabel.fontSize = 11
        subLabel.fontColor = SKColor(red: 0.90, green: 0.75, blue: 0.40, alpha: 1.0)
        subLabel.position = CGPoint(x: 0, y: -18)
        bannerPill.addChild(subLabel)
    }
    
    private func setupSwipeGuide() {
        swipeGuideNode = SKNode()
        swipeGuideNode.zPosition = 60
        addChild(swipeGuideNode)
        
        swipePathNode = SKShapeNode()
        swipePathNode.lineWidth = 4.0
        swipePathNode.strokeColor = SKColor(red: 0.95, green: 0.80, blue: 0.30, alpha: 0.85)
        swipePathNode.lineCap = .round
        swipeGuideNode.addChild(swipePathNode)
        
        swipeFingerDot = SKShapeNode(circleOfRadius: 8.5)
        swipeFingerDot.fillColor = SKColor(red: 0.98, green: 0.88, blue: 0.45, alpha: 1.0)
        swipeFingerDot.strokeColor = .white
        swipeFingerDot.lineWidth = 2.0
        swipeGuideNode.addChild(swipeFingerDot)
        
        arrowHead = SKShapeNode()
        arrowHead.fillColor = SKColor(red: 0.98, green: 0.88, blue: 0.45, alpha: 1.0)
        arrowHead.strokeColor = .clear
        swipeGuideNode.addChild(arrowHead)
    }
    
    func showFreezePrompt(action: String, sub: String, isRight: Bool, screenSize: CGSize) {
        removeAllActions()
        run(SKAction.fadeIn(withDuration: 0.15))
        
        actionLabel.text = action
        subLabel.text = sub
        
        bannerPill.run(SKAction.sequence([
            SKAction.scale(to: 1.08, duration: 0.08),
            SKAction.scale(to: 1.0, duration: 0.08)
        ]))
        
        let midX = screenSize.width / 2.0
        let playerY: CGFloat = 140.0
        let targetX = midX + (isRight ? dodgeDistance : -dodgeDistance)
        
        animateSwipeArc(from: CGPoint(x: midX, y: playerY), to: CGPoint(x: targetX, y: playerY + 16), isRight: isRight)
    }
    
    private func animateSwipeArc(from start: CGPoint, to end: CGPoint, isRight: Bool) {
        swipeGuideNode.alpha = 1.0
        swipeGuideNode.removeAllActions()
        
        let path = UIBezierPath()
        let controlPoint = CGPoint(x: (start.x + end.x) / 2.0, y: start.y + 35.0)
        path.move(to: start)
        path.addQuadCurve(to: end, controlPoint: controlPoint)
        swipePathNode.path = path.cgPath
        
        let arrowPath = UIBezierPath()
        let arrowSize: CGFloat = 7.0
        let angle: CGFloat = isRight ? 0.35 : (.pi - 0.35)
        arrowPath.move(to: end)
        arrowPath.addLine(to: CGPoint(x: end.x - cos(angle - 0.5) * arrowSize * 2,
                                      y: end.y - sin(angle - 0.5) * arrowSize * 2))
        arrowPath.addLine(to: CGPoint(x: end.x - cos(angle + 0.5) * arrowSize * 2,
                                      y: end.y - sin(angle + 0.5) * arrowSize * 2))
        arrowPath.close()
        arrowHead.path = arrowPath.cgPath
        
        let animate = SKAction.customAction(withDuration: 0.55) { [weak self] _, time in
            guard let self = self else { return }
            let t = time / 0.55
            let oneMinusT = 1.0 - t
            let posX = oneMinusT * oneMinusT * start.x + 2 * oneMinusT * t * controlPoint.x + t * t * end.x
            let posY = oneMinusT * oneMinusT * start.y + 2 * oneMinusT * t * controlPoint.y + t * t * end.y
            self.swipeFingerDot.position = CGPoint(x: posX, y: posY)
        }
        
        swipeGuideNode.run(SKAction.repeatForever(SKAction.sequence([
            animate,
            SKAction.wait(forDuration: 0.2)
        ])))
    }
    
    func hide() {
        removeAllActions()
        swipeGuideNode.removeAllActions()
        run(SKAction.fadeOut(withDuration: 0.15))
    }
    
    func shakeBanner() {
        bannerPill.run(SKAction.sequence([
            SKAction.moveBy(x: -8, y: 0, duration: 0.03),
            SKAction.moveBy(x: 16, y: 0, duration: 0.03),
            SKAction.moveBy(x: -8, y: 0, duration: 0.03)
        ]))
    }
}
