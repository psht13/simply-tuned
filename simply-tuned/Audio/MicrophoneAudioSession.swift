import AudioKit
import AVFoundation
import Foundation

enum MicrophonePermissionState: Equatable {
    case undetermined
    case granted
    case denied
}

enum MicrophoneAudioSession {
    static func permissionState() -> MicrophonePermissionState {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            return .granted
        case .denied:
            return .denied
        case .undetermined:
            return .undetermined
        @unknown default:
            return .undetermined
        }
    }

    static func requestPermission(_ completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { allowed in
            DispatchQueue.main.async {
                completion(allowed)
            }
        }
    }

    static func configureForTuner() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [
                .defaultToSpeaker,
                .allowBluetooth,
                .allowBluetoothA2DP,
            ]
        )
        try? session.setPreferredSampleRate(44_100)
        try? session.setPreferredInputNumberOfChannels(1)
        try? session.setPreferredIOBufferDuration(0.005)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        Settings.sampleRate = session.sampleRate
        Settings.channelCount = UInt32(max(session.inputNumberOfChannels, 1))
        Settings.bufferLength = .short
        Settings.recordingBufferLength = .short
    }
}
