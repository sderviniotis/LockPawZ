import Foundation

/// LockPawZ: how the lock presents itself.
///
/// Transparent (the default) shows no cover at all. Every screen stays exactly as it was,
/// so work in progress can be watched from across the room, while the keyboard, pointer and
/// trackpad are swallowed at the event tap. Touch ID is armed straight away; its system
/// prompt is visible, since there is no cover to hide it behind.
///
/// Covered is upstream Lockpaw's behaviour: shield-level overlays on every screen, the
/// mascot, the password field. Kept as the off position of one setting.
enum LockMode {
    static let transparentKey = "transparentLock"
    static let defaultTransparent = true

    static var isTransparent: Bool {
        UserDefaults.standard.object(forKey: transparentKey) as? Bool ?? defaultTransparent
    }
}
