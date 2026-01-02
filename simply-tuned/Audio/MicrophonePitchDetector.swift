import AudioKit
import Foundation
import SoundpipeAudioKit

final class MicrophonePitchDetector {
    struct Sample {
        let frequencyHz: Double
        let confidence: Double
    }

    enum DetectorError: Error {
        case inputUnavailable
    }

    var onPitch: ((Sample) -> Void)?

    private let engine = AudioEngine()
    private var pitchTap: PitchTap?
    private var outputMixer: Mixer?
    private var isRunning = false

    func start() throws {
        guard !isRunning else { return }

        try MicrophoneAudioSession.configureForTuner()
        guard let input = engine.input else {
            throw DetectorError.inputUnavailable
        }

        let mixer = Mixer(input)
        mixer.volume = 0
        engine.output = mixer
        outputMixer = mixer

        pitchTap = PitchTap(input, bufferSize: 4096) { [weak self] pitches, amplitudes in
            guard let self else { return }
            let (frequency, amplitude) = self.strongestChannel(pitches: pitches, amplitudes: amplitudes)
            let confidence = self.normalizedConfidence(from: amplitude)
            self.onPitch?(Sample(frequencyHz: frequency, confidence: confidence))
        }

        try engine.start()
        pitchTap?.start()
        isRunning = true
    }

    func stop() {
        pitchTap?.stop()
        pitchTap = nil
        engine.stop()
        outputMixer = nil
        isRunning = false
    }

    private func normalizedConfidence(from amplitude: Float) -> Double {
        min(1, max(0, Double(amplitude)))
    }

    private func strongestChannel(pitches: [Float], amplitudes: [Float]) -> (Double, Float) {
        let count = min(pitches.count, amplitudes.count)
        guard count > 0 else { return (0, 0) }

        var bestIndex = 0
        var bestAmplitude = amplitudes[0]

        if count > 1 {
            for index in 1..<count where amplitudes[index] > bestAmplitude {
                bestAmplitude = amplitudes[index]
                bestIndex = index
            }
        }

        let frequency = Double(pitches[bestIndex])
        return (frequency, bestAmplitude)
    }
}
