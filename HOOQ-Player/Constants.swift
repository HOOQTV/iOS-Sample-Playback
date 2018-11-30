//
//  Constants.swift
//  HOOQ-Player
//
//  Created by Rohan Chalana on 10/7/18.
//  Copyright © 2018 HOOQ. All rights reserved.
//

struct Constants {
    struct KEY {
        static let GATEWAY_URL = "gatewayUrl"
        static let CUSTOMER = "" // Conviva
        static let LICENSE = "LICENSE_KEY"
        static let MANIFEST = "MANIFEST_KEY"
        static let FAIRPLAY_CERT = "http://api-sandbox.hooq.tv/2.0/afp/certificate/Singtel-Fairplay.cer"
    }
    
    struct VALUE {
        static let GATEWAY_URL = "" //Conviva
    }
    
    
    struct APIURL {
        static let NIGHTLY_URL = "http://api-nightly.hooq.tv"
        static let SANDBOX_URL = "http://api-sandbox.hooq.tv"
    }
    
    struct VersionSupport {
        static let Version = "2.0"
    }

    struct RequestHeader {
        
        static let ApiKey = ""
        static let ContentType = "application/json"
        static let PostmanToken = "84f2c462-3836-4c95-b996-2a74df2b860b"
        static let ConsumerCustom = ""
        static let Username = ""
        static let DeviceType = "iOSMobile"
        static let DrmType = "HLS/FAIRPLAY"
        static let CachePolicy = "no-cache"
    }
}
