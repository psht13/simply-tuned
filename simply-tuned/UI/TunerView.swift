import SwiftUI

struct TunerView: View {
    @StateObject private var viewModel = TunerViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                header

                controls

                TunerIndicatorView(cents: viewModel.centsOffset)
                    .animation(.easeOut(duration: 0.08), value: viewModel.centsOffset)

                readouts

                Spacer(minLength: 0)
            }
            .padding()
            .navigationBarHidden(true)
            .onAppear { viewModel.startMocking() }
            .onDisappear { viewModel.stopMocking() }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("SimpleTuner")
                .font(.title2.weight(.semibold))

            Spacer()

            Picker("Tuning", selection: $viewModel.selectedTuning) {
                ForEach(Tuning.mvpTunings) { tuning in
                    Text(tuning.displayName).tag(tuning)
                }
            }
            .pickerStyle(.menu)
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Auto-detect string", isOn: $viewModel.isAutoDetectEnabled)

            if !viewModel.isAutoDetectEnabled {
                let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(viewModel.selectedTuning.strings) { string in
                        Button {
                            viewModel.selectString(string)
                        } label: {
                            Text(string.name)
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity, minHeight: 36)
                        }
                        .buttonStyle(.bordered)
                        .tint(viewModel.selectedString == string ? .accentColor : .gray)
                    }
                }
            }
        }
    }

    private var readouts: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Target")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(viewModel.selectedString.name)  •  \(formatHz(viewModel.selectedString.frequencyHz))")
                    .fontDesign(.monospaced)
            }

            HStack {
                Text("Detected")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatHz(viewModel.detectedFrequencyHz))
                    .fontDesign(.monospaced)
            }

            HStack {
                Text("Cents")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatCents(viewModel.centsOffset))
                    .fontDesign(.monospaced)
            }

            HStack {
                Text("Confidence")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.2f", viewModel.confidence))
                    .fontDesign(.monospaced)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }

    private func formatHz(_ value: Double) -> String {
        String(format: "%.2f Hz", value)
    }

    private func formatCents(_ value: Double) -> String {
        let clamped = Cents.clampedForUI(value)
        return String(format: "%+.1f", clamped)
    }
}

#Preview {
    TunerView()
}
