import Foundation

struct InTuneUpdate {
    let isInTune: Bool
    let didTrigger: Bool
}

final class InTuneGate {
    private let thresholdCents: Double
    private let requiredDuration: TimeInterval

    private var inRangeBeganAt: Date?
    private(set) var isInTune: Bool = false

    init(thresholdCents: Double = 5, requiredDuration: TimeInterval = 0.3) {
        self.thresholdCents = thresholdCents
        self.requiredDuration = requiredDuration
    }

    func reset() {
        inRangeBeganAt = nil
        isInTune = false
    }

    func update(cents: Double, now: Date = .now) -> InTuneUpdate {
        let isWithinRange = abs(cents) <= thresholdCents

        guard isWithinRange else {
            inRangeBeganAt = nil
            isInTune = false
            return InTuneUpdate(isInTune: false, didTrigger: false)
        }

        if isInTune {
            return InTuneUpdate(isInTune: true, didTrigger: false)
        }

        if inRangeBeganAt == nil {
            inRangeBeganAt = now
        }

        guard let inRangeBeganAt else {
            return InTuneUpdate(isInTune: false, didTrigger: false)
        }

        if now.timeIntervalSince(inRangeBeganAt) >= requiredDuration {
            isInTune = true
            return InTuneUpdate(isInTune: true, didTrigger: true)
        }

        return InTuneUpdate(isInTune: false, didTrigger: false)
    }
}
