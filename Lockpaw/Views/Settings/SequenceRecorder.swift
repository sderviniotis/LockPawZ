import SwiftUI
import Carbon

/// LockPawZ: records one unlock sequence. Click Change, type 4 to 8 keys (no modifiers),
/// Return saves, Delete removes the last key, Esc cancels. The other sequence is checked
/// so neither can start with the other.
struct SequenceRecorder: View {
    let action: SequenceAction

    @State private var current: [Int] = []
    @State private var draft: [Int] = []
    @State private var isRecording = false
    @State private var message: String?
    @State private var monitor: Any?

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 8) {
                Text(isRecording ? (draft.isEmpty ? "Type the keys\u{2026}" : UnlockSequence.display(draft)) : UnlockSequence.display(current))
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(isRecording ? settingsAccentColor : .primary)
                    .frame(minWidth: 140, alignment: .trailing)
                Button(isRecording ? "Cancel" : "Change") {
                    isRecording ? stop() : start()
                }
                if !isRecording, current != defaultCodes {
                    Button("Reset") { save(defaultCodes) }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(isRecording ? "Recording sequence" : "Sequence \(UnlockSequence.display(current))")

            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(isRecording ? Color.secondary : Color("LockpawError"))
            }
        }
        .onAppear { current = UnlockSequence.stored(action) }
        .onDisappear(perform: stop)
    }

    private var defaultCodes: [Int] {
        action == .desktop ? UnlockSequence.defaultDesktop : UnlockSequence.defaultScreensaver
    }

    private func start() {
        draft = []
        message = "\(UnlockSequence.minLength) to \(UnlockSequence.maxLength) keys, then Return. Esc cancels."
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard LockStatus.shared.state == .unlocked else { stop(); return event }
            if event.isARepeat { return nil }
            let code = Int(event.keyCode)
            switch code {
            case kVK_Escape:
                stop()
            case kVK_Return, kVK_ANSI_KeypadEnter:
                commit()
            case kVK_Delete:
                if !draft.isEmpty { draft.removeLast() }
            default:
                // Modifier keys alone never arrive as keyDown; chords are refused so the
                // sequence is always plain keys, which is what the tap matches.
                let mods = event.modifierFlags.intersection([.command, .option, .control])
                guard mods.isEmpty else { message = "Plain keys only, no Command, Option or Control."; return nil }
                guard draft.count < UnlockSequence.maxLength else { message = "That's the maximum. Press Return to save."; return nil }
                draft.append(code)
                message = "\(UnlockSequence.minLength) to \(UnlockSequence.maxLength) keys, then Return. Esc cancels."
            }
            return nil
        }
    }

    private func commit() {
        guard UnlockSequence.isValid(draft) else {
            message = "Needs \(UnlockSequence.minLength) to \(UnlockSequence.maxLength) keys."
            return
        }
        let other = UnlockSequence.stored(action == .desktop ? .screensaver : .desktop)
        let desktop = action == .desktop ? draft : other
        let screensaver = action == .desktop ? other : draft
        if let conflict = UnlockSequence.conflict(desktop: desktop, screensaver: screensaver) {
            message = conflict
            return
        }
        save(draft)
        stop()
    }

    private func save(_ codes: [Int]) {
        UnlockSequence.save(codes, for: action)
        current = codes
        message = nil
    }

    private func stop() {
        isRecording = false
        draft = []
        if message?.hasSuffix("Esc cancels.") == true { message = nil }
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
