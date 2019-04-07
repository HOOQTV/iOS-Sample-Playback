//
//  ViewController.swift
//  HOOQ-Player
//
//  Created by Vishal Adatia on 20/6/18.
//  Copyright © 2018 HOOQ. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import Freddy

class ViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    fileprivate let hooqPlayerConvivaManager = HQPlayerConvivaManager.shared
    fileprivate var player = AVPlayer.init(playerItem: nil)
    private var testMagic: Magic?
    
    var selectedContentId = ""
    var selectedContentTitle = ""
    var license: String = ""
    var manifest: String = ""
    
    var authorizationToken = ""
    var refreshToken = ""
    
    @IBOutlet fileprivate weak var contentTableView: UITableView!
    @IBOutlet fileprivate weak var loader: UIActivityIndicatorView!
    
    var contentIdArray: NSMutableArray = NSMutableArray.init()
    var contentNameArray: NSMutableArray = NSMutableArray.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = true
        let btnLogout = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(userLogout(sender:)))
        self.navigationItem.leftBarButtonItem = btnLogout
        
        self.title = "HOOQ"

        let result = UserDefaults.standard.value(forKey: "AuthorizationToken")
        if result == nil {
            loader.startAnimating()
            self.callRefreshTokenAPI()
        } else {
            self.updateTableView()
        }
        self.contentTableView.tableFooterView = UIView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //stopPlayer()
    }
    
    func stopPlayer()  {
        player.replaceCurrentItem(with: nil)
    }
    
    func updateTableView() ->  Void {
        self.contentIdArray.removeAllObjects()
        self.contentNameArray.removeAllObjects()
        
        self.contentNameArray.add("Pretty Woman")
        self.contentNameArray.add("The Oath S1E1")
        self.contentIdArray.add("02a6b7d0-69fb-465e-8cd5-17e4ebcbedc2")
        contentIdArray.add("97c44b21-f398-43e9-ad3a-d58a2b410072")

        self.contentTableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func userLogout(sender: UIBarButtonItem) {
        HQAPIManager.shared().signOutAPI(onSuccess: { isSuccess in
            if isSuccess {
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }
            } else {
                let alert = UIAlertController(title: "Error", message: "Failed to logout user", preferredStyle: .alert)
                let btnOK = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(btnOK)
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
}

/// UITABLEVIEW DELEGATE
extension ViewController {
    // MARK: UITableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contentIdArray.count
    }
    
    // cell height
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell :  UITableViewCell? = contentTableView?.dequeueReusableCell(withIdentifier: "cellReuseIdentifier")
        if cell == nil {
            cell = UITableViewCell.init(style: UITableViewCellStyle.default, reuseIdentifier: "cellReuseIdentifier")
        }
        let text = contentNameArray[indexPath.row]
        cell?.textLabel?.text = text as? String
        return cell!
    }
    func tableView(_ tableView : UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedContentId = contentIdArray[indexPath.row] as! String
        let title = contentNameArray[indexPath.row] as! String
        selectedContentTitle = title
        callPlayAPI(contentId: selectedContentId, title: title)
    }
}


/// AvPlayer
extension ViewController {
    func callAvPlayer(with videoItem: HQVideoItem) -> Void {
        let videoPlayer = HQPlayerViewController(videoItem)
        self.present(videoPlayer, animated: true)
    }
}



//API CALL
extension ViewController {
    
    func callPlayAPI(contentId: String,
                     title: String) -> Void {
        HQAPIManager.shared().callNativePlayAPI(contentId: contentId,
                                                onCompletionBlock: {
                                                    HQServiceResponseBlock -> Void in
            let response : NSDictionary? = HQServiceResponseBlock as? NSDictionary
            print("PlayAPI success response = \(String(describing: response))")
            let playData : NSDictionary? = response?.object(forKey: "data") as? NSDictionary
            guard let jsonData = try? JSONSerialization.data(withJSONObject: playData!, options: .prettyPrinted),
                let jsonO = try? JSON(data: jsonData),
                var videoObject = try? HQVideoItem(json: jsonO) else { return }
            
            self.license = videoObject.license
            self.manifest = videoObject.content
            videoObject.title = title
            UserDefaults.standard.set(self.license,forKey: Constants.KEY.LICENSE)
            UserDefaults.standard.set(self.manifest,forKey: Constants.KEY.MANIFEST)
            self.hooqPlayerConvivaManager.createHOOQPlayerSessionForConviva(videoID:contentId as String,                                                                             assetName:"Test") // Conviva
            DispatchQueue.main.sync {
                self.loader.stopAnimating()
                self.callAvPlayer(with: videoObject) // Load Player
            }
        }, onFailure: {
            HQServiceResponseBlock -> Void in
            let response : NSDictionary? = HQServiceResponseBlock as? NSDictionary
            print("PlayAPI failure response = \(String(describing: response))")
            DispatchQueue.main.sync {
                self.loader.startAnimating()
//                self.callRefreshTokenAPI()
            }
        })
    }
}

///Refresh Token API
extension ViewController {
    //callRefreshToken
    func callRefreshTokenAPI() -> Void {
        HQAPIManager.shared().callTokenAPI(onCompletionBlock: {
            HQServiceResponseBlock -> Void in
            let response : NSDictionary? = HQServiceResponseBlock as? NSDictionary
            
            let tokenData : NSDictionary? = response?.object(forKey: "data") as? NSDictionary
            self.authorizationToken = tokenData?.object(forKey: "accessToken") as! String
            self.refreshToken = tokenData?.object(forKey: "refreshToken") as! String
            UserDefaults.standard.set(self.authorizationToken, forKey: "AuthorizationToken")
            UserDefaults.standard.set(self.refreshToken, forKey: "RefreshToken")
            
            DispatchQueue.main.sync {
                self.loader.stopAnimating()
                self.updateTableView()
                self.callPlayAPI(contentId: self.selectedContentId, title: "")
                //self.callDiscoverFeed()
            }
        }, onFailure: {
            HQServiceResponseBlock -> Void in
            DispatchQueue.main.sync {
                self.loader.stopAnimating()
            }
        })
    }
}

extension ViewController {
    /**
     Methp to add key path observers to the player item.
     This will help us track the player status.
     */
    func addKeypathObserversToCurrentPlayerItem() {
        let playerItem = player.currentItem
        playerItem?.addObserver(self, forKeyPath: "playbackBufferEmpty", options: .new, context: nil)
        playerItem?.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: .new, context: nil)
        playerItem?.addObserver(self, forKeyPath: "playbackBufferFull", options: .new, context: nil)
        playerItem?.addObserver(self, forKeyPath: "status", options: .new, context: nil)
    }
    /**
     Method to remove the key path observers to the player item.
     */
    func removeKeyPathObserversToCurrentPlayerItem() {
        let playerItem = player.currentItem
        playerItem?.removeObserver(self, forKeyPath: "playbackBufferEmpty")
        playerItem?.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
        playerItem?.removeObserver(self, forKeyPath: "playbackBufferFull")
        playerItem?.removeObserver(self, forKeyPath: "status")
    }
}

extension ViewController {
    @objc
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if object is AVPlayerItem {
            switch keyPath {
            case "playbackBufferEmpty"?:
                print("playbackBufferEmpty >> ")
                //setDisplayLoadingIndicator(true)
            case "playbackLikelyToKeepUp"?, "playbackBufferFull"?:
                print("playbackLikelyToKeepUp >> ")
                //setDisplayLoadingIndicator(false)
            case "status"?:
                print("status >> ")
                //handlePlayerItemStatusUpdate(player.currentItem?.status)
            default:break
                //setDisplayLoadingIndicator(false)
            }
        }
    }
}
