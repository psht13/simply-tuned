import Foundation

enum Cents {
    static func offset(from frequencyHz: Double, targetHz: Double) -> Double {
        guard frequencyHz > 0, targetHz > 0 else { return 0 }
        return 1200.0 * log2(frequencyHz / targetHz)
    }

    static func clampedForUI(_ cents: Double) -> Double {
        min(50, max(-50, cents))
    }
}

struct ExponentialMovingAverage {
    let alpha: Double
    private(set) var value: Double?

    init(alpha: Double) {
        self.alpha = alpha
    }

    mutating func update(with newValue: Double) -> Double {
        if let existingValue = value {
            let updatedValue = alpha * newValue + (1 - alpha) * existingValue
            value = updatedValue
            return updatedValue
        }

        value = newValue
        return newValue
    }

    mutating func reset() {
        value = nil
    }
}
