//
//  DfnsUserSignupViewController.swift
//  AlphaWallet
//
//  Created by leven on 2023/8/14.
//

import Foundation
import AlphaWalletFoundation
import SnapKit
protocol DfnsUserSignupViewControllerDelegate: AnyObject {
    func didSignUp(username: String)
    func didSignIn(username: String)
}

class DfnsUserSignupViewController: UIViewController {
    
    private let keystore: Keystore
    private let initSignInOrUp: Bool
    
    weak var delegate: DfnsUserSignupViewControllerDelegate?
    
    lazy var switchButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("sign in", for: .normal)
        button.setTitle("sign up", for: .selected)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitleColor(UIColor(hex: "828282"), for: .normal)
        button.addTarget(self, action: #selector(self.switchSignIn), for: .touchUpInside)
        return button

    }()

    lazy var confirmButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Configm", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = UIColor(hex: "171717")
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.layer.cornerRadius = 4
        button.layer.masksToBounds = true
        button.addTarget(self, action: #selector(self.clickconfirm), for: .touchUpInside)
        return button
    }()
    
    lazy var nameInput: UITextField = {
        let input = UITextField()
        input.placeholder = "Input name"
        input.font = UIFont.systemFont(ofSize: 17)
        input.borderStyle = .roundedRect
        input.attributedPlaceholder = NSAttributedString(string: "Input name", attributes: [.font: UIFont.systemFont(ofSize: 17), .foregroundColor: UIColor(hex: "AAAAAA")])
        input.backgroundColor = UIColor(hex: "EEEEEE")
        return input
    }()
    
    lazy var passwordInput: UITextField = {
        let input = UITextField()
        input.font = UIFont.systemFont(ofSize: 17)
        input.borderStyle = .roundedRect
        input.attributedPlaceholder = NSAttributedString(string: "Input password", attributes: [.font: UIFont.systemFont(ofSize: 17), .foregroundColor: UIColor(hex: "AAAAAA")])
        input.backgroundColor = UIColor(hex: "EEEEEE")
        return input
    }()
    
    init(keystore: Keystore, initSignInOrUp: Bool) {
        self.keystore = keystore
        self.initSignInOrUp = initSignInOrUp
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Configuration.Color.Semantic.defaultViewBackground
        nameInput.addedOn(self.view).snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(100)
            make.centerX.equalToSuperview()
            make.left.equalTo(20)
            make.height.equalTo(48)
        }
        self.passwordInput.alpha = 0
        self.passwordInput.addedOn(self.view).snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.height.equalTo(self.nameInput)
            make.top.equalTo(self.nameInput.snp.bottom).offset(20)
        }
        
        self.confirmButton.addedOn(self.view).snp.makeConstraints { make in
            make.left.equalTo(20)
            make.centerX.height.equalTo(nameInput)
            make.bottom.equalTo(-50)
        }
        self.switchButton.addedOn(self.view).snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(self.confirmButton.snp.top).offset(-16)
        }
        
        self.view.addTap { [weak self] in
            guard let self = self else { return }
            self.view.endEditing(true)
        }
        self.switchButton.isSelected = self.initSignInOrUp
        self.updateUI()
    }
    
    func updateUI() {
        self.title = self.switchButton.isSelected ? "Sign In" : "Sign Up"
        UIView.animate(withDuration: 0.2) {
            if self.switchButton.isSelected {
                self.passwordInput.alpha = 0
            } else {
                self.passwordInput.alpha = 1
            }
        }
    }
    
    @objc func switchSignIn() {
        self.switchButton.isSelected = !self.switchButton.isSelected
        self.updateUI()
    }
    
    @objc func clickconfirm() {
        if self.switchButton.isSelected {
            self.signIn()
        } else {
            self.signUp()
        }
    }
    
    func signUp() {
        guard let name = self.nameInput.text, name.trimmed().isEmpty == false else {
            UIWindow.toast("please input name")
            return
        }
        
        guard let password = self.passwordInput.text, password.trimmed().isEmpty == false else {
            UIWindow.toast("please input password")
            return
        }
        if #available(iOS 15.0, *) {
            UIWindow.showLoading()
            DfnsManager.shared.register(username: name, password: password).done { [weak self]json in
                guard let self = self else { return }
                if let name = json["username"].string {
                    UIWindow.toast("Go to sign in")
                    self.switchSignIn()
                    self.nameInput.text = name
                    self.delegate?.didSignUp(username: name)
                } else {
                    UIWindow.toast(json.rawString() ?? "")
                }
            }.ensure {
                UIWindow.hideLoading()
            }.catch { error in
                UIWindow.toast(error.localizedDescription)
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    func signIn() {
        guard let name = self.nameInput.text, name.trimmed().isEmpty == false else {
            UIWindow.toast("please input name")
            return
        }
        
        if #available(iOS 15.0, *) {
            UIWindow.showLoading()
            DfnsManager.shared.signIn(username: name).done { [weak self]json in
                guard let self = self else { return }
                if let name = json["username"].string {
                    self.keystore.currentUserName = name
                    self.delegate?.didSignIn(username: name)
                } else {
                    UIWindow.toast(json.rawString() ?? "")
                }
            }.ensure {
                UIWindow.hideLoading()
            }.catch { error in
                UIWindow.toast(error.localizedDescription)
            }
        }
        
    }
    
    func getWallets() {
        if #available(iOS 15.0, *) {
            DfnsManager.shared.listWallets().done { json in
                print(json)
            }.catch { error in
                
            }
        } else {
            // Fallback on earlier versions
        }
    }
}
