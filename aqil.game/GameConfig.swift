//
//  GameConfig.swift
//  aqil.game
//
import SpriteKit
import UIKit

// MARK: - Konfigurasi Level & Kecepatan
struct LevelConfig {
    let level: Int
    let title: String
    let duelsRequired: Int
    let standoffDelay: ClosedRange<Double>
    let handApproachDuration: Double
    let bulletSpeedDuration: Double
    let feintChance: Double
    let fakeHesitationChance: Double
}

struct LevelSystem {
    static let levels: [LevelConfig] = [
        LevelConfig(level: 1, title: "ROOKIE", duelsRequired: 3, standoffDelay: 1.3...1.6, handApproachDuration: 0.55, bulletSpeedDuration: 0.38, feintChance: 0.0, fakeHesitationChance: 0.0),
        LevelConfig(level: 2, title: "GUNSLINGER", duelsRequired: 7, standoffDelay: 0.85...1.15, handApproachDuration: 0.38, bulletSpeedDuration: 0.28, feintChance: 0.35, fakeHesitationChance: 0.15),
        LevelConfig(level: 3, title: "OUTLAW", duelsRequired: 12, standoffDelay: 0.55...0.80, handApproachDuration: 0.25, bulletSpeedDuration: 0.20, feintChance: 0.45, fakeHesitationChance: 0.25),
        LevelConfig(level: 4, title: "DESPERADO", duelsRequired: 18, standoffDelay: 0.35...0.55, handApproachDuration: 0.17, bulletSpeedDuration: 0.15, feintChance: 0.55, fakeHesitationChance: 0.30),
        LevelConfig(level: 5, title: "LEGEND", duelsRequired: Int.max, standoffDelay: 0.22...0.38, handApproachDuration: 0.12, bulletSpeedDuration: 0.12, feintChance: 0.65, fakeHesitationChance: 0.35)
    ]
    
    static func currentLevel(for duelCount: Int) -> LevelConfig {
        for config in levels {
            if duelCount < config.duelsRequired { return config }
        }
        return levels.last!
    }
}

// MARK: - Generator Efek Vignette Berdarah Prosedural
struct BloodVignetteHelper {
    static func generateTexture(screenSize: CGSize) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: screenSize)
        let image = renderer.image { context in
            let ctx = context.cgContext
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            
            // Radial Gradient: Tengah Bening -> Tepi Merah Darah Pekat
            let colors = [
                UIColor.clear.cgColor,
                UIColor.clear.cgColor,
                UIColor(red: 0.65, green: 0.02, blue: 0.02, alpha: 0.55).cgColor,
                UIColor(red: 0.40, green: 0.01, blue: 0.01, alpha: 0.95).cgColor
            ] as CFArray
            let locations: [CGFloat] = [0.0, 0.45, 0.78, 1.0]
            
            if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: locations) {
                let center = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
                let radius = max(screenSize.width, screenSize.height) * 0.72
                ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [.drawsAfterEndLocation])
            }
            
            // Percikan Darah di Sudut
            ctx.setFillColor(UIColor(red: 0.38, green: 0.01, blue: 0.01, alpha: 0.88).cgColor)
            let bloodSplatters: [(x: CGFloat, y: CGFloat, r: CGFloat)] = [
                (18, 28, 14), (36, 16, 9), (12, 60, 8), (4, 42, 11),
                (screenSize.width - 20, 26, 14), (screenSize.width - 42, 16, 9), (screenSize.width - 12, 58, 10),
                (18, screenSize.height - 30, 15), (42, screenSize.height - 18, 10), (12, screenSize.height - 65, 8),
                (screenSize.width - 20, screenSize.height - 32, 15), (screenSize.width - 45, screenSize.height - 18, 10)
            ]
            for s in bloodSplatters {
                ctx.fillEllipse(in: CGRect(x: s.x - s.r, y: s.y - s.r, width: s.r * 2, height: s.r * 2))
            }
        }
        return SKTexture(image: image)
    }
}
