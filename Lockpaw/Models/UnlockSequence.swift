import Foundation

/// LockPawZ: what a matched unlock sequence does.
enum SequenceAction: String, CaseIterable {
    /// Unlock and leave the desktop as it is.
    case desktop
    /// Unlock, then start the macOS screensaver. With "require password after screen saver
    /// begins" on, this hands the Mac to its real lock screen.
    case screensaver
}

/// The two secret key sequences, stored as arrays of virtual key codes. Typed on the
/// physical keyboard while locked (the tap feeds them to `SequenceMatcher`), never
/// shown on screen, never reachable by a local process.
enum UnlockSequence {
    static let desktopKey = "unlockSequenceDesktop"
    static let screensaverKey = "unlockSequenceScreensaver"

    /// Down Up Down Up X and Down Up Down Up S.
    static let defaultDesktop: [Int] = [125, 126, 125, 126, 7]
    static let defaultScreensaver: [Int] = [125, 126, 125, 126, 1]

    static let minLength = 4
    static let maxLength = 8
    /// Seconds allowed between two keys of a sequence before it starts over.
    static let stepTimeout: TimeInterval = 5

    static func stored(_ action: SequenceAction) -> [Int] {
        let key = action == .desktop ? desktopKey : screensaverKey
        let fallback = action == .desktop ? defaultDesktop : defaultScreensaver
        guard let codes = UserDefaults.standard.array(forKey: key) as? [Int], isValid(codes) else { return fallback }
        return codes
    }

    static func save(_ codes: [Int], for action: SequenceAction) {
        UserDefaults.standard.set(codes, forKey: action == .desktop ? desktopKey : screensaverKey)
        NotificationCenter.default.post(name: .lockpawSequencePreferenceChanged, object: nil)
    }

    static func isValid(_ codes: [Int]) -> Bool {
        (minLength...maxLength).contains(codes.count)
    }

    /// Neither sequence may be a prefix of the other: the shorter one would always fire
    /// first and the longer could never be typed.
    static func conflict(desktop: [Int], screensaver: [Int]) -> String? {
        if desktop == screensaver { return "The two sequences are the same." }
        if desktop.starts(with: screensaver) || screensaver.starts(with: desktop) {
            return "One sequence starts with the other, so the shorter one would always win."
        }
        return nil
    }

    // MARK: - Display

    static func display(_ codes: [Int]) -> String {
        codes.map(keyName).joined(separator: " ")
    }

    /// Readable name for a virtual key code (ANSI layout for letters and digits).
    static func keyName(_ code: Int) -> String {
        if let name = keyNames[code] { return name }
        return "key\(code)"
    }

    private static let keyNames: [Int: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
        11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 18: "1", 19: "2",
        20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8",
        29: "0", 30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "Return",
        37: "L", 38: "J", 39: "\u{2019}", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/",
        45: "N", 46: "M", 47: ".", 48: "Tab", 49: "Space", 50: "`", 51: "Delete",
        53: "Esc", 96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9",
        103: "F11", 109: "F10", 111: "F12", 118: "F4", 120: "F2", 122: "F1",
        115: "Home", 116: "PgUp", 117: "Fwd Del", 119: "End", 121: "PgDn",
        123: "\u{2190}", 124: "\u{2192}", 125: "\u{2193}", 126: "\u{2191}",
    ]
}

/// Pure matcher, one per lock session. Every key typed while locked is fed in; it tracks
/// progress through both sequences at once (they may share a prefix), restarts on a wrong
/// key (a wrong key that happens to be a sequence's first key counts as that first key),
/// and starts over after `stepTimeout` of silence. Nothing is reported until a whole
/// sequence lands, so a wrong guess learns nothing.
struct SequenceMatcher {
    private let sequences: [(action: SequenceAction, codes: [Int])]
    private var progress: [Int]
    private var lastKey: Date?
    private let timeout: TimeInterval

    init(desktop: [Int], screensaver: [Int], timeout: TimeInterval = UnlockSequence.stepTimeout) {
        sequences = [(.desktop, desktop), (.screensaver, screensaver)]
        progress = [0, 0]
        self.timeout = timeout
    }

    mutating func feed(keyCode: Int, now: Date = Date()) -> SequenceAction? {
        if let last = lastKey, now.timeIntervalSince(last) > timeout { reset() }
        lastKey = now

        var matched: SequenceAction?
        for i in sequences.indices {
            let codes = sequences[i].codes
            if progress[i] < codes.count, codes[progress[i]] == keyCode {
                progress[i] += 1
            } else {
                progress[i] = codes.first == keyCode ? 1 : 0
            }
            if progress[i] == codes.count { matched = sequences[i].action }
        }
        if matched != nil { reset() }
        return matched
    }

    mutating func reset() {
        progress = [0, 0]
        lastKey = nil
    }
}
