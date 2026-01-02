import Combine
import Foundation

@MainActor
final class TunerViewModel: ObservableObject {
    @Published var selectedTuning: Tuning = .standard {
        didSet { handleTuningChanged(from: oldValue) }
    }
    @Published var isAutoDetectEnabled: Bool = true {
        didSet { handleAutoDetectToggled(from: oldValue) }
    }

    @Published var selectedString: TuningString = Tuning.standard.strings[0] {
        didSet { handleSelectedStringChanged(from: oldValue) }
    }
    @Published var detectedFrequencyHz: Double = 0
    @Published var centsOffset: Double = 0
    @Published var confidence: Double = 0
    @Published var microphonePermissionState: MicrophonePermissionState = .undetermined

    private let pitchDetector = MicrophonePitchDetector()
    private var centsSmoother = ExponentialMovingAverage(alpha: 0.25)

    private var autoLockedString: TuningString?
    private var autoDriftBeganAt: Date?

    init() {
        pitchDetector.onPitch = { [weak self] sample in
            Task { @MainActor in
                self?.handlePitchSample(sample)
            }
        }
    }

    func startListening() {
        let permission = MicrophoneAudioSession.permissionState()
        microphonePermissionState = permission

        switch permission {
        case .granted:
            beginDetection()
        case .undetermined:
            MicrophoneAudioSession.requestPermission { [weak self] allowed in
                guard let self else { return }
                self.microphonePermissionState = allowed ? .granted : .denied
                if allowed {
                    self.beginDetection()
                } else {
                    self.stopListening()
                }
            }
        case .denied:
            stopListening()
        }
    }

    func stopListening() {
        pitchDetector.stop()
        clearPitchValues()
    }

    func selectString(_ string: TuningString) {
        selectedString = string
    }

    private func beginDetection() {
        do {
            try pitchDetector.start()
        } catch {
            pitchDetector.stop()
            clearPitchValues()
        }
    }

    private func clearPitchValues() {
        detectedFrequencyHz = 0
        confidence = 0
        centsOffset = 0
        centsSmoother.reset()
    }

    private func handlePitchSample(_ sample: MicrophonePitchDetector.Sample) {
        guard sample.frequencyHz > 0 else {
            clearPitchValues()
            return
        }

        detectedFrequencyHz = sample.frequencyHz
        confidence = sample.confidence

        if isAutoDetectEnabled {
            updateAutoSelectedString(using: sample.frequencyHz, now: Date())
        }

        let rawCents = Cents.offset(from: sample.frequencyHz, targetHz: selectedString.frequencyHz)
        let smoothedCents = centsSmoother.update(with: rawCents)
        centsOffset = Cents.clampedForUI(smoothedCents)
    }

    private func handleTuningChanged(from oldValue: Tuning) {
        autoLockedString = nil
        autoDriftBeganAt = nil
        centsSmoother.reset()

        if let matching = selectedTuning.strings.first(where: { $0.name == selectedString.name }) {
            selectedString = matching
        } else {
            selectedString = selectedTuning.strings[0]
        }
    }

    private func handleAutoDetectToggled(from oldValue: Bool) {
        guard isAutoDetectEnabled != oldValue else { return }

        autoLockedString = nil
        autoDriftBeganAt = nil
        centsSmoother.reset()
    }

    private func handleSelectedStringChanged(from oldValue: TuningString) {
        guard selectedString != oldValue else { return }

        centsSmoother.reset()
        autoDriftBeganAt = nil
    }

    private func updateAutoSelectedString(using detectedFrequencyHz: Double, now: Date) {
        guard detectedFrequencyHz > 0, !selectedTuning.strings.isEmpty else { return }

        let candidate = closestString(to: detectedFrequencyHz, in: selectedTuning)

        if autoLockedString == nil {
            autoLockedString = candidate
            selectedString = candidate
            autoDriftBeganAt = nil
            return
        }

        guard let lockedString = autoLockedString else { return }
        if candidate == lockedString { return }

        let lockedCents = Cents.offset(from: detectedFrequencyHz, targetHz: lockedString.frequencyHz)
        let unlockThresholdCents: Double = 120
        let unlockDuration: TimeInterval = 0.5

        if abs(lockedCents) <= unlockThresholdCents {
            autoDriftBeganAt = nil
            return
        }

        if let driftBeganAt = autoDriftBeganAt {
            if now.timeIntervalSince(driftBeganAt) >= unlockDuration {
                autoLockedString = candidate
                selectedString = candidate
                autoDriftBeganAt = nil
            }
        } else {
            autoDriftBeganAt = now
        }
    }

    private func closestString(to frequencyHz: Double, in tuning: Tuning) -> TuningString {
        var bestString = tuning.strings[0]
        var bestAbsCents = abs(Cents.offset(from: frequencyHz, targetHz: bestString.frequencyHz))

        for string in tuning.strings.dropFirst() {
            let absCents = abs(Cents.offset(from: frequencyHz, targetHz: string.frequencyHz))
            if absCents < bestAbsCents {
                bestAbsCents = absCents
                bestString = string
            }
        }

        return bestString
    }
}
