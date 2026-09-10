//
//  Audio.swift
//  game c5
//
//  Created by carstenz meru phantara on 09/09/26.
//

import AVFoundation

final class SoundManager {
    static let shared = SoundManager()

    private let engine = AVAudioEngine()
    private var voices: [(player: AVAudioPlayerNode, pitch: AVAudioUnitTimePitch)] = []
    private var buffers: [String: AVAudioPCMBuffer] = [:]
    private var nextVoice = 0
    private let voiceCount = 6 
    private let bgmPlayer = AVAudioPlayerNode()
    
    private init() {
        for _ in 0..<voiceCount {
            let player = AVAudioPlayerNode()
            let pitch = AVAudioUnitTimePitch()
            engine.attach(player)
            engine.attach(pitch)
            engine.connect(player, to: pitch, format: nil)
            engine.connect(pitch, to: engine.mainMixerNode, format: nil)
            voices.append((player, pitch))
        }
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        try? engine.start()
    }

    // call once per sound file, e.g. at app/scene launch
    func preload(_ fileName: String) {
        guard buffers[fileName] == nil,
              let url = Bundle.main.url(forResource: fileName, withExtension: nil),
              let file = try? AVAudioFile(forReading: url),
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
        else { return }
        try? file.read(into: buffer)
        buffers[fileName] = buffer
    }

    /// pitchRangeCents: 1200 = one octave. ±150 is a subtle, natural-sounding wobble.
    func play(_ fileName: String, pitchRangeCents: ClosedRange<Float> = -150...150, volume: Float = 1.0) {
        guard let buffer = buffers[fileName] else { return }
        let voice = voices[nextVoice]
        nextVoice = (nextVoice + 1) % voices.count

        voice.pitch.pitch = Float.random(in: pitchRangeCents)
        voice.player.volume = volume
        voice.player.stop()
        voice.player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        voice.player.play()
    }
    // 2. Gunakan ini khusus untuk memutar BGM secara looping
        func playBGM(_ fileName: String, volume: Float = 1.0) {
            guard let buffer = buffers[fileName] else { return }
            
            bgmPlayer.stop() // Hentikan lagu sebelumnya jika ada
            bgmPlayer.volume = volume
            
            // Kunci utamanya ada di options: .loops
            bgmPlayer.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            bgmPlayer.play()
        }
        
        // 3. Tambahan fungsi jika kamu ingin menghentikan BGM (misal: game over)
        func stopBGM() {
            bgmPlayer.stop()
        }
}
