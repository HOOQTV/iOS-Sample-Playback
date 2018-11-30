//
//  AVPlayerItemExtension.swift
//  HOOQ-Player
//
//  Created by Rohan Chalana on 24/7/18.
//  Copyright © 2018 HOOQ. All rights reserved.
//

import Foundation
import AVKit

extension AVPlayerItem {
    enum TrackType {
        case subtitle
        case audio
        fileprivate func characteristic(item: AVPlayerItem) -> AVMediaSelectionGroup?  {
            let str = self == .subtitle ? AVMediaCharacteristic.legible : AVMediaCharacteristic.audible
            if item.asset.availableMediaCharacteristicsWithMediaSelectionOptions.contains(str) {
                return item.asset.mediaSelectionGroup(forMediaCharacteristic: str)
            }
            return nil
        }
    }
          
    func tracks(type: TrackType) -> [String] {
        if let characteristic = type.characteristic(item: self) {
            return characteristic.options.map { $0.displayName }
        }
        return [String]()
    }
    
    func audiotracks() -> [HQAudioTrack] {
        var audioTrack = [HQAudioTrack]()
        if let characteristic = TrackType.audio.characteristic(item: self) {
            for option in characteristic.options {
                let audio = HQAudioTrack(name: option.displayName, locale: option.locale)
                audioTrack.append(audio)
            }
        }
        return audioTrack
    }
    
    func selected(type: TrackType) -> String? {
        guard let group = type.characteristic(item: self) else { return nil }
        let selected = selectedMediaOption(in: group)
        return selected?.displayName
    }
    
    func select(type:TrackType, name: String) {
        guard let group = type.characteristic(item: self) else { return }
        guard let matched = group.options.filter({ $0.displayName == name }).first else { return }
        select(matched, in: group)
    }
    
    func select(type:TrackType, locale: Locale) {
        guard let group = type.characteristic(item: self) else { return }
        guard let matched = group.options.filter({ $0.locale == locale }).first else { return }
        select(matched, in: group)
    }
    
    func selectDefault(type: TrackType) {
        guard let group = type.characteristic(item: self) else { return }
        select(nil, in: group)
    }
}
