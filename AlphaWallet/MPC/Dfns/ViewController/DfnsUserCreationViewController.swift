//
//  DfnsUserCreationViewController.swift
//  AlphaWallet
//
//  Created by leven on 2023/8/14.
//

import Foundation
import AlphaWalletFoundation
import SnapKit
import Combine
protocol DfnsUserCreationViewControllerDelegate: AnyObject {
    func didSignUp(user: String)
    func didSignIn(user: String)
}

class DfnsUserCreationViewController: UIViewController, DfnsUserSignupViewControllerDelegate {
    private let keystore: Keystore
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit

        return imageView
    }()
    private let buttonsBar = VerticalButtonsBar(numberOfButtons: 2)
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        return titleLabel
    }()
    
    weak var delegate: DfnsUserCreationViewControllerDelegate?
    
    init(keystore: Keystore) {
        self.keystore = keystore
        super.init(nibName: nil, bundle: nil)
        
        view.addSubview(imageView)
        view.addSubview(titleLabel)
        titleLabel.isHidden = true
        let footerBar = ButtonsBarBackgroundView(buttonsBar: buttonsBar, separatorHeight: 0)
        view.addSubview(footerBar)

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            imageView.widthAnchor.constraint(equalToConstant: 300),
            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            footerBar.anchorsConstraint(to: view)
        ])
        self.configure()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    func configure() {
        view.backgroundColor = Configuration.Color.Semantic.defaultViewBackground
        imageView.image = UIImage.init(named: "dfns_purple")
        titleLabel.attributedText =  {
            let font: UIFont = ScreenChecker().isNarrowScreen ? Fonts.regular(size: 20) : Fonts.regular(size: 30)
            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center

            return .init(string: R.string.localizable.gettingStartedSubtitle(), attributes: [
                .font: font,
                .foregroundColor: Configuration.Color.Semantic.defaultForegroundText,
                .paragraphStyle: paragraph
            ])
        }()

        let createUserButton = buttonsBar.buttons[0]
        createUserButton.setTitle("Sign In", for: .normal)
        createUserButton.addTarget(self, action: #selector(alreadyHaveUserWallet), for: .touchUpInside)

        let alreadyHaveUserButton = buttonsBar.buttons[1]
        alreadyHaveUserButton.setTitle("Sign Up", for: .normal)
        alreadyHaveUserButton.addTarget(self, action: #selector(createUserSelected), for: .touchUpInside)
    }
    
    @objc private func createUserSelected(_ sender: UIButton) {
        let vc = DfnsUserSignupViewController(keystore: self.keystore, initSignInOrUp: false)
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func alreadyHaveUserWallet(_ sender: UIButton) {
        let vc = DfnsUserSignupViewController(keystore: self.keystore, initSignInOrUp: true)
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func didSignIn(username: String) {
        self.delegate?.didSignIn(user: username)
    }
    
    func didSignUp(username: String) {
        self.delegate?.didSignUp(user: username)
    }
}
