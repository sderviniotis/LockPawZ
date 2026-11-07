# LockPawZ

Private fork of Lockpaw (https://github.com/sorkila/lockpaw, MIT) for Steve Derviniotis.
Upstream's CLAUDE.md (release pipeline, Sparkle, notarisation, appcast, Homebrew, marketing)
does NOT apply here. Git history before 2026-11-08 is upstream's.

## What LockPawZ is
A macOS menu bar app that locks keyboard, mouse and trackpad system-wide while leaving every
screen visible (no overlay), unlocked only by the person at the keyboard:
- Touch ID, armed while locked (upstream mechanism)
- Sequence A (default Down Up Down Up X): unlock to desktop
- Sequence B (default Down Up Down Up S): unlock, then start the macOS screensaver
Starts unlocked on every launch. No network access. No update channel. No root helper.

## Removed from upstream (2026-11-08, Phase 4)
- lockpaw://unlock, unlock-password, toggle URL handlers (unlock without auth from any local process)
- Sparkle auto-update (would have replaced the fork with stock Lockpaw)
- LockpawHelper root LaunchDaemon and lid-closed mode
- DEBUG Cmd+Shift+Q kill switch in InputBlocker
- Supporter licence (Polar check), support ask, support card. `Supporter` is a stub, always true.
- Webhook relay (ntfy / Pushover / webhook) and Keychain helper
- Release workflow, Homebrew cask, FUNDING.yml
Agent hooks (CLI install-hook) remain in code but are never connected.

## Build
```
cd ~/Projects/LockPawZ && xcodegen generate && open Lockpaw.xcodeproj
```
Signing: Steve's Personal Team (free Apple ID), Debug and Release. Debug bundle id is
com.eriknielsen.lockpaw.debug; Accessibility must be granted to "Lockpaw Debug".
After a rebuild that changes the signature: `tccutil reset Accessibility com.eriknielsen.lockpaw.debug`

## Test
```
xcodebuild -project Lockpaw.xcodeproj -scheme Lockpaw -configuration Debug test
```

## Plan and tracking
- Phase plan: Claude project "Keyboard lock", doc lockpaw-fork-plan.md
- Tracker: monday.com board LockPawZ (Projects workspace)
- Docs: Google Drive "Projects (Dev < >)/LockPawZ" (security review, this plan, tools)
