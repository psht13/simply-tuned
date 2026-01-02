import Foundation
import SwiftUI

struct TunerIndicatorView: View {
    let cents: Double
    let successEvent: Int

    @State private var pulse: Double = 0

    private var normalized: Double {
        let clamped = Cents.clampedForUI(cents)
        return clamped / 50.0
    }

    private var markerColor: Color {
        abs(cents) <= 5 ? .green : .accentColor
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height

            let horizontalPadding: Double = 16
            let markerDiameter: Double = 16
            let usableWidth = max(0, width - horizontalPadding * 2 - markerDiameter)
            let centerX = width / 2
            let markerX = centerX + normalized * (usableWidth / 2)

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.thinMaterial)

                Capsule(style: .circular)
                    .fill(Color.green)
                    .frame(width: 10, height: height * 0.85)
                    .opacity(0.35 * pulse)
                    .blur(radius: 6 + 4 * pulse)
                    .scaleEffect(y: 1.0 + 0.2 * pulse, anchor: .center)
                    .position(x: centerX, y: height / 2)

                Capsule(style: .circular)
                    .fill(Color.green)
                    .frame(width: 4, height: height * 0.75)
                    .position(x: centerX, y: height / 2)

                Circle()
                    .fill(markerColor)
                    .frame(width: markerDiameter, height: markerDiameter)
                    .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                    .position(x: markerX, y: height / 2)
            }
        }
        .frame(height: 92)
        .onChange(of: successEvent) { _ in
            triggerPulse()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tuning indicator")
        .accessibilityValue("\(Int(Cents.clampedForUI(cents))) cents")
    }

    private func triggerPulse() {
        pulse = 0
        withAnimation(.easeOut(duration: 0.12)) {
            pulse = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.easeOut(duration: 0.35)) {
                pulse = 0
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        TunerIndicatorView(cents: -35, successEvent: 0)
        TunerIndicatorView(cents: -8, successEvent: 0)
        TunerIndicatorView(cents: 0, successEvent: 0)
        TunerIndicatorView(cents: 6, successEvent: 0)
        TunerIndicatorView(cents: 40, successEvent: 0)
    }
    .padding()
}
