//
//  SubtitleModel.swift
//  MiniHooq
//
//  Created by Rohan Chalana on 28/6/18.
//  Copyright © 2018 Rohan Chalana. All rights reserved.
//

import Foundation
import AVKit
import Freddy

enum HQAssetOption {
    case textTrack([HQTextTrack])
    case audioTrack([HQAudioTrack])
    case quality([HQAudioTrack])
}

struct HQTextTrack: JSONDecodable {
    let name: String
    let lang: String
    let uri: String
    
    public init(json value: JSON) throws {
        name = try value.getString(at: "name")
        lang = try value.getString(at: "lang")
        uri = try value.getString(at: "uri")
    }
}

struct HQAudioTrack {
    let name: String
    let locale: Locale?
}

struct HQVideoItem: JSONDecodable {
    let textTrack: [HQTextTrack]
    let license: String
    let content: String
    var title: String?
    let preroll: String
    let certificate: String
    var audioTrack: [HQAudioTrack]?
    
    public init(json value: JSON) throws {
        license = try value.getString(at: "license")
        content = try value.getString(at: "content")
        preroll = try value.getString(at: "preroll")
        certificate = try value.getString(at: "certificate")
        textTrack = try value.getArray(at: "textTracks", "webvtt").map(HQTextTrack.init)
    }
}
