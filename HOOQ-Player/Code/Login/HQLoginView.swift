//
//  LoginView.swift
//  HOOQ-Player
//
//  Created by Rohan Chalana on 15/11/18.
//  Copyright © 2018 HOOQ. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol HQLoginViewDelegate: class {
    func loginButton(username: String?,
                     password: String?,
                     view: HQLoginView)
}

final class HQLoginView: UIView {
    
    weak var delegate: HQLoginViewDelegate?
    private let disposeBag = DisposeBag()
    
    private lazy var loginNameLabel: UILabel = {
        let loginNameLabel = UILabel()
        loginNameLabel.textAlignment = .center
        loginNameLabel.text = "Login"
        loginNameLabel.textColor = .black
        loginNameLabel.font = loginNameLabel.font.withSize(18)
        return loginNameLabel
    }()
    
    private let username: UITextField = {
        let usernameTextField = UITextField()
        usernameTextField.placeholder = "Username"
        return usernameTextField
    }()
    
    private let password: UITextField = {
        let usernameTextField = UITextField()
        usernameTextField.placeholder = "Password"
        return usernameTextField
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor(red: 149/255.0, green: 27/255.0, blue: 129/255.0, alpha: 1.0)
        button.setTitle("Login", for: .normal)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupEvents()

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(loginNameLabel)
        addSubview(username)
        addSubview(password)
        addSubview(loginButton)
    }
    
    private func events() {
        addSubview(loginNameLabel)
        addSubview(username)
//        addSubview(password)
        addSubview(loginButton)
    }

    private func setupEvents() {
        loginButton.rx.tap.subscribe({ [weak self] _ in
            guard let `self` = self else { return }
            self.delegate?.loginButton(username: self.username.text,
                                       password: self.password.text,
                                       view: self)
        }).disposed(by: disposeBag)
    }
    
    private func setupConstraints() {
        loginNameLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview().offset(-32)
            make.left.right.equalToSuperview()
            make.height.equalTo(32)
        }
        
        username.snp.makeConstraints { make in
            make.top.equalTo(loginNameLabel.snp.bottom).offset(16)
            make.height.equalTo(32)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
        }
        
//        password.snp.makeConstraints { make in
//            make.top.equalTo(username.snp.bottom).offset(4)
//            make.height.equalTo(32)
//            make.centerX.equalToSuperview()
//            make.width.equalTo(200)
//        }
        
        loginButton.snp.makeConstraints { make in
            make.top.equalTo(username.snp.bottom).offset(16)
            make.height.equalTo(32)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
        }
    }
}
