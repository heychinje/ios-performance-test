//
//  BackgroundTaskManager.swift
//  PerformanceTest
//
//  Created by Zheng, Haiqiang (Jason) on 2025/7/8.
//

import AVFoundation

/// Manages background task execution using silent audio
class BackgroundTaskManager {
    
    // MARK: - Properties
    
    private var audioPlayer: AVAudioPlayer?
    private var backgroundTimer: Timer?
    private var isEnabled: Bool = true
    
    // MARK: - Public Methods
    
    func configure() {
        setupAudioSession()
        createSilentAudioPlayer()
    }
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        print("Background task manager \(enabled ? "enabled" : "disabled")")
    }
    
    func startBackgroundExecution() {
        guard isEnabled else {
            print("Background task manager is disabled")
            return
        }
        
        print("Starting background execution...")
        
        if let audioPlayer = audioPlayer {
            let success = audioPlayer.play()
            print("Silent audio playback: \(success ? "started" : "failed")")
            
            startBackgroundTimer()
            performBackgroundTask()
        } else {
            print("Audio player unavailable, recreating...")
            createSilentAudioPlayer()
            if let audioPlayer = audioPlayer {
                let success = audioPlayer.play()
                print("Recreated audio player: \(success ? "started" : "failed")")
                startBackgroundTimer()
                performBackgroundTask()
            }
        }
    }
    
    func stopBackgroundExecution() {
        print("Stopping background execution...")
        
        audioPlayer?.pause()
        stopBackgroundTimer()
    }
    
    func cleanup() {
        audioPlayer?.stop()
        audioPlayer = nil
        stopBackgroundTimer()
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Error deactivating audio session: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, options: .mixWithOthers)
            try audioSession.setActive(true)
        } catch {
            print("Error setting up audio session: \(error)")
        }
    }
    
    private func createSilentAudioPlayer() {
        guard let audioData = SilentAudioGenerator.createSilentAudioData() else {
            print("Failed to create silent audio data")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.volume = 0.0
            audioPlayer?.prepareToPlay()
        } catch {
            print("Error creating audio player: \(error)")
        }
    }
    
    private func startBackgroundTimer() {
        backgroundTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.performBackgroundTask()
        }
    }
    
    private func stopBackgroundTimer() {
        backgroundTimer?.invalidate()
        backgroundTimer = nil
    }
    
    private func performBackgroundTask() {
        DispatchQueue.global(qos: .background).async {
            print("Background task executing...")
            Thread.sleep(forTimeInterval: 3.0)
            print("Background task completed")
        }
    }
} 