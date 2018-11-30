//
//  LoginViewController.swift
//  HOOQ-Player
//
//  Created by Rohan Chalana on 15/11/18.
//  Copyright © 2018 HOOQ. All rights reserved.
//

import Foundation
import UIKit

final class HQLoginViewController: UIViewController, HQLoginViewDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        let loginView = HQLoginView()
        view.addSubview(loginView)
        setupNavigationBar()
        loginView.backgroundColor = .white
        loginView.snp.makeConstraints { make in
            make.top.bottom.left.right.equalToSuperview()
        }
        loginView.delegate = self
    }
    
    private func setupNavigationBar() {
        self.navigationController?.navigationBar.barStyle = UIBarStyle.blackTranslucent
        self.navigationController?.navigationBar.backgroundColor = UIColor.init(red: 179/255, green: 37/255, blue: 156/255, alpha: 1)
        
        self.navigationController?.navigationBar.tintColor = UIColor.white // for titles, buttons, etc.
        let navigationTitleFont = UIFont(name: "Avenir", size: 20)!
        self.navigationController?.navigationBar.titleTextAttributes = [kCTFontAttributeName: navigationTitleFont] as [NSAttributedStringKey : Any]
    }
    
    func loginButton(username: String?,
                     password: String?,
                     view: HQLoginView) {
        guard let userId = username else { return }
        signIn(with: userId)        
    }
    
    private func signIn(with username: String) {
        HQAPIManager.shared().signInAPI(with: username, onCompletionBlock: {
            HQServiceResponseBlock -> Void in
            let response : NSDictionary? = HQServiceResponseBlock as? NSDictionary
            let tokenData : NSDictionary? = response?.object(forKey: "data") as? NSDictionary
            let authorizationToken = tokenData?.object(forKey: "accessToken") as! String
            let refreshToken = tokenData?.object(forKey: "refreshToken") as! String
            UserDefaults.standard.set(authorizationToken, forKey: "AuthorizationToken")
            UserDefaults.standard.set(refreshToken, forKey: "RefreshToken")
            DispatchQueue.main.sync {
                self.presentContentListController()
            }
        }, onFailure: {
            HQServiceResponseBlock -> Void in
            DispatchQueue.main.sync {
            }
        })
    
    }
    private func presentContentListController() {
        let vc = ViewController.init(nibName: "ViewController", bundle: nil)
        navigationController?.pushViewController(vc, animated: true)
    }
}
