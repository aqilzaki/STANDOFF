//
//  ContentView.swift
//  game.c5
//
//  Created by muhammad aqil zaki on 31/08/26.
//


import SwiftUI
import SpriteKit

struct ContentView: View {
    // Set up the GameScene to fill the device screen
    var scene: SKScene {
        let scene = GameScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .resizeFill
        return scene
    }
    
    var body: some View {
        // Render the SpriteKit scene inside SwiftUI
        SpriteView(scene: scene)
            .ignoresSafeArea() // Pushes the scene to the very edges of the screen
    }
}

#Preview {
    ContentView()
}
