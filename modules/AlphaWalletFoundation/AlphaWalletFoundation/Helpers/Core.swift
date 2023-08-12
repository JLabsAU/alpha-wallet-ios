// Copyright © 2019 Stormbird PTE. LTD.

import Foundation
import func AlphaWalletCore.isRunningTests
let isRunningTests = AlphaWalletCore.isRunningTests

public func isAlphaWallet() -> Bool {
    Bundle.main.bundleIdentifier == "xyz.j-labs.wallet"
}

public func isRunningOnMac() -> Bool {
    if ProcessInfo.processInfo.isMacCatalystApp {
        return true
    }
    if #available(iOS 14.0, *) {
        return ProcessInfo.processInfo.isiOSAppOnMac
    } else {
        return false
    }
}
