import Combine
import Foundation
import SwiftUI

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

    private var timerCancellable: AnyCancellable?
    private var centsSmoother = ExponentialMovingAverage(alpha: 0.25)

    private var autoLockedString: TuningString?
    private var autoDriftBeganAt: Date?

    private var mockStartedAt: Date = .distantPast
    private var mockSegmentIndex: Int = 0
    private var mockSegmentStartedAt: Date = .distantPast
    private var mockInitialCentsForSegment: Double = 0

    private var manualMockStartedAt: Date = .distantPast
    private var manualMockInitialCents: Double = 0

    func startMocking() {
        guard timerCancellable == nil else { return }

        mockStartedAt = .now
        mockSegmentIndex = 0
        mockSegmentStartedAt = mockStartedAt
        mockInitialCentsForSegment = initialCentsForMockSegment(0)

        manualMockStartedAt = mockStartedAt
        manualMockInitialCents = initialCentsForManualString(selectedString)

        timerCancellable = Timer
            .publish(every: 1.0 / 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in
                self?.tickMock(at: now)
            }
    }

    func stopMocking() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    func selectString(_ string: TuningString) {
        selectedString = string
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

        if isAutoDetectEnabled {
            mockSegmentIndex = 0
            mockSegmentStartedAt = .now
            mockInitialCentsForSegment = initialCentsForMockSegment(mockSegmentIndex)
        }
    }

    private func handleAutoDetectToggled(from oldValue: Bool) {
        guard isAutoDetectEnabled != oldValue else { return }

        autoLockedString = nil
        autoDriftBeganAt = nil
        centsSmoother.reset()

        if isAutoDetectEnabled {
            mockSegmentIndex = 0
            mockSegmentStartedAt = .now
            mockInitialCentsForSegment = initialCentsForMockSegment(mockSegmentIndex)
        } else {
            manualMockStartedAt = .now
            manualMockInitialCents = initialCentsForManualString(selectedString)
        }
    }

    private func handleSelectedStringChanged(from oldValue: TuningString) {
        guard selectedString != oldValue else { return }

        centsSmoother.reset()
        autoLockedString = isAutoDetectEnabled ? selectedString : nil
        autoDriftBeganAt = nil

        if !isAutoDetectEnabled {
            manualMockStartedAt = .now
            manualMockInitialCents = initialCentsForManualString(selectedString)
        }
    }

    private func tickMock(at now: Date) {
        let (rawDetectedFrequencyHz, rawConfidence) = generateMockSample(at: now)

        detectedFrequencyHz = rawDetectedFrequencyHz
        confidence = rawConfidence

        if isAutoDetectEnabled {
            updateAutoSelectedString(using: rawDetectedFrequencyHz, now: now)
        }

        let rawCents = Cents.offset(from: rawDetectedFrequencyHz, targetHz: selectedString.frequencyHz)
        let smoothedCents = centsSmoother.update(with: rawCents)
        centsOffset = Cents.clampedForUI(smoothedCents)
    }

    private func generateMockSample(at now: Date) -> (frequencyHz: Double, confidence: Double) {
        guard !selectedTuning.strings.isEmpty else {
            return (0, 0)
        }

        if isAutoDetectEnabled {
            let segmentDuration: TimeInterval = 3.0
            let elapsed = now.timeIntervalSince(mockStartedAt)
            let segmentIndex = Int(elapsed / segmentDuration) % selectedTuning.strings.count

            if segmentIndex != mockSegmentIndex {
                mockSegmentIndex = segmentIndex
                mockSegmentStartedAt = now
                mockInitialCentsForSegment = initialCentsForMockSegment(segmentIndex)
                centsSmoother.reset()
            }

            let segmentElapsed = now.timeIntervalSince(mockSegmentStartedAt)
            let baseString = selectedTuning.strings[mockSegmentIndex]

            let decay = exp(-segmentElapsed / 1.8)
            let wobble = 2.0 * sin(segmentElapsed * 2.0 * .pi * 1.6)
            let noise = Double.random(in: -0.6...0.6)

            let cents = mockInitialCentsForSegment * decay + wobble + noise
            let frequencyHz = baseString.frequencyHz * pow(2, cents / 1200.0)
            let confidence = mockConfidence(for: cents)
            return (frequencyHz, confidence)
        } else {
            let elapsed = now.timeIntervalSince(manualMockStartedAt)
            let decay = exp(-elapsed / 3.0)
            let wobble = 1.25 * sin(elapsed * 2.0 * .pi * 1.1)
            let noise = Double.random(in: -0.35...0.35)

            let cents = manualMockInitialCents * decay + wobble + noise
            let frequencyHz = selectedString.frequencyHz * pow(2, cents / 1200.0)
            let confidence = mockConfidence(for: cents)
            return (frequencyHz, confidence)
        }
    }

    private func initialCentsForMockSegment(_ index: Int) -> Double {
        let sign: Double = (index % 2 == 0) ? 1 : -1
        let magnitude = Double((index * 19) % 26 + 10) // 10...35
        return sign * magnitude
    }

    private func initialCentsForManualString(_ string: TuningString) -> Double {
        let scalarSum = string.name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        let sign: Double = (scalarSum % 2 == 0) ? 1 : -1
        let magnitude = Double((scalarSum % 21) + 8) // 8...28
        return sign * magnitude
    }

    private func mockConfidence(for cents: Double) -> Double {
        let closeness = 1.0 - min(1.0, abs(cents) / 50.0)
        return min(1.0, max(0.0, 0.55 + 0.45 * closeness))
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
