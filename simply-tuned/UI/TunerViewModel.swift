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
    @Published var inTune: Bool = false
    @Published var successEvent: Int = 0
    @Published var microphonePermissionState: MicrophonePermissionState = .undetermined

    private let pitchDetector = MicrophonePitchDetector()
    private let stringSelector = StringSelectionController()
    private let inTuneGate = InTuneGate()
    private var centsSmoother = ExponentialMovingAverage(alpha: 0.25)

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
        inTune = false
        centsSmoother.reset()
        inTuneGate.reset()
    }

    private func handlePitchSample(_ sample: MicrophonePitchDetector.Sample) {
        guard sample.frequencyHz > 0 else {
            clearPitchValues()
            return
        }

        let now = Date()
        let resolvedString = stringSelector.selectString(
            detectedFrequencyHz: sample.frequencyHz,
            tuning: selectedTuning,
            userSelectedString: selectedString,
            isAutoDetectEnabled: isAutoDetectEnabled,
            now: now
        )
        if resolvedString != selectedString {
            selectedString = resolvedString
        }

        detectedFrequencyHz = sample.frequencyHz
        confidence = sample.confidence

        let rawCents = Cents.offset(from: sample.frequencyHz, targetHz: resolvedString.frequencyHz)
        let smoothedCents = centsSmoother.update(with: rawCents)
        let inTuneUpdate = inTuneGate.update(cents: smoothedCents, now: now)
        inTune = inTuneUpdate.isInTune
        if inTuneUpdate.didTrigger {
            successEvent += 1
        }
        centsOffset = Cents.clampedForUI(smoothedCents)
    }

    private func handleTuningChanged(from oldValue: Tuning) {
        stringSelector.reset()
        resetInTuneState()
        centsSmoother.reset()

        if let matching = selectedTuning.strings.first(where: { $0.name == selectedString.name }) {
            selectedString = matching
        } else {
            selectedString = selectedTuning.strings[0]
        }
    }

    private func handleAutoDetectToggled(from oldValue: Bool) {
        guard isAutoDetectEnabled != oldValue else { return }

        stringSelector.reset()
        resetInTuneState()
        centsSmoother.reset()
    }

    private func handleSelectedStringChanged(from oldValue: TuningString) {
        guard selectedString != oldValue else { return }

        resetInTuneState()
        centsSmoother.reset()
    }

    private func resetInTuneState() {
        inTuneGate.reset()
        inTune = false
    }
}
