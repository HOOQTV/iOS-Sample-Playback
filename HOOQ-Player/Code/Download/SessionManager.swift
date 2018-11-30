//
//  SessionManager.swift
//  HOOQ-Player
//
//  Created by Rohan Chalana on 11/7/18.
//  Copyright © 2018 HOOQ. All rights reserved.
//

import Foundation
import AVFoundation

final class SessionManager: NSObject, AVAssetDownloadDelegate {
    static let shared = SessionManager()
    
    internal let homeDirectoryURL = URL(fileURLWithPath: NSHomeDirectory())
    private var session: AVAssetDownloadURLSession!
    internal var downloadingMap = [AVAssetDownloadTask: Magic]()
    /*
     
     */
    override private init() {
        super.init()
        let configuration = URLSessionConfiguration.background(withIdentifier: "fps.configuration")
        session = AVAssetDownloadURLSession(configuration: configuration,
                                            assetDownloadDelegate: self,
                                            delegateQueue: OperationQueue.main)
        restoreDownloadsMap()
    }
    
    // MARK: Method
    
    private func restoreDownloadsMap() {
        session.getAllTasks { tasksArray in
            for task in tasksArray {
                guard let assetDownloadTask = task as? AVAssetDownloadTask,
                    let assetNamme = task.taskDescription else { break }
                
                let asset = Magic(asset: assetDownloadTask.urlAsset, description: assetNamme)
                self.downloadingMap[assetDownloadTask] = asset
            }
        }
    }
    
    func downloadStream(_ asset: Magic) {
        guard assetExists(forName: asset.name) == false else { return }
        
        guard let task = session.makeAssetDownloadTask(asset: asset.urlAsset,
                                                       assetTitle: asset.name,
                                                       assetArtworkData: nil,
                                                       options: nil) else { return }
        
        task.taskDescription = asset.name
        downloadingMap[task] = asset
        
        task.resume()
    }
    
    func cancelDownload(_ asset: Magic) {
        downloadingMap.first(where: { $1 == asset })?.key.cancel()
    }
    
    func deleteAsset(forName: String) throws {
        guard let relativePath = VideoStore.path(forName: forName) else { return }
        let localFileLocation = homeDirectoryURL.appendingPathComponent(relativePath)
        try FileManager.default.removeItem(at: localFileLocation)
        VideoStore.remove(forName: forName)
    }
    
    func assetExists(forName: String) -> Bool {
        guard let relativePath = VideoStore.path(forName: forName) else { return false }
        let filePath = homeDirectoryURL.appendingPathComponent(relativePath).path
        return FileManager.default.fileExists(atPath: filePath)
    }
    
    // MARK: AVAssetDownloadDelegate
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let task = task as? AVAssetDownloadTask,
            let asset = downloadingMap.removeValue(forKey: task) else { return }
        
        if let error = error as? NSError {
            switch (error.domain, error.code) {
            case (NSURLErrorDomain, NSURLErrorCancelled):
                guard let localFileLocation = VideoStore.path(forName: asset.name) else { return }
                do {
                    let fileURL = homeDirectoryURL.appendingPathComponent(localFileLocation)
                    try FileManager.default.removeItem(at: fileURL)
                } catch {
                    print("An error occured trying to delete the contents on disk for \(asset.name): \(error)")
                }
                
            case (NSURLErrorDomain, NSURLErrorUnknown):
                asset.result = .failure(error)
                fatalError("Downloading HLS streams is not supported in the simulator.")
                
            default:
                asset.result = .failure(error)
                print("An unexpected error occured \(error.domain)")
            }
        } else {
            asset.result = .success
        }
        switch asset.result! {
        case .success:
            asset.finishClosure?(VideoStore.path(forName: asset.name)!)
        case .failure(let err):
            asset.errorClosure?(err)
        }
    }
    
    func urlSession(_ session: URLSession,
                    assetDownloadTask: AVAssetDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let fps = downloadingMap[assetDownloadTask] else { return }
        VideoStore.set(path: location.relativePath, forName: fps.name)
    }
    
    func urlSession(_ session: URLSession,
                    assetDownloadTask: AVAssetDownloadTask,
                    didLoad timeRange: CMTimeRange,
                    totalTimeRangesLoaded loadedTimeRanges: [NSValue],
                    timeRangeExpectedToLoad: CMTimeRange) {
        guard let asset = downloadingMap[assetDownloadTask] else { return }
        asset.result = nil
        guard let progressClosure = asset.progressClosure else { return }
        
        let percentComplete = loadedTimeRanges.reduce(0.0) {
            let loadedTimeRange : CMTimeRange = $1.timeRangeValue
            return $0 + CMTimeGetSeconds(loadedTimeRange.duration) / CMTimeGetSeconds(timeRangeExpectedToLoad.duration)
        }
        
        progressClosure(percentComplete)
    }
}
