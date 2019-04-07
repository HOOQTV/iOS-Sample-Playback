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
        static let CUSTOMER = "b032d1138c0bcf37f920408a26af5b2338a38e3b" // Conviva
        static let LICENSE = "LICENSE_KEY"
        static let MANIFEST = "MANIFEST_KEY"
        static let FAIRPLAY_CERT = "http://api-sandbox.hooq.tv/2.0/afp/certificate/Singtel-Fairplay.cer"
    }
    
    struct VALUE {
        static let GATEWAY_URL = "https://hooq-vodafone-test.testonly.conviva.com" //Conviva
    }
    
    
    struct APIURL {
        static let NIGHTLY_URL = "https://api-nightly.hooq.tv"
        static let SANDBOX_URL = "https://api-sandbox.hooq.tv"
        static let PROD_URL = "https://api-prod.hooq.tv"
        static let DEFAULT_URL = "https://api.hooq.tv"
    }
    
    struct VersionSupport {
        static let Version = "2.0"
    }

    struct RequestHeader {
        
        static let ApiKey = "8Ht3nmI0F8mvPKVpvdQBDY7aHmsWFEkd"
        static let ContentType = "application/json"
        static let PostmanToken = "84f2c462-3836-4c95-b996-2a74df2b860b"
        static let ConsumerCustom = ""
        static let Username = ""
        static let DeviceType = "iOSMobile"
        static let DrmType = "HLS/FAIRPLAY"
        static let CachePolicy = "no-cache"
    }
}
