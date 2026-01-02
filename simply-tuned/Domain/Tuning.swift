import Foundation

struct Tuning: Identifiable, Hashable {
    let id: String
    let displayName: String
    let strings: [TuningString]

    init(displayName: String, strings: [TuningString]) {
        self.displayName = displayName
        self.strings = strings
        self.id = displayName
    }
}

struct TuningString: Identifiable, Hashable {
    let id: String
    let name: String
    let frequencyHz: Double

    init(name: String, frequencyHz: Double) {
        self.name = name
        self.frequencyHz = frequencyHz
        self.id = name
    }
}

extension Tuning {
    static let standard = Tuning(
        displayName: "Standard",
        strings: [
            TuningString(name: "E2", frequencyHz: 82.41),
            TuningString(name: "A2", frequencyHz: 110.00),
            TuningString(name: "D3", frequencyHz: 146.83),
            TuningString(name: "G3", frequencyHz: 196.00),
            TuningString(name: "B3", frequencyHz: 246.94),
            TuningString(name: "E4", frequencyHz: 329.63),
        ]
    )

    static let dropD = Tuning(
        displayName: "Drop D",
        strings: [
            TuningString(name: "D2", frequencyHz: 73.42),
            TuningString(name: "A2", frequencyHz: 110.00),
            TuningString(name: "D3", frequencyHz: 146.83),
            TuningString(name: "G3", frequencyHz: 196.00),
            TuningString(name: "B3", frequencyHz: 246.94),
            TuningString(name: "E4", frequencyHz: 329.63),
        ]
    )

    static let halfStepDown = Tuning(
        displayName: "Half-step down",
        strings: [
            TuningString(name: "Eb2", frequencyHz: 77.78),
            TuningString(name: "Ab2", frequencyHz: 103.83),
            TuningString(name: "Db3", frequencyHz: 138.59),
            TuningString(name: "Gb3", frequencyHz: 185.00),
            TuningString(name: "Bb3", frequencyHz: 233.08),
            TuningString(name: "Eb4", frequencyHz: 311.13),
        ]
    )

    static let fullStepDown = Tuning(
        displayName: "Full-step down",
        strings: [
            TuningString(name: "D2", frequencyHz: 73.42),
            TuningString(name: "G2", frequencyHz: 98.00),
            TuningString(name: "C3", frequencyHz: 130.81),
            TuningString(name: "F3", frequencyHz: 174.61),
            TuningString(name: "A3", frequencyHz: 220.00),
            TuningString(name: "D4", frequencyHz: 293.66),
        ]
    )

    static let openG = Tuning(
        displayName: "Open G",
        strings: [
            TuningString(name: "D2", frequencyHz: 73.42),
            TuningString(name: "G2", frequencyHz: 98.00),
            TuningString(name: "D3", frequencyHz: 146.83),
            TuningString(name: "G3", frequencyHz: 196.00),
            TuningString(name: "B3", frequencyHz: 246.94),
            TuningString(name: "D4", frequencyHz: 293.66),
        ]
    )

    static let openD = Tuning(
        displayName: "Open D",
        strings: [
            TuningString(name: "D2", frequencyHz: 73.42),
            TuningString(name: "A2", frequencyHz: 110.00),
            TuningString(name: "D3", frequencyHz: 146.83),
            TuningString(name: "F#3", frequencyHz: 185.00),
            TuningString(name: "A3", frequencyHz: 220.00),
            TuningString(name: "D4", frequencyHz: 293.66),
        ]
    )

    static let dadgad = Tuning(
        displayName: "DADGAD",
        strings: [
            TuningString(name: "D2", frequencyHz: 73.42),
            TuningString(name: "A2", frequencyHz: 110.00),
            TuningString(name: "D3", frequencyHz: 146.83),
            TuningString(name: "G3", frequencyHz: 196.00),
            TuningString(name: "A3", frequencyHz: 220.00),
            TuningString(name: "D4", frequencyHz: 293.66),
        ]
    )

    static let dropC = Tuning(
        displayName: "Drop C",
        strings: [
            TuningString(name: "C2", frequencyHz: 65.41),
            TuningString(name: "G2", frequencyHz: 98.00),
            TuningString(name: "C3", frequencyHz: 130.81),
            TuningString(name: "F3", frequencyHz: 174.61),
            TuningString(name: "A3", frequencyHz: 220.00),
            TuningString(name: "D4", frequencyHz: 293.66),
        ]
    )

    static let allTunings: [Tuning] = [
        .standard,
        .dropD,
        .halfStepDown,
        .fullStepDown,
        .dropC,
        .openG,
        .openD,
        .dadgad,
    ]
}
