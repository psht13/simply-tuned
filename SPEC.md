# SimplyTuned — MVP Spec (iOS latest only)

## Goal
A simple, free iPhone guitar tuner with a UI inspired by the “center line + left/right deviation” pattern.
Must feel responsive, pleasant, and minimal.

## Platform / Tech
- iOS: latest only
- UI: SwiftUI
- Architecture: MVVM
- Audio input: AVAudioSession + mic
- Pitch detection (MVP): AudioKit PitchTap (SoundpipeAudioKit) :contentReference[oaicite:1]{index=1}
- Dependency management: Swift Package Manager (SPM)

## Core Screens
### Tuner Screen (single main screen)
**Header**
- App name: “SimpleTuner”
- Tuning selector (dropdown / sheet)
- Optional: settings icon (not required MVP)

**Controls**
- Toggle: “Auto-detect string” (default ON)
- If Auto OFF: show 6 string buttons (E, A, D, G, B, E) to choose active string
- If Auto ON: app selects string automatically from pitch

**Main Tuner Indicator**
- A center green vertical line
- A moving marker indicating pitch offset:
  - left = flat (lower)
  - right = sharp (higher)
- Marker position based on cents offset, clamped to [-50, +50]

**Readouts**
- Current target string name (e.g. E2) + target frequency
- Detected frequency (Hz)
- Current cents offset
- Optional: confidence indicator (0..1)

## Tunings (MVP includes at least)
- Standard: E2 A2 D3 G3 B3 E4
- Drop D: D2 A2 D3 G3 B3 E4
- Half-step down: Eb2 Ab2 Db3 Gb3 Bb3 Eb4
(Additional tunings can be added later via a simple data model.)

## Logic Requirements
### Pitch -> Cents
- cents = 1200 * log2(freq / targetFreq)
- clamp to [-50, +50] for UI display
- smoothing: EMA or rolling median over recent cents

### Auto string selection
- Choose closest target frequency to detected frequency
- Add “lock”:
  - once chosen, keep it unless pitch drifts far (e.g. > 120 cents away) for > 500ms

### In-tune detection (prevents spam)
- Consider “in tune” when abs(cents) <= 5
- Must be stable continuously for >= 300ms before triggering success
- Trigger success only on edge (false -> true)

## Feedback
On success (edge trigger):
- Play short bundled success .wav
- Trigger haptic success
- Visual: subtle pulse/glow on center line (one-shot)

## Permissions
- Must request microphone permission
- Info.plist must include:
  - NSMicrophoneUsageDescription: “Microphone is used to detect guitar pitch for tuning.”

## Non-goals (for MVP)
- No accounts/login
- No cloud or analytics
- No recording/saving audio
- No Android

## Project Structure
- /Domain (Tunings, Strings, target frequencies)
- /Audio (Audio session, engine, pitch tap wrapper)
- /TunerLogic (auto selection, cents calc, stability gate)
- /UI (SwiftUI views, ViewModels)

## Definition of Done (MVP)
- Runs on a real iPhone
- Displays stable cents movement while plucking strings
- Auto/manual modes work
- Success feedback triggers correctly and not repeatedly
- Clean build, no TODO placeholders in core flow
