import SwiftUI

struct MenuBarView: View {
    @ObservedObject var controller: LockController

    var body: some View {
        Group {
            if controller.state == .unlocked {
                Button {
                    controller.lock()
                } label: {
                    Label("Lock Screen", systemImage: "lock.fill")
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
            } else {
                if !LockMode.isTransparent {
                    Button {
                        controller.requestUnlock()
                    } label: {
                        Label("Unlock with Password", systemImage: "keyboard")
                    }

                    Divider()
                }

                Label {
                    Text("Locked for \(Constants.formatElapsedTime(controller.elapsedTime))")
                        .foregroundStyle(.primary.opacity(0.7))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                } icon: {
                    Image(systemName: "clock")
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Button("Settings\u{2026}") {
                NotificationCenter.default.post(name: .lockpawOpenSettings, object: nil)
            }
            .keyboardShortcut(",")

            Button("Quit LockPawZ") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
