//
//  HQPlayerSettingsViewModel.swift
//  HOOQ-Player
//
//  Created by Rohan Chalana on 1/8/18.
//  Copyright © 2018 HOOQ. All rights reserved.
//

import Foundation

struct HQPlayerSettingsViewModel {
    var subtitleArray: [HQTextTrack]
    var audioArray: [HQAudioTrack]
    var audioSelectedIndex: Int
    var subtitleSelectedIndex: Int

    init(with subtitleList: [HQTextTrack],
         audioList: [HQAudioTrack],
         audioSelectedIndex: Int = 0,
         subtitleSelectedIndex: Int = -1) {
        self.audioSelectedIndex = audioSelectedIndex
        self.subtitleSelectedIndex = subtitleSelectedIndex
        audioArray = audioList
        subtitleArray = subtitleList
    }
}
