import Foundation

/// LockPawZ: the upstream supporter licence (a Polar key check over the network, the
/// yearly ask and the support card) is gone. This private fork is always a "supporter",
/// which just means every bundled mascot and seasonal skin is available. No network.
@MainActor
final class Supporter: ObservableObject {
    static let shared = Supporter()
    @Published private(set) var isSupporter = true
    private init() {}
}
