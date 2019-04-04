//
//  HQPlayerConvivaManager.swift
//  HOOQ-Player
//
//  Created by Vishal Adatia on 25/6/18.
//  Copyright © 2018 HOOQ. All rights reserved.
//

import UIKit
import ConvivaAVFoundation
import ConvivaCore
import AVKit
import AVFoundation

class HQPlayerConvivaManager: NSObject {
    
    static let shared = HQPlayerConvivaManager()
    
    var session : ConvivaLightSession! // Conviva Session object
    var convivaMetadata : ConvivaContentInfo! // Conviva Session Metadata
    var customMetaTags : NSMutableDictionary!
    
    func createHOOQPlayerSessionForConviva(videoID:String, assetName:String) -> Void {
        self.clearConvivaSession()
        
        convivaMetadata = ConvivaContentInfo.createInfoForLightSession(withAssetName:assetName as String?) as! ConvivaContentInfo
        convivaMetadata.isLive = false
        convivaMetadata.playerName = "HOOQ Player"
        convivaMetadata.viewerId = ""
        
        // Extra Tags
        customMetaTags = NSMutableDictionary.init()
        customMetaTags.setValue(videoID, forKey:"channelId")
        customMetaTags.setValue("HLS", forKey: "streamProtocol")
        customMetaTags.setValue("Internal", forKey: "playerVendor")
        convivaMetadata.tags = customMetaTags
        self.session = LivePass.createSession(withStreamer:nil, andConvivaContentInfo: convivaMetadata)
    }
    
    func attachHOOQlayerToSession(avplayer:AVPlayer) -> Void {
        if avplayer.isKind(of: AVPlayer.self) {
            if self.session != nil {
                self.session.attachStreamer(avplayer)
            } else {
                print("no Conviva Session")
            }
            //if (avplayer.conforms(to: ConvivaProxyFactory.self)) {
            
            //}
        } else {
            print("AVPlayer error")
        }
    }
    
    func reportHQPlayerError(errorString:String) -> Void {
        if (self.session != nil) {
            self.session.reportError(errorString, errorType:ErrorSeverity(rawValue: 0)!)
            self.clearConvivaSessionAndMetaData()
        }
    }
    
    func clearConvivaSessionAndMetaData() -> Void {
        if (self.session != nil) {
            self.session.cleanup()
            self.session = nil
        }
    }
    
    func clearConvivaSession() -> Void {
        if self.session != nil {
            LivePass.cleanupSession(self.session)
            self.session = nil
        }
    }
}
