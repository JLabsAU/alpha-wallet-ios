//
//  DfnsInitUserCreationCoordinator.swift
//  AlphaWallet
//
//  Created by leven on 2023/8/14.
//

import Foundation
import UIKit
import AlphaWalletFoundation
protocol DfnsInitUserCreationCoordinatorDelegate: AnyObject {
    func didSignUp(user: String)
    func didSignIn(user: String)
}

class DfnsInitUserCreationCoordinator: Coordinator, DfnsUserCreationViewControllerDelegate {
    
    var coordinators: [Coordinator] = []
    let navigationController: UINavigationController
    private let keystore: Keystore
    private let config: Config
    
    weak var delegate: DfnsInitUserCreationCoordinatorDelegate?
    
    init(config: Config,
         navigationController: UINavigationController,
         keystore: Keystore) {
        self.config = config
        self.navigationController = navigationController
        self.keystore = keystore
        navigationController.setNavigationBarHidden(false, animated: true)
    }
    
    func start() {
        let vc = DfnsUserCreationViewController(keystore: self.keystore)
        vc.delegate = self
        navigationController.viewControllers = [vc]
    }
    
    func didSignIn(user: String) {
        self.delegate?.didSignIn(user: user)
    }
    func didSignUp(user: String) {
        self.delegate?.didSignUp(user: user)

    }
}
