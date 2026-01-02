import Foundation
import SwiftUI
import UIKit

private enum TypeScale {
    static let title = Font.system(size: 30, weight: .semibold, design: .rounded)
    static let subtitle = Font.system(size: 15, weight: .medium, design: .rounded)
    static let sectionTitle = Font.system(size: 14, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 15, weight: .regular, design: .rounded)
    static let secondary = Font.system(size: 12, weight: .medium, design: .rounded)
}

private enum Palette {
    static let accent = Color(red: 0.12, green: 0.49, blue: 0.64)
    static let success = Color(red: 0.19, green: 0.64, blue: 0.38)
    static let textPrimary = Color(red: 0.12, green: 0.16, blue: 0.22)
    static let textSecondary = Color(red: 0.36, green: 0.42, blue: 0.49)
    static let textTertiary = Color(red: 0.52, green: 0.58, blue: 0.64)
    static let cardBackground = Color.white.opacity(0.96)
    static let cardBorder = Color.black.opacity(0.06)
    static let cardShadow = Color.black.opacity(0.08)
    static let backgroundTop = Color(red: 0.99, green: 0.97, blue: 0.95)
    static let backgroundBottom = Color(red: 0.9, green: 0.94, blue: 0.98)
    static let backgroundGlowWarm = Color(red: 0.97, green: 0.86, blue: 0.78).opacity(0.45)
    static let backgroundGlowCool = Color(red: 0.78, green: 0.9, blue: 0.97).opacity(0.45)
    static let pillBackground = Color.white.opacity(0.9)
    static let pillBorder = Color.black.opacity(0.08)
}

struct TunerView: View {
    @StateObject private var viewModel = TunerViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @State private var feedbackPlayer = SuccessFeedbackPlayer()
    @State private var isTuningPickerPresented = false
    @State private var showSuccessMessage = false
    @State private var hasAppeared = false
    @State private var successDismissWorkItem: DispatchWorkItem?
    @State private var successMessageText = "Nice!"
    @State private var isDebugVisible = false

    var body: some View {
        NavigationStack {
            ZStack {
                background

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        header
                            .opacity(hasAppeared ? 1 : 0)
                            .offset(y: hasAppeared ? 0 : 8)
                            .animation(.easeOut(duration: 0.45), value: hasAppeared)

                        if viewModel.microphonePermissionState == .granted {
                            tunerContent
                        } else {
                            permissionContent
                        }

                        #if DEBUG
                        if isDebugVisible {
                            DebugReadoutView(
                                target: viewModel.selectedString,
                                detectedFrequencyHz: viewModel.detectedFrequencyHz,
                                centsOffset: viewModel.centsOffset,
                                confidence: viewModel.confidence
                            )
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        #endif
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarHidden(true)
            .tint(Palette.accent)
            .onAppear {
                viewModel.startListening()
                withAnimation(.easeOut(duration: 0.45)) {
                    hasAppeared = true
                }
            }
            .onDisappear {
                viewModel.stopListening()
            }
            .onChange(of: viewModel.successEvent) { _, newValue in
                guard newValue > 0 else { return }
                feedbackPlayer.trigger()
                showSuccessPulse()
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    viewModel.startListening()
                }
            }
        }
    }

    private var header: some View {
        let base = HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Simply Tuned")
                    .font(TypeScale.title)
                    .foregroundStyle(Palette.textPrimary)

                Text("Tune your guitar with confidence")
                    .font(TypeScale.subtitle)
                    .foregroundStyle(Palette.textSecondary)
            }

            Spacer()

            tuningButton
        }
        .sheet(isPresented: $isTuningPickerPresented) {
            TuningPickerSheet(selectedTuning: $viewModel.selectedTuning, tunings: Tuning.allTunings)
        }

