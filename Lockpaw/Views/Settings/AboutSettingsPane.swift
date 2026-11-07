import SwiftUI

private let upstreamURL = URL(string: "https://github.com/sorkila/lockpaw")!
private let forkURL = URL(string: "https://github.com/sderviniotis/LockPawZ")!

/// About: version, lineage, and the honest note about what kind of lock this is.
/// LockPawZ has no update channel and no licence: it is built and installed by hand.
struct AboutSettingsPane: View {
    var body: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 52, height: 52)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("LockPawZ").font(.title3.weight(.semibold))
                        Text(versionText).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }

            Section {
                LabeledContent("Fork") {
                    Link("sderviniotis/LockPawZ", destination: forkURL)
                }
                LabeledContent("Based on Lockpaw by Erik Nielsen") {
                    Link("sorkila/lockpaw", destination: upstreamURL)
                }
            } footer: {
                Text("Blocks the keyboard, mouse and trackpad while you're away. It isn't a replacement for your Mac's own lock screen (Control-Command-Q).")
                    .foregroundStyle(.secondary)
            }
        }
        .settingsPane(.about)
    }

    private var versionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        switch (version, build) {
        case let (.some(version), .some(build)): return "Version \(version) (\(build))"
        case let (.some(version), .none): return "Version \(version)"
        case let (.none, .some(build)): return "Build \(build)"
        default: return "Version unknown"
        }
    }
}
