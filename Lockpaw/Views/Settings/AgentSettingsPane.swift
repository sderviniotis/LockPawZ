import SwiftUI

/// Agents: connect them first (with which ones already are), then how a ping looks and
/// sounds. LockPawZ: the phone/webhook relay was removed; nothing leaves the Mac.
struct AgentSettingsPane: View {
    @AppStorage(GlowIntensity.storageKey) private var glowIntensity = GlowIntensity.defaultValue.rawValue
    @AppStorage(Constants.agentPingSoundKey) private var pingSound = false
    @AppStorage(Constants.lockScreenShowsProjectsKey) private var showsProjects = false

    @State private var connected: Set<String> = []
    @State private var results: [String: SetupResult] = [:]

    var body: some View {
        Form {
            Section {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                    ForEach(AgentConnection.agents, id: \.self) { agent in
                        AgentButton(
                            name: AgentConnection.displayName(agent),
                            state: buttonState(agent)
                        ) {
                            run(["install-hook", agent], mark: agent)
                        }
                    }
                }
                .padding(.vertical, 4)

                if let failure = failureMessage {
                    Text(failure)
                        .font(.callout)
                        .foregroundStyle(Color("LockpawAmber"))
                        .textSelection(.enabled)
                }
            } header: {
                Text("Connect an agent")
            } footer: {
                Text("One click adds Lockpaw's ping to the agent's settings and keeps a backup. Codex asks you to trust new hooks once: run /hooks in Codex.")
                    .foregroundStyle(.secondary)
            }

            Section("When an agent pings") {
                Picker("Glow", selection: $glowIntensity) {
                    ForEach(GlowIntensity.allCases, id: \.rawValue) { Text($0.displayName).tag($0.rawValue) }
                }
                .pickerStyle(.segmented)

                Toggle(isOn: $pingSound) {
                    SettingLabel("Play a sound", detail: "Off by default, for shared spaces.")
                }

                Toggle(isOn: $showsProjects) {
                    SettingLabel("Show project names on the lock screen", detail: "\u{201C}Claude Code \u{00B7} web-app\u{201D} instead of \u{201C}Claude Code\u{201D}.")
                }

                LabeledContent("Try it") {
                    Button("Send a Test Ping") {
                        AgentNotifier.shared.notify(body: "Claude Code finished in lockpaw.", withSound: pingSound)
                    }
                }
            }

            Section {
                LabeledContent {
                    Button {
                        run(["install-cli"], mark: "cli", treatWarningAsFailure: false)
                    } label: {
                        switch results["cli"] {
                        case .running: ProgressView().controlSize(.small)
                        case .success: Text("Installed")
                        default: Text("Install")
                        }
                    }
                    .disabled(results["cli"] == .running || results["cli"] == .success)
                } label: {
                    SettingLabel("Command-line tool", detail: "Optional. Puts lockpaw in ~/.local/bin for your own scripts. Connecting an agent installs it too.")
                }
            }
        }
        .settingsPane(.agents)
        .onAppear(perform: refreshConnections)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshConnections()
        }
    }

    // MARK: - Setup (runs the bundled CLI, which backs up configs)

    enum SetupResult: Equatable {
        case running
        case success
        case failure(String)
    }

    private func buttonState(_ agent: String) -> AgentButton.State {
        switch results[agent] {
        case .running: return .running
        case .failure: return .failed
        case .success: return .connected
        case nil: return connected.contains(agent) ? .connected : .idle
        }
    }

    private var failureMessage: String? {
        for mark in AgentConnection.agents + ["cli"] {
            if case .failure(let message) = results[mark], !message.isEmpty { return message }
        }
        return nil
    }

    private func refreshConnections() {
        Task {
            connected = await Task.detached(priority: .utility) {
                Set(AgentConnection.agents.filter { AgentConnection.isConnected($0) })
            }.value
        }
    }

    /// Runs the bundled `lockpaw` CLI off the main thread. A ⚠️ on stdout with exit 0 (a
    /// foreign Codex `notify` it won't overwrite) counts as a failure, so the button never
    /// claims a write that didn't happen.
    private func run(_ arguments: [String], mark: String, treatWarningAsFailure: Bool = true) {
        if results[mark] == .running { return }
        guard let cli = Bundle.main.sharedSupportURL?.appendingPathComponent("lockpaw"),
              FileManager.default.isExecutableFile(atPath: cli.path) else {
            results[mark] = .failure("The bundled lockpaw tool is missing. Reinstall Lockpaw.")
            return
        }
        results[mark] = .running
        let startedAt = Date()
        Task.detached {
            let process = Process()
            process.executableURL = cli
            process.arguments = arguments
            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            let result: SetupResult
            do {
                try process.run()
                process.waitUntilExit()
                let out = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                let err = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                if process.terminationStatus != 0 {
                    result = .failure(err.trimmingCharacters(in: .whitespacesAndNewlines))
                } else if treatWarningAsFailure, out.contains("⚠️") {
                    result = .failure(out.trimmingCharacters(in: .whitespacesAndNewlines))
                } else {
                    result = .success
                }
            } catch {
                result = .failure(error.localizedDescription)
            }
            // The CLI finishes in milliseconds; hold the spinner briefly so success reads
            // as an event rather than a flicker.
            let elapsed = Date().timeIntervalSince(startedAt)
            if elapsed < Constants.Timing.agentSetupMinSpin {
                try? await Task.sleep(nanoseconds: UInt64((Constants.Timing.agentSetupMinSpin - elapsed) * 1_000_000_000))
            }
            await MainActor.run {
                results[mark] = result
                // install-hook installs the CLI as a side effect; mirror that.
                if mark != "cli", result == .success { results["cli"] = .success }
            }
        }
    }
}

/// One agent: its name, and a check once Lockpaw's hook is in its settings. Clicking a
/// connected agent runs the installer again, which upgrades the hook in place.
private struct AgentButton: View {
    enum State { case idle, running, connected, failed }

    let name: String
    let state: State
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(name).lineLimit(1)
                Spacer(minLength: 0)
                switch state {
                case .idle:
                    Image(systemName: "plus.circle").foregroundStyle(.secondary)
                case .running:
                    ProgressView().controlSize(.small)
                case .connected:
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(settingsAccentColor)
                case .failed:
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(Color("LockpawAmber"))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 4)
        }
        .controlSize(.large)
        .disabled(state == .running)
        .accessibilityLabel(name)
        .accessibilityValue(accessibilityValue)
        .help(state == .connected ? "Connected. Click to update the hook." : "Connect \(name)")
    }

    private var accessibilityValue: String {
        switch state {
        case .idle: return "Not connected"
        case .running: return "Connecting"
        case .connected: return "Connected"
        case .failed: return "Couldn't connect"
        }
    }
}
