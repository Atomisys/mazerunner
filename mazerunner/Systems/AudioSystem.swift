import AVFoundation

/// System responsible for centralizing all audio management in the game
/// Leverages the existing SoundPlayer functionality and manages all audio files
final class AudioSystem {
    
    // MARK: - Audio Types
    
    /// Types of audio that can be played
    enum AudioType {
        case start
        case cherry
        case death
        case wall
        case enemy
        case player
        case levelComplete
        case gameOver
    }
    
    // MARK: - Properties
    
    /// Dictionary to store audio players for each sound type
    private var audioPlayers: [AudioType: SoundPlayer] = [:]
    
    /// Master volume control (0.0 to 1.0)
    private var masterVolume: Float = 1.0
    
    /// Whether audio is enabled
    private var isAudioEnabled: Bool = true
    
    /// Whether sound effects are enabled
    private var isSoundEffectsEnabled: Bool = true
    
    /// Whether background music is enabled
    private var isBackgroundMusicEnabled: Bool = true
    
    // MARK: - Audio File Mapping
    
    /// Mapping of audio types to their file names
    private let audioFileMapping: [AudioType: String] = [
        .start: "start",
        .cherry: "cherry", 
        .death: "death",
        .wall: "wall"
    ]
    
    // MARK: - Initialization
    
    init() {
        setupAudioPlayers()
        configureAudioSession()
    }
    
    // MARK: - Setup
    
    /// Set up all audio players
    private func setupAudioPlayers() {
        for (audioType, fileName) in audioFileMapping {
            let soundPlayer = SoundPlayer(fileName: fileName)
            audioPlayers[audioType] = soundPlayer
        }
    }
    
    /// Configure the audio session
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error configuring audio session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Audio Playback
    
    /// Play a specific audio type
    /// - Parameters:
    ///   - audioType: The type of audio to play
    ///   - volume: Volume level (0.0 to 1.0), defaults to master volume
    func play(_ audioType: AudioType, volume: Float? = nil) {
        guard isAudioEnabled else { return }
        
        // Check if this type should be played based on settings
        if !shouldPlayAudioType(audioType) { return }
        
        guard let soundPlayer = audioPlayers[audioType] else {
            print("Warning: No audio player found for type: \(audioType)")
            return
        }
        
        let effectiveVolume = volume ?? masterVolume
        soundPlayer.play(volume: effectiveVolume)
    }
    
    /// Stop a specific audio type
    /// - Parameter audioType: The type of audio to stop
    func stop(_ audioType: AudioType) {
        guard let soundPlayer = audioPlayers[audioType] else { return }
        soundPlayer.stop()
    }
    
    /// Stop all audio
    func stopAll() {
        for soundPlayer in audioPlayers.values {
            soundPlayer.stop()
        }
    }
    
    /// Check if a specific audio type is currently playing
    /// - Parameter audioType: The type of audio to check
    /// - Returns: True if the audio is playing
    func isPlaying(_ audioType: AudioType) -> Bool {
        guard let soundPlayer = audioPlayers[audioType] else { return false }
        return soundPlayer.isPlaying()
    }
    
    // MARK: - Game-Specific Audio Methods
    
    /// Play start game sound
    func playStartSound() {
        play(.start)
    }
    
    /// Play cherry collection sound
    func playCherrySound() {
        play(.cherry)
    }
    
    /// Play death sound
    func playDeathSound() {
        play(.death)
    }
    
    /// Play wall digging sound
    func playWallSound() {
        play(.wall)
    }
    
    /// Play enemy collision sound
    func playEnemySound() {
        // For now, use death sound for enemy collisions
        // In the future, we could add a specific enemy sound file
        play(.death, volume: masterVolume * 0.7) // Slightly quieter
    }
    
    /// Play player movement sound
    func playPlayerSound() {
        // For now, use wall sound for player movement
        // In the future, we could add a specific player movement sound file
        play(.wall, volume: masterVolume * 0.3) // Much quieter
    }
    
    /// Play level complete sound
    func playLevelCompleteSound() {
        // For now, use start sound for level completion
        // In the future, we could add a specific level complete sound file
        play(.start, volume: masterVolume * 0.8)
    }
    
    /// Play game over sound
    func playGameOverSound() {
        // For now, use death sound for game over
        // In the future, we could add a specific game over sound file
        play(.death, volume: masterVolume * 0.9)
    }
    