        #if DEBUG
        return base.onLongPressGesture(minimumDuration: 0.6) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isDebugVisible.toggle()
            }
        }
        #else
        return base
        #endif
    }

    private var tuningButton: some View {
        TuningSelectorPill(value: viewModel.selectedTuning.displayName) {
            isTuningPickerPresented = true
        }
    }

    private var tunerContent: some View {
        VStack(spacing: 16) {
            controlsCard
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 8)
                .animation(.easeOut(duration: 0.45).delay(0.05), value: hasAppeared)

            indicatorCard
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared ? 0 : 8)
                .animation(.easeOut(duration: 0.45).delay(0.1), value: hasAppeared)
        }
    }

    private var permissionContent: some View {
        Group {
            switch viewModel.microphonePermissionState {
            case .undetermined:
                PermissionPlaceholderView(
                    iconName: "mic.fill",
                    title: "Enable Microphone",
                    message: "Simply Tuned listens to your guitar to detect pitch. Audio stays on your device.",
                    actionTitle: "Enable Microphone",
                    action: { viewModel.requestMicrophonePermission() }
                )
            case .denied:
                PermissionPlaceholderView(
                    iconName: "mic.slash.fill",
                    title: "Microphone Access Off",
                    message: "Enable microphone access in Settings to start tuning.",
                    actionTitle: "Open Settings",
                    action: openSettings
                )
            case .granted:
                EmptyView()
            }
        }
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 8)
        .animation(.easeOut(duration: 0.45).delay(0.05), value: hasAppeared)
    }

    private var controlsCard: some View {
        TunerCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center) {
                    Text("Auto-detect")
                        .font(TypeScale.sectionTitle)
                        .foregroundStyle(Palette.textPrimary)

                    Spacer()

                    Toggle("", isOn: $viewModel.isAutoDetectEnabled)
                        .labelsHidden()
                        .accessibilityLabel("Auto-detect")
                        .toggleStyle(SwitchToggleStyle(tint: Palette.accent))
                }

                Text(viewModel.isAutoDetectEnabled ? "Listening for the closest string..." : "Select a string to tune.")
                    .font(TypeScale.secondary)
                    .foregroundStyle(Palette.textTertiary)

                let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(viewModel.selectedTuning.strings) { string in
                        StringButton(
                            title: string.name,
                            state: stringButtonState(for: string),
                            isInteractive: !viewModel.isAutoDetectEnabled
                        ) {
                            viewModel.selectString(string)
                        }
                    }
                }
            }
        }
    }

    private var indicatorCard: some View {
        TunerCard {
            VStack(spacing: 16) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Target")
                            .font(TypeScale.sectionTitle)
                            .foregroundStyle(Palette.textSecondary)
                        Text(viewModel.selectedString.name)
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundStyle(Palette.textPrimary)
                    }

                    Spacer()

                    Text(viewModel.selectedTuning.displayName)
                        .font(TypeScale.secondary)
                        .foregroundStyle(Palette.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Palette.pillBackground)
                                .overlay(
                                    Capsule(style: .continuous)
                                        .stroke(Palette.pillBorder, lineWidth: 1)
                                )
                        )
                }

                ZStack(alignment: .bottom) {
                    TunerIndicatorView(cents: viewModel.centsOffset, successEvent: viewModel.successEvent)

                    if showSuccessMessage {
                        Text(successMessageText)
                            .font(.system(.callout, design: .rounded).weight(.semibold))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Palette.success.opacity(0.18))
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(Palette.success.opacity(0.45), lineWidth: 1)
                            )
                            .foregroundStyle(Palette.success)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                            .padding(.bottom, 8)
                    }
                }
            }
        }
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Palette.backgroundTop,
                    Palette.backgroundBottom,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(Palette.backgroundGlowWarm)
                .blur(radius: 80)
                .offset(x: -160, y: -220)

            Circle()
                .fill(Palette.backgroundGlowCool)
                .blur(radius: 90)
                .offset(x: 170, y: 200)
        }
        .ignoresSafeArea()
    }

    private func stringButtonState(for string: TuningString) -> StringButton.State {
        if viewModel.tunedStringIDs.contains(string.id) {
            return .success
        }
        if viewModel.selectedString == string {
            return .active
        }
        if viewModel.isAutoDetectEnabled {
            return .disabled
        }
        return .idle
    }

    private func showSuccessPulse() {
        successDismissWorkItem?.cancel()
        withAnimation(.easeOut(duration: 0.18)) {
            showSuccessMessage = true
        }

        let workItem = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.35)) {
                showSuccessMessage = false
            }
        }
        successDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: workItem)
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

struct TuningSelectorPill: View {
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(value)
                    .font(TypeScale.sectionTitle)
                    .foregroundStyle(Palette.textPrimary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.textSecondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(
                Capsule(style: .continuous)
                    .fill(Palette.pillBackground)
            )
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Palette.pillBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Tuning")
        .accessibilityValue(value)
    }
}

struct TunerCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content.cardStyle()
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Palette.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Palette.cardBorder, lineWidth: 1)
                    )
                    .shadow(color: Palette.cardShadow, radius: 10, x: 0, y: 6)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

struct StringButton: View {
    enum State: Equatable {
        case idle
        case active
        case success
        case disabled
    }

