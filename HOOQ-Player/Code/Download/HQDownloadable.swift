//
//  HQDownloadable.swift
//  HOOQ-Player
//
//  Created by Rohan Chalana on 20/11/18.
//  Copyright © 2018 HOOQ. All rights reserved.
//

import Foundation
import AVFoundation
import AVKit


protocol HQDownloadableDelegate: class {
    func contendDownloading(completedPercentage: Double,
                            downloadable: HQDownloadable)
    func contendDownloadCompleted(_ downloadable: HQDownloadable)
}



class HQDownloadable {
    private var testMagic: Magic?
    weak var delegate: HQDownloadableDelegate?

    private func startDownload(url: String) {
        guard let url = URL(string: url) else { return }
        testMagic = Magic(url: url, name: "testvishal")
        switch testMagic?.state {
        case .downloaded?:
            print("Downloaded")
        case .notDownloaded?:
            self.startDownload(testMagic)
        case .downloading?:
            print("Downloading")
        case .none:
            print("none")
        }
    }
    
    private func startDownload(_ asset: Magic?) {
        testMagic?.download { (progressPercentage) in
            print("Download %",progressPercentage)
            self.delegate?.contendDownloading(completedPercentage: progressPercentage,
                                              downloadable: self)
            }.finish { (relativePath) in
                self.delegate?.contendDownloadCompleted(self)
        }
    }
    
    private func getDownloadedContent() -> AVPlayerItem? {
        guard let localUrl = testMagic?.localUrl else { return nil }
        let localAsset = AVURLAsset(url: localUrl)
        let playerItem = AVPlayerItem(asset: localAsset)
        return playerItem
    }
}
