//
//  MPCInitUserCreationCoordinator.swift
//  AlphaWallet
//
//  Created by leven on 2023/8/14.
//

import Foundation
import UIKit
import AlphaWalletFoundation
import Combine
protocol MPCInitUserCreationCoordinatorDelegate: AnyObject {
    func didAddUser(username: String, wallet: Wallet, coordinator: MPCInitUserCreationCoordinator)
}

class MPCInitUserCreationCoordinator: Coordinator {
    
    var coordinators: [Coordinator] = []
    
    let navigationController: UINavigationController
    private let keystore: Keystore
    private let config: Config
    
    weak var delegate: MPCInitUserCreationCoordinatorDelegate?
    private var cancellable = Set<AnyCancellable>()

    init(config: Config,
         navigationController: UINavigationController,
         keystore: Keystore) {
        self.config = config
        self.navigationController = navigationController
        self.keystore = keystore
        navigationController.setNavigationBarHidden(false, animated: true)
    }
    
    func start() {
        startDfnsCoordinator()
    }

    private func startDfnsCoordinator() {
        let coordinator = DfnsInitUserCreationCoordinator(
            config: config,
            navigationController: navigationController,
            keystore: keystore)
        coordinator.delegate = self
        coordinator.start()
        addCoordinator(coordinator)
    }
}
extension MPCInitUserCreationCoordinator: DfnsInitUserCreationCoordinatorDelegate {
    func didSignUp(user: String) {
        
    }
    
    func didSignIn(user: String) {
        self.createInstantWallet(username: user)
    }
    
    func createInstantWallet(username: String) {
        //NOTE: don't use weak ref here
        navigationController.displayLoading(text: R.string.localizable.walletCreateInProgress(), animated: false)
        keystore.createHDWallet()
            .sink(receiveCompletion: { result in
                self.navigationController.hideLoading(animated: false)
                if case .failure(let error) = result {
                    self.navigationController.displayError(error: error)
                }
            }, receiveValue: { wallet in
                WhatsNewExperimentCoordinator.lastCreatedWalletTimestamp = Date()
                self.delegate?.didAddUser(username: username, wallet: wallet, coordinator: self)
            }).store(in: &cancellable)
    }
}