    let title: String
    let state: State
    let isInteractive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)

                if state == .success {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                }
            }
            .font(TypeScale.sectionTitle)
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity, minHeight: 40)
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(borderColor, lineWidth: state == .active ? 2 : 1)
        )
        .shadow(color: shadowColor, radius: state == .active ? 10 : 4, x: 0, y: state == .active ? 6 : 2)
        .opacity(interactionOpacity)
        .saturation(interactionSaturation)
        .disabled(!isInteractive)
        .animation(.easeOut(duration: 0.18), value: state)
    }

    private var interactionOpacity: Double {
        guard !isInteractive else { return 1 }
        return (state == .active || state == .success) ? 0.85 : 0.65
    }

    private var interactionSaturation: Double {
        guard !isInteractive else { return 1 }
        return (state == .active || state == .success) ? 0.9 : 0.8
    }

    private var backgroundColor: Color {
        switch state {
        case .idle:
            return Color.white.opacity(0.94)
        case .active:
            return Color.white
        case .success:
            return Palette.accent
        case .disabled:
            return Color.white.opacity(0.9)
        }
    }

    private var borderColor: Color {
        switch state {
        case .idle:
            return Palette.cardBorder
        case .active:
            return Palette.accent
        case .success:
            return Palette.accent
        case .disabled:
            return Palette.cardBorder
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .idle:
            return Palette.textPrimary
        case .active:
            return Palette.accent
        case .success:
            return Color.white
        case .disabled:
            return Palette.textTertiary
        }
    }

    private var shadowColor: Color {
        switch state {
        case .idle:
            return Color.black.opacity(0.06)
        case .active:
            return Palette.accent.opacity(0.25)
        case .success:
            return Palette.accent.opacity(0.25)
        case .disabled:
            return Color.black.opacity(0.04)
        }
    }
}

struct TuningPickerSheet: View {
    @Binding var selectedTuning: Tuning
    let tunings: [Tuning]

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                if searchText.isEmpty {
                    ForEach(tuningGroups) { group in
                        Section(group.title) {
                            ForEach(group.tunings) { tuning in
                                tuningRow(for: tuning)
                            }
                        }
                    }
                } else {
                    ForEach(filteredTunings) { tuning in
                        tuningRow(for: tuning)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Choose a tuning")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search tunings")
        }
    }

    private var filteredTunings: [Tuning] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return tunings }
        return tunings.filter { tuning in
            tuning.displayName.localizedCaseInsensitiveContains(trimmed) ||
            tuning.strings.map(\.name).joined(separator: " ").localizedCaseInsensitiveContains(trimmed)
        }
    }

    private var tuningGroups: [TuningGroup] {
        let standardGroup = [
            Tuning.standard,
            Tuning.dropD,
            Tuning.halfStepDown,
            Tuning.fullStepDown,
            Tuning.dropC,
        ].filter { tunings.contains($0) }

        let openGroup = [
            Tuning.openG,
            Tuning.openD,
            Tuning.dadgad,
        ].filter { tunings.contains($0) }

        return [
            TuningGroup(title: "Standard & Down", tunings: standardGroup),
            TuningGroup(title: "Open Tunings", tunings: openGroup),
        ].filter { !$0.tunings.isEmpty }
    }

    @ViewBuilder
    private func tuningRow(for tuning: Tuning) -> some View {
        Button {
            selectedTuning = tuning
            dismiss()
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tuning.displayName)
                        .font(TypeScale.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(tuning.strings.map(\.name).joined(separator: " "))
                        .font(TypeScale.secondary)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if tuning == selectedTuning {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Palette.accent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private struct TuningGroup: Identifiable {
        let id: String
        let title: String
        let tunings: [Tuning]

        init(title: String, tunings: [Tuning]) {
            self.title = title
            self.tunings = tunings
            self.id = title
        }
    }
}

struct PermissionPlaceholderView: View {
    let iconName: String
    let title: String
    let message: String
    let actionTitle: String
    let action: () -> Void
    var secondaryActionTitle: String? = nil
    var secondaryAction: (() -> Void)? = nil

    var body: some View {
        TunerCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Palette.accent.opacity(0.18))
                            .frame(width: 44, height: 44)
                        Image(systemName: iconName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(Palette.accent)
                    }

                    Text(title)
                        .font(TypeScale.sectionTitle)
                        .foregroundStyle(Palette.textPrimary)
                }

                Text(message)
                    .font(TypeScale.body)
                    .foregroundStyle(Palette.textSecondary)

                HStack(spacing: 16) {
                    Button(actionTitle, action: action)
                        .buttonStyle(.borderedProminent)
                        .tint(Palette.accent)

                    if let secondaryActionTitle, let secondaryAction {
                        Button(secondaryActionTitle, action: secondaryAction)
                            .buttonStyle(.bordered)
                    }
                }
                .controlSize(.large)
            }
        }
    }
}

#if DEBUG
private struct DebugReadoutView: View {
    let target: TuningString
    let detectedFrequencyHz: Double
    let centsOffset: Double
    let confidence: Double

    var body: some View {
        TunerCard {
            VStack(spacing: 10) {
                debugRow(label: "Target", value: "\(target.name)  •  \(formatHz(target.frequencyHz))")
                debugRow(label: "Detected", value: formatHz(detectedFrequencyHz))
                debugRow(label: "Cents", value: formatCents(centsOffset))
                debugRow(label: "Confidence", value: String(format: "%.2f", confidence))
            }
        }
    }

    private func debugRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontDesign(.monospaced)
        }
    }

    private func formatHz(_ value: Double) -> String {
        String(format: "%.2f Hz", value)
    }

    private func formatCents(_ value: Double) -> String {
        let clamped = Cents.clampedForUI(value)
        return String(format: "%+.1f", clamped)
    }
}
#endif

#Preview {
    TunerView()
}
