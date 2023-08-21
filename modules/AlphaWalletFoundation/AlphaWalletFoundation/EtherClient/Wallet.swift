// Copyright SIX DAY LLC. All rights reserved.

import Foundation

public enum WalletType: Equatable, Hashable, CustomStringConvertible {
    case real(AlphaWallet.Address)
    case watch(AlphaWallet.Address)
    case hardware(AlphaWallet.Address)
    case dfns(AlphaWallet.Address)
    public var description: String {
        switch self {
        case .real(let address):
            return ".real(\(address.eip55String))"
        case .watch(let address):
            return ".watch(\(address.eip55String))"
        case .hardware(let address):
            return ".hardware(\(address.eip55String))"
        case .dfns(let address):
            return ".dfns(\(address.eip55String))"
        }
    }
}

public enum WalletOrigin: Int {
    case privateKey
    case hd
    case hardware
    case watch
    case dfns
}

public struct Wallet: Equatable, CustomStringConvertible {
    public let type: WalletType
    public let origin: WalletOrigin
    
    public var address: AlphaWallet.Address {
        switch type {
        case .real(let account):
            return account
        case .watch(let address):
            return address
        case .hardware(let address):
            return address
        case .dfns(let address):
            return address
        }
    }

    public var allowBackup: Bool {
        switch type {
        case .real:
            return true
        case .watch, .hardware, .dfns:
            return false
        }
    }

    public var description: String {
        type.description
    }

    public init(address: AlphaWallet.Address, origin: WalletOrigin, walletId: String? = nil) {
        switch origin {
        case .privateKey, .hd:
            self.type = .real(address)
        case .hardware:
            self.type = .hardware(address)
        case .watch:
            self.type = .watch(address)
        case .dfns:
            self.type = .real(address)
        }
        self.origin = origin
    }
}

extension Wallet: Hashable { }
