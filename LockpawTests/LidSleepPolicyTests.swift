import XCTest
@testable import Lockpaw

final class LidSleepPolicyTests: XCTestCase {

    private let ac = LidSleepPolicy.Power(onBattery: false, batteryPercent: 80)

    private func decide(
        enabled: Bool = true, helperReady: Bool = true, locked: Bool = true,
        power: LidSleepPolicy.Power? = nil, thermal: LidSleepPolicy.Thermal = .nominal,
        cutOff: Bool = false
    ) -> LidSleepPolicy.Decision {
        LidSleepPolicy.decide(
            enabled: enabled, helperReady: helperReady, locked: locked,
            power: power ?? ac, thermal: thermal, cutOffForBattery: cutOff
        )
    }

    func testBlocksOnlyWhenEnabledReadyAndLocked() {
        XCTAssertTrue(decide().block)
        XCTAssertFalse(decide(enabled: false).block)
        XCTAssertFalse(decide(helperReady: false).block)
        XCTAssertFalse(decide(locked: false).block, "never a general keep-awake toggle")
    }

    func testHotMacSleeps() {
        XCTAssertTrue(decide(thermal: .fair).block)
        XCTAssertFalse(decide(thermal: .serious).block)
        XCTAssertFalse(decide(thermal: .critical).block)
    }

    func testBatteryFloorCutsOff() {
        let atFloor = decide(power: .init(onBattery: true, batteryPercent: 20))
        XCTAssertFalse(atFloor.block)
        XCTAssertTrue(atFloor.cutOffForBattery)
        XCTAssertTrue(decide(power: .init(onBattery: true, batteryPercent: 21)).block)
    }

    func testBatteryHysteresis() {
        // Cut off at 20%; a wobble to 22% must not flip it back on.
        XCTAssertFalse(decide(power: .init(onBattery: true, batteryPercent: 22), cutOff: true).block)
        let resumed = decide(power: .init(onBattery: true, batteryPercent: 25), cutOff: true)
        XCTAssertTrue(resumed.block)
        XCTAssertFalse(resumed.cutOffForBattery)
    }

    func testChargerClearsTheBatteryCutoff() {
        let plugged = decide(power: .init(onBattery: false, batteryPercent: 10), cutOff: true)
        XCTAssertTrue(plugged.block)
        XCTAssertFalse(plugged.cutOffForBattery)
    }

    func testUnreadableBatteryKeepsThePreviousCutoff() {
        XCTAssertFalse(decide(power: .init(onBattery: true, batteryPercent: nil), cutOff: true).block)
        XCTAssertTrue(decide(power: .init(onBattery: true, batteryPercent: nil), cutOff: false).block)
    }

    func testThermalStateMapping() {
        XCTAssertEqual(LidSleepPolicy.Thermal(.serious), .serious)
    }

    // MARK: - System lock

    private func unlocks(_ state: LockState = .locked, seen: Bool = true, stillLocked: Bool = false, setting: Bool = true) -> Bool {
        SystemLockPolicy.unlocksAfterSystemUnlock(
            state: state, systemLockSeenDuringLock: seen, sessionReportsLocked: stillLocked, settingEnabled: setting
        )
    }

    func testAutoUnlockAfterMacUnlockNeedsEveryCondition() {
        XCTAssertTrue(unlocks())
        XCTAssertFalse(unlocks(setting: false), "off by default: Lockpaw stays locked")
        XCTAssertFalse(unlocks(seen: false), "no confirmed macOS lock during this session proves nothing")
        for state in [LockState.unlocked, .locking, .unlocking] {
            XCTAssertFalse(unlocks(state))
        }
    }

    /// The distributed "screenIsUnlocked" can be posted by any process. If the window
    /// server still reports the session locked, it was not a real unlock.
    func testForgedUnlockNotificationDoesNothing() {
        XCTAssertFalse(unlocks(stillLocked: true))
    }

    func testMacLockIsNotAnAccessibilityRevocation() {
        XCTAssertTrue(SystemLockPolicy.forceUnlocksForAccessibility(trusted: false, systemScreenLocked: false))
        XCTAssertFalse(SystemLockPolicy.forceUnlocksForAccessibility(trusted: false, systemScreenLocked: true))
        XCTAssertFalse(SystemLockPolicy.forceUnlocksForAccessibility(trusted: true, systemScreenLocked: false))
    }
}
