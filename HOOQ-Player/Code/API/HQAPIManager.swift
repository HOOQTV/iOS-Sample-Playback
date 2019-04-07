//
//  HQWebServiceManager.swift
//  HOOQ-Player
//
//  Created by Vishal Adatia on 21/6/18.
//  Copyright © 2018 HOOQ. All rights reserved.
//

import UIKit

typealias HQServiceResponseBlock = (Any) -> Void

class HQAPIManager {
    
    var onCompBlock:HQServiceResponseBlock?
    var onFailBlock:HQServiceResponseBlock?
    
    private static var sharedAPIManager: HQAPIManager = {
        let apiManager = HQAPIManager.init(baseURL: NSURL.fileURL(withPath: Constants.APIURL.NIGHTLY_URL))
        return apiManager
    }()
    
    // MARK: -
    let baseURL: URL
    let deviceid = UIDevice.current.identifierForVendor?.uuidString
    let systemVersion = UIDevice.current.systemVersion
    let deviceModel = UIDevice.current.name
    
    // Initialization
    private init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    // MARK: - Accessors
    class func shared() -> HQAPIManager {
        return sharedAPIManager
    }
}

/**
 General Request Header
 */
extension HQAPIManager {
    func upateAPIHeader(request:NSMutableURLRequest) -> NSMutableURLRequest {
        
        request.addValue(Constants.RequestHeader.CachePolicy, forHTTPHeaderField: "Cache-Control")
        request.addValue(deviceid!, forHTTPHeaderField: "x-device-id")
        request.addValue(Constants.RequestHeader.PostmanToken, forHTTPHeaderField: "Postman-Token")
        request.addValue(Constants.RequestHeader.ApiKey, forHTTPHeaderField: "apikey")
        request.addValue(systemVersion, forHTTPHeaderField: "x-device-os-version")
        request.addValue(deviceModel, forHTTPHeaderField: "x-device-model")
        request.addValue(Constants.RequestHeader.DeviceType, forHTTPHeaderField: "x-device-type")
        request.addValue(Constants.RequestHeader.DrmType, forHTTPHeaderField: "x-dhs-drm")
        request.addValue("ios", forHTTPHeaderField: "x-device-os")
        return request
    }
    
    func signAPIHeader(request:NSMutableURLRequest) -> NSMutableURLRequest {
        request.addValue(Constants.RequestHeader.ContentType, forHTTPHeaderField: "Content-Type")
        request.addValue(Constants.RequestHeader.PostmanToken, forHTTPHeaderField: "Postman-Token")
        request.addValue(Constants.RequestHeader.ConsumerCustom, forHTTPHeaderField: "X-Consumer-Custom-ID")
        request.addValue(Constants.RequestHeader.Username, forHTTPHeaderField: "X-Consumer-Username")
        request.addValue(Constants.RequestHeader.ApiKey, forHTTPHeaderField: "apikey")
        request.addValue(Constants.RequestHeader.CachePolicy, forHTTPHeaderField: "Cache-Control")
        return request
    }
}

extension HQAPIManager {
    
    func signInAPI(with username: String, onCompletionBlock:@escaping HQServiceResponseBlock, onFailure:@escaping HQServiceResponseBlock) -> Void {
        let urlString:String = String(format: "%@/%@/user/signin",Constants.APIURL.SANDBOX_URL,Constants.VersionSupport.Version)
        //let urlString:String = "https://api-nightly.hooq.tv/2.0/user/signin"
        print("URL = \(urlString)")
        var request = NSMutableURLRequest(url: NSURL(string: urlString)! as URL)
        let session = URLSession.shared
        let deviceInfo = ["serialNo": "DEFAULT", //c0befd3745203f3af5eb0737fc6aa205
                          "name": "DEFAULT",
                          "type": "DEFAULT",
                          "brand": "DEFAULT",
                          "modelNo": "DEFAULT",
                          "os": "DEFAULT",
                          "osVersion": "DEFAULT"]
        let requestData : NSMutableDictionary = NSMutableDictionary.init()
        let parameters: [String : Any] = ["email": username,
                          "device": deviceInfo]
        //"ipAddress": "139.228.188.138",
        //"meta": ["hmac": "bypass"]
        let meta = ["hmac": "Key10|LSz4IFHuplrJZaEK1yAQlBbzbZk16Ir35aQa1Ue/NJU="] //hmac calculation is failing, so it's hard coded
        requestData.setValue(parameters, forKey: "data")
        requestData.setValue(meta, forKey: "meta")
        
        print("requestData = \(requestData)")

        let jsonData = try! JSONSerialization.data(withJSONObject: requestData, options: JSONSerialization.WritingOptions.prettyPrinted)
        
//        let result = UserDefaults.standard.value(forKey: "AuthorizationToken")
//        if result != nil {
//            let authorizationValie:String = String(format: "Bearer %@",UserDefaults.standard.value(forKey: "AuthorizationToken") as! CVarArg)
//            request.addValue(authorizationValie, forHTTPHeaderField: "Authorization")
//        } else {
//            request.addValue("Bearer ", forHTTPHeaderField: "Authorization")
//        }
        
        request = signAPIHeader(request: request)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        self.onCompBlock = onCompletionBlock
        self.onFailBlock = onFailure
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            if let data = data {
                let json = try? JSONSerialization.jsonObject(with: data, options: [])
                if let response = response as? HTTPURLResponse , 200...299 ~= response.statusCode {
                    let data:NSDictionary = json as! NSDictionary
                    self.onCompBlock!(data)
                } else {
                    self.onFailBlock!(data)
                }
            }
        })
        task.resume()
    }

    
    func callTokenAPI(onCompletionBlock:@escaping HQServiceResponseBlock, onFailure:@escaping HQServiceResponseBlock) -> Void {
        
        let urlString:String = String(format: "%@/%@/user/token/refresh",Constants.APIURL.SANDBOX_URL,Constants.VersionSupport.Version)
        //let urlString:String = "http://api-nightly.hooq.tv/2.0/user/token/refresh"
        var request = NSMutableURLRequest(url: NSURL(string: urlString)! as URL)
        let session = URLSession.shared
        
        let requestData : NSMutableDictionary = NSMutableDictionary.init()
        let token = UserDefaults.standard.value(forKey: "RefreshToken")
        let parameters = ["refreshToken": token, "ipAddress": "27.34.240.0"]
        requestData.setValue(parameters, forKey: "data")
        let jsonData = try! JSONSerialization.data(withJSONObject: requestData, options: JSONSerialization.WritingOptions.prettyPrinted)
        
        let result = UserDefaults.standard.value(forKey: "AuthorizationToken")
        if result != nil {
            let authorizationValie:String = String(format: "Bearer %@",UserDefaults.standard.value(forKey: "AuthorizationToken") as! CVarArg)
            request.addValue(authorizationValie, forHTTPHeaderField: "Authorization")
        } else {
            request.addValue("Bearer ", forHTTPHeaderField: "Authorization")
        }
        
        request = self.upateAPIHeader(request: request)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        self.onCompBlock = onCompletionBlock
        self.onFailBlock = onFailure
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            if let data = data {
                let json = try? JSONSerialization.jsonObject(with: data, options: [])
                if let response = response as? HTTPURLResponse , 200...299 ~= response.statusCode {
                    let data:NSDictionary = json as! NSDictionary
                    self.onCompBlock!(data)
                } else {
                    self.onFailBlock!(data)
                }
            }
        })
        task.resume()
    }
}

