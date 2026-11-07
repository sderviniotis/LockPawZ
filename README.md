# LockPawZ

A personal macOS menu bar app that locks the keyboard, mouse and trackpad while leaving every
screen exactly as it was, so work in progress can be watched from across the room but not
touched. Unlocked only by the person at the keyboard: Touch ID, or a secret key sequence.

LockPawZ is a fork of [Lockpaw](https://github.com/sorkila/lockpaw) by Erik Nielsen (MIT).
Lockpaw covers the screen with a lock screen and a mascot; LockPawZ shows no cover at all.
Everything else about how the lock works, the event tap, the armed Touch ID, the state
machine, is Erik's work and this fork would not exist without it.

## What it does

- **Lock** with ⌘⇧L or the menu bar paw. Nothing on screen changes.
- **Blocked while locked:** every key, click, drag, scroll and trackpad gesture, system-wide,
  including Cmd+Tab, Cmd+Q, Spotlight, Mission Control and Space switching. The pointer
  still moves (freezing it needs root), which is a handy sign the Mac is alive.
- **Unlock** by resting a finger on Touch ID, or by typing a sequence of 4 to 8 keys:
  - sequence A unlocks to the desktop
  - sequence B unlocks and starts the macOS screen saver, which hands the Mac to its own
    lock screen when "require password" is on
- Sequences are set in Settings and never shown on screen. Only physical keystrokes count:
  a script or an AI agent posting keys through the Accessibility API cannot type them.
- **The hotkey never unlocks.** Nor does any URL scheme, Shortcut, CLI command or notification.
  There is no path by which software running on the Mac can unlock it.
- Starts unlocked after every launch, login or reboot.
- No network access. No auto-update. No helper processes. No third-party code.

Lockpaw's original covered lock screen is still there as the off position of
Settings → General → "Keep the screens visible".

## Not a security boundary

Same caveat as upstream: this is a hands-off tool, not confidentiality. Anyone with physical
access can hold the power button, pull a cable or kill the process from another session. For
real security use the Mac's own lock screen (Ctrl+Cmd+Q), which sequence B gets you to.

## Changes from upstream Lockpaw 1.7.1

Removed, after a code review of the whole project (see `CHANGELOG.md`):

| Removed | Why |
|---|---|
| `lockpaw://toggle`, `unlock`, `unlock-password` URL handlers | `toggle` unlocked without authentication from any local process |
| Sparkle auto-update | Would have replaced the fork with stock Lockpaw |
| `LockpawHelper` root daemon and lid-closed mode | Root code with no use here; cannot run on a free Apple ID build anyway |
| Supporter licence, support card, yearly ask | Upstream's tip jar. All mascots are simply available |
| Webhook relay (ntfy, Pushover, webhook) and Keychain helper | The only other network path |
| Debug-build Cmd+Shift+Q kill switch | Trap for a daily-use build |
| Release workflow, Homebrew cask, funding links | Not distributing |

Added:

- Transparent lock mode with pointer blocking at the event tap (`LockMode`, `LockdownPolicy.pointerEventMask`)
- Unlock sequences and matcher (`UnlockSequence`, `SequenceMatcher`), screen saver exit, Settings recorder
- `scripts/build-lockpawz.sh`: universal Release build, zip, install

The agent-ping hooks (Claude Code, Codex, Gemini, Cursor, Copilot, Aider) and the `lockpaw`
CLI are still in the code but do nothing unless connected, and there is nothing to gain from
connecting them in transparent mode.

## Build

Requires macOS 14+, Xcode 16+ (built with 27.2), [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```
xcodegen generate && open Lockpaw.xcodeproj      # develop
./scripts/build-lockpawz.sh --install            # Release build, universal, to /Applications
xcodebuild -project Lockpaw.xcodeproj -scheme Lockpaw -configuration Debug test   # unit tests
```

Signing is set to a personal Apple ID team in `project.yml`; change `DEVELOPMENT_TEAM` to yours.
Builds are not notarised: on another Mac, right-click → Open once.

## Licence

MIT, same as upstream. Copyright for the original work remains with Erik Nielsen; see `LICENSE`.
The mascot artwork is his. "Lockpaw" is his name for his app; this one is LockPawZ.
