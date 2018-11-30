//
//  VideoStore.swift
//  HOOQ-Player
//
//  Created by Rohan Chalana on 11/7/18.
//  Copyright © 2018 HOOQ. All rights reserved.
//

import Foundation

struct VideoStore {
    private static var shared: [String: String] = {
        if FileManager.default.fileExists(atPath: storeURL.path) {
            return NSDictionary(contentsOf: storeURL) as! [String : String]
        }
        return [:]
    }()
    
    private static let storeURL: URL = {
        let library = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
        return URL(fileURLWithPath: library).appendingPathComponent("VideoStore").appendingPathExtension("plist")
    }()
    
    static func allMap() -> [String: String] {
        return shared
    }
    
    static func path(forName: String) -> String? {
        if let path = shared[forName] {
            return path
        }
        return nil
    }
    
    @discardableResult
    static func set(path: String, forName: String) -> Bool {
        shared[forName] = path
        let dict = shared as NSDictionary
        return dict.write(to: storeURL, atomically: true)
    }
    
    @discardableResult
    static func remove(forName: String) -> Bool {
        guard let _ = shared.removeValue(forKey: forName) else { return false }
        let dict = shared as NSDictionary
        return dict.write(to: storeURL, atomically: true)
    }
}
