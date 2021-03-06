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
    fileprivate let hooqPlayerConvivaManager = HQPlayerConvivaManager()
    fileprivate var player = AVPlayer.init(playerItem: nil)
    private var testMagic: Magic?
    
    var selectedContentId = ""
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
        self.title = "HOOQ"

        let result = UserDefaults.standard.value(forKey: "AuthorizationToken")
        if result == nil {
            loader.startAnimating()
            self.callRefreshTokenAPI()
        } else {
            self.updateTableView()
        }
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
        
        self.contentNameArray.add("MIB")
        contentIdArray.add("e53579d4-cba9-4d1f-828d-bed04c782e92")
        
        self.contentNameArray.add("MIB Long Duration")
        contentIdArray.add("9de5a8f3-1e8d-4bb0-a637-e22b242b8b19")

        self.contentTableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
