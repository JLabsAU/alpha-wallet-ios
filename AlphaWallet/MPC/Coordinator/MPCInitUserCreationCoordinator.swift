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
import PromiseKit
import SwiftyJSON
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
        if #available(iOS 15.0, *) {
            UIWindow.showLoading()
            let _ = loadDfnsWallets().done { json in
                if let address = json["items"].arrayValue.first?["address"].stringValue {
                    if let curWallet = self.keystore.wallets.first(where: { $0.address.eip55String ==  AlphaWallet.Address(string: address)?.eip55String }) {
                        self.delegate?.didAddUser(username: user, wallet: curWallet, coordinator: self)
                    } else {
                        let _ = self.importWallet(json).done { wallet in
                            self.delegate?.didAddUser(username: user, wallet: wallet, coordinator: self)
                        }
                    }
                } else {
                    self.createAndLoadWallete(user)
                }
            }.ensure {

            }.catch { error in
                UIWindow.toast(error.localizedDescription)
            }
        }
    }
    
    @available(iOS 15.0, *)
    func createAndLoadWallete(_ username: String) {
        UIWindow.showLoading()
        let _ = self.createDfnsWallet().then { json in
            return self.loadDfnsWallets(retry: true)
        }.then { json in
            return self.importWallet(json)
        }.done { wallet in
            self.delegate?.didAddUser(username: username, wallet: wallet, coordinator: self)
        }.ensure {
           
        }.catch { err in
            UIWindow.hideLoading()
            UIWindow.toast(err.localizedDescription)
        }
    }
    
    func importWallet(_ json: JSON) -> Promise<Wallet> {
        return Promise { resolver in
            let address: String = json["items"].arrayValue.first?["address"].stringValue ?? ""
            let walletId: String = json["items"].arrayValue.first?["id"].stringValue ?? ""
            self.keystore.addWallet(wallet: .init(address: .init(string: address)!, origin: .dfns, walletId: walletId)).sink { wallet in
                resolver.fulfill(wallet)
            }.store(in: &cancellable)
        }
    }
    
    @available(iOS 15.0, *)
    func createDfnsWallet() -> Promise<JSON> {
        return DfnsManager.shared.createWallet(net: "EthereumSepolia")
    }
    
    @available(iOS 15.0, *)
    func loadDfnsWallets(retry: Bool = false) -> Promise<JSON> {
        return DfnsManager.shared.listWallets().then { json in
            let address: String = json["items"].arrayValue.first?["address"].stringValue ?? ""
            if address.isEmpty && retry {
                return self.loadDfnsWallets(retry: true)
            } else {
                return Promise.value(json)
            }
        }
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
