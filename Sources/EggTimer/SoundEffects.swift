import AVFoundation

@MainActor
enum SoundEffects {
    private static let beepPlayer = makePlayer(named: "beep")
    private static let beepBeepPlayer = makePlayer(named: "beepbeep")

    static func preload() {
        _ = beepPlayer
        _ = beepBeepPlayer
    }

    static func playStartStop() {
        play(beepPlayer)
    }

    static func playEnd() {
        play(beepBeepPlayer)
    }

    private static func makePlayer(named name: String) -> AVAudioPlayer? {
        guard let url = Bundle.module.url(forResource: name, withExtension: "mp3"),
              let player = try? AVAudioPlayer(contentsOf: url) else {
            return nil
        }
        player.prepareToPlay()
        warmUp(player)
        return player
    }

    private static func warmUp(_ player: AVAudioPlayer) {
        player.volume = 0
        player.play()
        player.stop()
        player.currentTime = 0
        player.volume = 1
        player.prepareToPlay()
    }

    private static func play(_ player: AVAudioPlayer?) {
        guard let player else { return }
        if player.isPlaying {
            player.stop()
        }
        player.currentTime = 0
        player.play()
    }
}
