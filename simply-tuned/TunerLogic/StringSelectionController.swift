import Foundation

final class StringSelectionController {
    private let driftThresholdCents: Double
    private let driftDuration: TimeInterval

    private var lockedString: TuningString?
    private var driftBeganAt: Date?

    init(driftThresholdCents: Double = 120, driftDuration: TimeInterval = 0.5) {
        self.driftThresholdCents = driftThresholdCents
        self.driftDuration = driftDuration
    }

    func reset() {
        lockedString = nil
        driftBeganAt = nil
    }

    func selectString(
        detectedFrequencyHz: Double,
        tuning: Tuning,
        userSelectedString: TuningString,
        isAutoDetectEnabled: Bool,
        now: Date = .now
    ) -> TuningString {
        guard isAutoDetectEnabled else {
            return userSelectedString
        }

        guard !tuning.strings.isEmpty else {
            return userSelectedString
        }

        guard detectedFrequencyHz > 0 else {
            return lockedString ?? userSelectedString
        }

        let candidate = closestString(to: detectedFrequencyHz, in: tuning)

        guard let locked = lockedString else {
            lockedString = candidate
            driftBeganAt = nil
            return candidate
        }

        if candidate == locked {
            driftBeganAt = nil
            return locked
        }

        let lockedCents = Cents.offset(from: detectedFrequencyHz, targetHz: locked.frequencyHz)
        if abs(lockedCents) <= driftThresholdCents {
            driftBeganAt = nil
            return locked
        }

        if let driftBeganAt = driftBeganAt {
            if now.timeIntervalSince(driftBeganAt) >= driftDuration {
                lockedString = candidate
                self.driftBeganAt = nil
                return candidate
            }
        } else {
            driftBeganAt = now
        }

        return locked
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
