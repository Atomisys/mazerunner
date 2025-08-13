import AVFoundation

class SoundPlayer {
    private var audioPlayer: AVAudioPlayer?
    private let fileName: String
    
    init(fileName: String) {
        self.fileName = fileName
        setupAudioPlayer()
    }
    
    private func setupAudioPlayer() {
        guard let path = Bundle.main.path(forResource: fileName, ofType: "mp3") else {
            print("Error: Could not find audio file \(fileName).mp3")
            return
        }
        
        let url = URL(fileURLWithPath: path)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Error loading audio file: \(error.localizedDescription)")
        }
    }
    
    func play(volume: Float = 1.0) {
        guard let player = audioPlayer else {
            print("Error: Audio player not initialized")
            return
        }
        
        // Set volume (0.0 to 1.0)
        player.volume = max(0.0, min(1.0, volume))
        
        // If already playing, stop and restart
        if player.isPlaying {
            player.stop()
        }
        
        player.currentTime = 0
        player.play()
    }
    
    func stop() {
        audioPlayer?.stop()
    }
    
    func isPlaying() -> Bool {
        return audioPlayer?.isPlaying ?? false
    }
}