    // MARK: - Volume Control
    
    /// Set the master volume
    /// - Parameter volume: Volume level (0.0 to 1.0)
    func setMasterVolume(_ volume: Float) {
        masterVolume = max(0.0, min(1.0, volume))
    }
    
    /// Get the current master volume
    /// - Returns: Current master volume level
    func getMasterVolume() -> Float {
        return masterVolume
    }
    
    /// Set volume for a specific audio type
    /// - Parameters:
    ///   - volume: Volume level (0.0 to 1.0)
    ///   - audioType: The type of audio to set volume for
    func setVolume(_ volume: Float, for audioType: AudioType) {
        // Note: This would require modifying SoundPlayer to support per-instance volume
        // For now, we'll use the master volume approach
        print("Volume control for specific audio types not yet implemented")
    }
    
    // MARK: - Audio Settings
    
    /// Enable or disable all audio
    /// - Parameter enabled: Whether audio should be enabled
    func setAudioEnabled(_ enabled: Bool) {
        isAudioEnabled = enabled
        if !enabled {
            stopAll()
        }
    }
    
    /// Check if audio is enabled
    /// - Returns: True if audio is enabled
    func getAudioEnabled() -> Bool {
        return isAudioEnabled
    }
    
    /// Enable or disable sound effects
    /// - Parameter enabled: Whether sound effects should be enabled
    func setSoundEffectsEnabled(_ enabled: Bool) {
        isSoundEffectsEnabled = enabled
    }
    
    /// Check if sound effects are enabled
    /// - Returns: True if sound effects are enabled
    func getSoundEffectsEnabled() -> Bool {
        return isSoundEffectsEnabled
    }
    
    /// Enable or disable background music
    /// - Parameter enabled: Whether background music should be enabled
    func setBackgroundMusicEnabled(_ enabled: Bool) {
        isBackgroundMusicEnabled = enabled
        if !enabled {
            // Stop any background music that might be playing
            stop(.start) // Assuming start.mp3 is background music
        }
    }
    
    /// Check if background music is enabled
    /// - Returns: True if background music is enabled
    func getBackgroundMusicEnabled() -> Bool {
        return isBackgroundMusicEnabled
    }
    
    // MARK: - Helper Methods
    
    /// Determine if an audio type should be played based on current settings
    /// - Parameter audioType: The type of audio to check
    /// - Returns: True if the audio should be played
    private func shouldPlayAudioType(_ audioType: AudioType) -> Bool {
        switch audioType {
        case .start:
            return isBackgroundMusicEnabled
        case .cherry, .death, .wall, .enemy, .player, .levelComplete, .gameOver:
            return isSoundEffectsEnabled
        }
    }
    
    // MARK: - Audio Session Management
    
    /// Pause audio system
    func pause() {
        // Pause all audio players
        for soundPlayer in audioPlayers.values {
            soundPlayer.stop()
        }
    }
    
    /// Resume audio system
    func resume() {
        // Resume any paused audio
        // Note: SoundPlayer doesn't have pause/resume, so we just stop
        // In a more sophisticated implementation, we'd track what was playing
    }
    
    /// Clean up audio resources
    func cleanup() {
        stopAll()
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Error deactivating audio session: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Debug Methods
    
    /// Print audio system status
    func printStatus() {
        print("=== Audio System Status ===")
        print("Master Volume: \(masterVolume)")
        print("Audio Enabled: \(isAudioEnabled)")
        print("Sound Effects Enabled: \(isSoundEffectsEnabled)")
        print("Background Music Enabled: \(isBackgroundMusicEnabled)")
        print("Active Audio Players: \(audioPlayers.count)")
        
        for (audioType, soundPlayer) in audioPlayers {
            let isPlaying = soundPlayer.isPlaying()
            print("  \(audioType): \(isPlaying ? "Playing" : "Stopped")")
        }
        print("==========================")
    }
    
    /// Test all audio files
    func testAllAudio() {
        print("Testing all audio files...")
        
        for audioType in AudioType.allCases {
            if audioPlayers[audioType] != nil {
                print("Testing \(audioType)...")
                play(audioType, volume: 0.5)
                
                // Wait a bit before testing the next sound
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.stop(audioType)
                }
            }
        }
    }
}

// MARK: - AudioType Extensions

extension AudioSystem.AudioType: CaseIterable {
    // This allows us to iterate through all audio types
}
