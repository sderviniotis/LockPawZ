# Security

LockPawZ is a personal fork, not a distributed product. There is no support, no release
channel and no vulnerability reporting process. Issues are tracked privately.

The threat model is the same as upstream Lockpaw's and is worth repeating: this blocks input
and is **not** a security boundary. Anyone with physical access can power the Mac off or end
the process from another session. For confidentiality, use the macOS lock screen (Ctrl+Cmd+Q).

What this fork does guarantee, by construction:

- No software path unlocks it: no URL scheme, Shortcut, CLI command, notification or AppleScript.
- Only physical keystrokes (events with no originating process) can advance an unlock sequence.
- No network access of any kind.

Upstream's security policy and its private vulnerability reporting are at
https://github.com/sorkila/lockpaw/security.
