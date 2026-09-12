//
//  Audio.swift
//  aqil.game (Crash-Proof Audio Engine with Auto-Background Mute)
//
import AVFoundation
import UIKit

final class SoundManager {
    static let shared = SoundManager()

    // Engine khusus efek suara (SFX)
    private let engine = AVAudioEngine()
    private var voices: [(player: AVAudioPlayerNode, pitch: AVAudioUnitTimePitch)] = []
    private var buffers: [String: AVAudioPCMBuffer] = [:]
    private var nextVoice = 0
    private let voiceCount = 6
    
    // Player khusus BGM
    private var bgmAudioPlayer: AVAudioPlayer?
    private var wasBGMPlayingBeforeBackground: Bool = false
    
    private init() {
        // 1. Hubungkan 6 voice untuk SFX
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
        
        setupLifecycleObservers()
    }
    
    private func setupLifecycleObservers() {
        // 1. Saat jari mulai geser keluar / app tidak aktif -> Hentikan audio instan!
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        // 2. Saat app sudah masuk ke background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // 3. Saat pemain membuka kembali app
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func handleAppWillResignActive() {
        if let player = bgmAudioPlayer, player.isPlaying {
            wasBGMPlayingBeforeBackground = true
            player.pause()
        } else {
            wasBGMPlayingBeforeBackground = false
        }
        engine.pause()
    }
    
    @objc private func handleAppDidEnterBackground() {
        bgmAudioPlayer?.pause()
        engine.pause()
    }
    
    @objc private func handleAppDidBecomeActive() {
        // Nyalakan kembali engine audio saat masuk app lagi
        try? engine.start()
        if wasBGMPlayingBeforeBackground {
            bgmAudioPlayer?.play()
        }
    }

    // Load file audio ke memori
    func preload(_ fileName: String) {
        guard buffers[fileName] == nil,
              let url = findAudioURL(fileName),
              let file = try? AVAudioFile(forReading: url),
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
        else { return }
        try? file.read(into: buffer)
        buffers[fileName] = buffer
    }

    /// Memutar SFX satu kali (tembakan, lonceng, dsb.)
    func play(_ fileName: String, pitchRangeCents: ClosedRange<Float> = -150...150, volume: Float = 1.0) {
        if buffers[fileName] == nil { preload(fileName) }
        guard let buffer = buffers[fileName] else { return }
        
        let voice = voices[nextVoice]
        nextVoice = (nextVoice + 1) % voices.count

        voice.pitch.pitch = Float.random(in: pitchRangeCents)
        voice.player.volume = volume
        voice.player.stop()
        voice.player.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
        voice.player.play()
    }
    
    /// 🔁 Memutar BGM secara LOOPING terus-menerus
    func playBGM(_ fileName: String, volume: Float = 0.6) {
        guard let url = findAudioURL(fileName) else {
            print("[SoundManager] Info: File BGM '\(fileName)' belum ada di project Xcode.")
            return
        }
        
        do {
            bgmAudioPlayer?.stop()
            bgmAudioPlayer = try AVAudioPlayer(contentsOf: url)
            bgmAudioPlayer?.numberOfLoops = -1
            bgmAudioPlayer?.volume = volume
            bgmAudioPlayer?.prepareToPlay()
            bgmAudioPlayer?.play()
            wasBGMPlayingBeforeBackground = true
        } catch {
            print("[SoundManager] Gagal memutar BGM: \(error)")
        }
    }
    
    /// Jeda BGM
    func pauseBGM() {
        bgmAudioPlayer?.pause()
        wasBGMPlayingBeforeBackground = false
    }
    
    /// Lanjutkan BGM
    func resumeBGM() {
        bgmAudioPlayer?.play()
        wasBGMPlayingBeforeBackground = true
    }
    
    /// Menghentikan BGM sepenuhnya
    func stopBGM() {
        bgmAudioPlayer?.stop()
        bgmAudioPlayer = nil
        wasBGMPlayingBeforeBackground = false
    }
    
    // Helper pencari file fleksibel
    private func findAudioURL(_ fileName: String) -> URL? {
        let name = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension.isEmpty ? "mp3" : (fileName as NSString).pathExtension
        
        return Bundle.main.url(forResource: name, withExtension: ext) ??
               Bundle.main.url(forResource: fileName, withExtension: nil)
    }
}