/**
 PLAY API Request
 */
extension HQAPIManager {
    
    func callNativePlayAPI(contentId:String,
                           onCompletionBlock:@escaping HQServiceResponseBlock,
                           onFailure:@escaping HQServiceResponseBlock) -> Void {
        let urlString:String = String(format: "%@/%@/play/%@",Constants.APIURL.SANDBOX_URL,Constants.VersionSupport.Version,contentId)
        //let urlString = String(format: "http:/api-nightly.hooq.tv/2.0/play/%@",contentId)
        var request = NSMutableURLRequest(url: NSURL(string: urlString)! as URL)
        let session = URLSession.shared
        
        let result = UserDefaults.standard.value(forKey: "AuthorizationToken") as! String
        let authorizationValie:String = String(format: "Bearer %@",result)
        request.addValue(authorizationValie, forHTTPHeaderField: "Authorization")
        request = self.upateAPIHeader(request: request)
        request.httpMethod = "GET"
        
        self.onCompBlock = onCompletionBlock
        self.onFailBlock = onFailure
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            if let data = data {
                let json = try? JSONSerialization.jsonObject(with: data, options: [])
                if let response = response as? HTTPURLResponse , 200...299 ~= response.statusCode {
                    let data:NSDictionary = json as! NSDictionary
                    self.onCompBlock!(data)
                } else {
                    let data:NSDictionary = json as! NSDictionary
                    self.onFailBlock!(data)
                }
            }
        })
        task.resume()
    }
}

/**
 PLAY API Request
 */
extension HQAPIManager {
    
    func callPlayHeartBeatAPI(contentId: String,
                              contentTime: TimeInterval,
                              currentPlayTime:TimeInterval, onCompletionBlock:@escaping HQServiceResponseBlock,
                              onFailure:@escaping HQServiceResponseBlock) -> Void {
        
        let urlString:String = String(format: "%@/%@/play/%@",Constants.APIURL.SANDBOX_URL,Constants.VersionSupport.Version,contentId)
        //let urlString:String = String(format: "http:/api-nightly.hooq.tv/2.0/play/%@",contentId)
        var request = NSMutableURLRequest(url: NSURL(string: urlString)! as URL)
        let session = URLSession.shared
        
        //NSDictionary to NSData
        let requestData:NSDictionary = NSMutableDictionary.init()
        //requestData.setValue(NSNumber.init(value: round(currentPlayTime)), forKey: "position")
        //requestData.setValue(NSNumber.init(value: round(contentTime)), forKey: "length")
        requestData.setValue(round(currentPlayTime), forKey: "position")
        requestData.setValue(round(contentTime), forKey: "length")
        requestData.setValue("", forKey: "nextEpisodeId")
        let jsonData = try! JSONSerialization.data(withJSONObject: requestData, options: JSONSerialization.WritingOptions.prettyPrinted)        
        //let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)! as String

        /////////////
        
        let result:String = UserDefaults.standard.value(forKey: "AuthorizationToken") as! String
        let authorizationValie:String = String(format: "Bearer %@",result)
        request.addValue(authorizationValie, forHTTPHeaderField: "Authorization")
        request = self.upateAPIHeader(request: request)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        self.onCompBlock = onCompletionBlock
        self.onFailBlock = onFailure
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            if let data = data {
                let json = try? JSONSerialization.jsonObject(with: data, options: [])
                if let response = response as? HTTPURLResponse , 200...299 ~= response.statusCode {
                    let data:NSDictionary = json as! NSDictionary
                    self.onCompBlock!(data)
                } else {
                    let data:NSDictionary = json as! NSDictionary
                    self.onFailBlock!(data)
                }
            }
        })
        task.resume()
    }
}
