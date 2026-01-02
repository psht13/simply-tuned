import Foundation
import SwiftUI
internal import Combine

@MainActor
final class TunerViewModel: ObservableObject {
    @Published var selectedTuning: Tuning = .standard
    @Published var isAutoDetectEnabled: Bool = true

    @Published var selectedString: TuningString? = Tuning.standard.strings.first
    @Published var detectedFrequencyHz: Double = 0
    @Published var centsOffset: Double = 0

    func setDetectedFrequency(_ frequencyHz: Double) {
        detectedFrequencyHz = frequencyHz
        updateCents()
    }

    private func updateCents() {
        guard
            detectedFrequencyHz > 0,
            let targetHz = selectedString?.frequencyHz,
            targetHz > 0
        else {
            centsOffset = 0
            return
        }

        let cents = Cents.offset(from: detectedFrequencyHz, targetHz: targetHz)
        centsOffset = Cents.clampedForUI(cents)
    }
}
