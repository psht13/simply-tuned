import SwiftUI

struct TunerIndicatorView: View {
    let cents: Double

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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tuning indicator")
        .accessibilityValue("\(Int(Cents.clampedForUI(cents))) cents")
    }
}

#Preview {
    VStack(spacing: 12) {
        TunerIndicatorView(cents: -35)
        TunerIndicatorView(cents: -8)
        TunerIndicatorView(cents: 0)
        TunerIndicatorView(cents: 6)
        TunerIndicatorView(cents: 40)
    }
    .padding()
}

