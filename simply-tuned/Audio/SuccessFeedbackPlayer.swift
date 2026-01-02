import AVFoundation
import UIKit

final class SuccessFeedbackPlayer {
    private var player: AVAudioPlayer?
    private let haptics = UINotificationFeedbackGenerator()

    init() {
        if let url = Bundle.main.url(forResource: "success", withExtension: "wav") {
            player = try? AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
        }
    }

    func trigger() {
        haptics.prepare()
        haptics.notificationOccurred(.success)

        guard let player else { return }
        if player.isPlaying {
            player.stop()
        }
        player.currentTime = 0
        player.play()
    }
}
