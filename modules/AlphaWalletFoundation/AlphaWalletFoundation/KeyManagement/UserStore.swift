//
//  UserStore.swift
//  AlphaWalletFoundation
//
//  Created by leven on 2023/8/14.
//

import Foundation
public protocol UserStore {
    var currentUserName: String? { get set }
}

public class DefaultUserStore: UserStore {
    private struct Keys {
        static let username = "mpc_current_username"
        
    }
    public var currentUserName: String? {
        get {
            return userDefaults.string(forKey: Keys.username)
        }
        
        set {
            userDefaults.set(newValue, forKey: Keys.username)
        }
    }
    let userDefaults: UserDefaults
    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
}
