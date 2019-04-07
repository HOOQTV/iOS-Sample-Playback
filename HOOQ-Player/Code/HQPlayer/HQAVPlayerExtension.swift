//
//  HQAVPlayerExtension.swift
//  HOOQ-Player
//
//  Created by Rohan Chalana on 8/8/18.
//  Copyright © 2018 HOOQ. All rights reserved.
//

import Foundation
import AVKit

extension AVPlayer {
    func forward() {
        guard let duration  = currentItem?.duration else { return }
        let playerCurrentTime = CMTimeGetSeconds(currentTime())
        let newTime = playerCurrentTime + 15.00
        if newTime < CMTimeGetSeconds(duration) {
            let time2: CMTime = CMTimeMake(Int64(newTime * 1000 as Float64), 1000)
            seek(to: time2)
        }
    }
    
    func rewind() {
        guard let duration  = currentItem?.duration else { return }
        let playerCurrentTime = CMTimeGetSeconds(currentTime())
        let newTime = playerCurrentTime - 15.00
        if newTime < CMTimeGetSeconds(duration) {
            let time2: CMTime = CMTimeMake(Int64(newTime * 1000 as Float64), 1000)
            seek(to: time2)
        }
    }
    
    func seek(to value: Float) {
        if !(value.isNaN || value.isInfinite) {
            let cmTime = CMTimeMake(Int64(value * 1000), 1000)
            seek(to: cmTime)
        }
    }
}
