import Foundation
import SwiftUI

struct TunerIndicatorView: View {
    let cents: Double
    let successEvent: Int

    @State private var pulse: Double = 0
    private let labelColor = Color.black.opacity(0.62)
    private let successColor = Color(red: 0.19, green: 0.64, blue: 0.38)
    private let trackLeft = Color(red: 0.36, green: 0.56, blue: 0.85).opacity(0.25)
    private let trackCenter = Color.white.opacity(0.85)
    private let trackRight = Color(red: 0.94, green: 0.66, blue: 0.42).opacity(0.25)

    private var normalized: Double {
        let clamped = Cents.clampedForUI(cents)
        return clamped / 50.0
    }

    private var isInTune: Bool {
        abs(cents) <= 5
    }

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height
                let horizontalPadding: Double = 22
                let markerWidth: Double = 22
                let markerHeight: Double = max(28, height * 0.5)
                let usableWidth = max(0, width - horizontalPadding * 2 - markerWidth)
                let centerX = width / 2
                let markerX = centerX + normalized * (usableWidth / 2)
                let tickCount = 9
                let tickSpacing = (width - horizontalPadding * 2) / Double(tickCount - 1)

                ZStack {
                    Capsule(style: .circular)
                        .fill(
                            LinearGradient(
                                colors: [trackLeft, trackCenter, trackRight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 12)
                        .overlay(
                            Capsule(style: .circular)
                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                        )
                        .position(x: centerX, y: height / 2)

                    ForEach(0..<tickCount, id: \.self) { index in
                        let isCenter = index == tickCount / 2
                        let tickHeight = isCenter ? height * 0.6 : height * 0.35
                        let tickOpacity = isCenter ? 0.45 : 0.2
                        Rectangle()
                            .fill(Color.black.opacity(tickOpacity))
                            .frame(width: 2, height: tickHeight)
                            .position(
                                x: horizontalPadding + Double(index) * tickSpacing,
                                y: height / 2
                            )
                    }

                    Capsule(style: .circular)
                        .fill(successColor.opacity(0.18))
                        .frame(width: 12, height: height * 0.7)
                        .blur(radius: 6)
                        .position(x: centerX, y: height / 2)

                    Capsule(style: .circular)
                        .fill(successColor.opacity(0.2))
                        .frame(width: 14, height: height * 0.75)
                        .blur(radius: 8)
                        .opacity(pulse)
                        .position(x: centerX, y: height / 2)

                    Capsule(style: .circular)
                        .fill(successColor)
                        .frame(width: 6, height: height * 0.75)
                        .opacity(0.9)
                        .position(x: centerX, y: height / 2)

                    Capsule(style: .circular)
                        .fill(markerGradient)
                        .frame(width: markerWidth, height: markerHeight)
                        .overlay(
                            Capsule(style: .circular)
                                .stroke(Color.white.opacity(0.7), lineWidth: 1)
                        )
                        .shadow(color: markerShadow, radius: 6, x: 0, y: 4)
                        .position(x: markerX, y: height / 2)
                        .animation(.spring(response: 0.25, dampingFraction: 0.78), value: cents)
                }
            }
            .frame(height: 86)

            HStack {
                Text("Flat")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Sharp")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.system(.caption2, design: .rounded).weight(.semibold))
            .foregroundStyle(labelColor)
        }
        .onChange(of: successEvent) {
            triggerPulse()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tuning indicator")
        .accessibilityValue("\(Int(Cents.clampedForUI(cents))) cents")
    }

    private var markerGradient: LinearGradient {
        let start = isInTune ? successColor.opacity(0.9) : Color.accentColor.opacity(0.85)
        let end = isInTune ? successColor.opacity(0.6) : Color.accentColor.opacity(0.45)
        return LinearGradient(colors: [start, end], startPoint: .top, endPoint: .bottom)
    }

    private var markerShadow: Color {
        isInTune ? successColor.opacity(0.35) : Color.black.opacity(0.18)
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
    VStack(spacing: 16) {
        TunerIndicatorView(cents: -35, successEvent: 0)
        TunerIndicatorView(cents: -8, successEvent: 0)
        TunerIndicatorView(cents: 0, successEvent: 0)
        TunerIndicatorView(cents: 6, successEvent: 0)
        TunerIndicatorView(cents: 40, successEvent: 0)
    }
    .padding()
}
