// Copyright SIX DAY LLC. All rights reserved.

import Foundation

public struct SentTransaction {
    public let id: String
    public let original: UnsignedTransaction
    public init(id: String, original:UnsignedTransaction) {
        self.id = id
        self.original = original
    }
}
