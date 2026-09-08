//
//  GameSettings.swift
//  aqil.game
//
//  Created by muhammad aqil zaki on 08/09/26.
//


//
//  GameSettings.swift
//  aqil.game
//
import Foundation
import CoreGraphics

// =============================================================================
// MARK: - PUSAT PENGATURAN GAME
// =============================================================================
struct GameSettings {
    // 1. SISTEM NYAWA
    static let maxPlayerLives: Int = 3
    
    // 2. TOLERANSI PARRY (TIMING TAP)
    static let parryWindowInitial: TimeInterval = 0.22
    static let parryWindowMinimum: TimeInterval = 0.09
    static let parryWindowScaling: Double = 0.008
    
    // 3. KECEPATAN TEBASAN PEDANG LAWAN
    static let slashDurationInitial: TimeInterval = 0.24
    static let slashDurationMinimum: TimeInterval = 0.12
    static let slashScaling: Double = 0.012
    
    // 4. JEDA ANCANG-ANCANG & RECHARGE LAWAN
    static let phase1IdleDuration: TimeInterval = 0.95
    static let phase1WindupDuration: TimeInterval = 0.36
    static let phase2FastWindup: TimeInterval = 0.26
    static let phase2NormalWindup: TimeInterval = 0.33
    static let phase3BlitzDuration: TimeInterval = 0.20
    static let phase3LongStandoff: ClosedRange<Double> = 0.9...1.8
    
    // 5. GERTAKAN (FEINT)
    static let feintPauseDelay: TimeInterval = 0.22
    static let feintChancePhase2: Double = 0.30
    static let feintChancePhase3: Double = 0.45
    
    // 6. KONTROL PEMAIN
    static let playerTiltAngle: CGFloat = 0.35 * (.pi / 180.0) // Sudut miring dalam radian
    static let playerTiltDuration: TimeInterval = 0.04
    static let playerResetDuration: TimeInterval = 0.08
    
    // 7. UKURAN & POSISI
    static let enemyScale: CGFloat = 8.0
    static let enemyPositionYRatio: CGFloat = -0.25
    static let enemySwordScale: CGFloat = 5.8
    static let playerBodyBaseY: CGFloat = 50.0
    
    // 8. SKOR
    static let baseScorePerParry: Int = 150
}

// MARK: - State Enums
enum CombatSide: Equatable {
    case left
    case right
}

enum AttackDirection: Equatable {
    case leftToRight
    case rightToLeft
}

enum TutorialStep: Equatable {
    case parryRight
    case parryLeft
    case holdRight
    case holdLeft
    case completed
}

enum DuelPhase: Equatable {
    case idleStance
    case windup
    case slashing
}
