//
//  HQPlayerViewControler.swift
//  HOOQ-Player
//
//  Created by Rohan Chalana on 25/7/18.
//  Copyright © 2018 HOOQ. All rights reserved.
//

import Foundation
import AVKit
import Freddy
import UIKit
import RxSwift
import RxAVFoundation

final class HQPlayerViewController: AVPlayerViewController {
    enum PlayerState {
        case play
        case pause
    }
    
    private var videoItem: HQVideoItem
    private lazy var headerView = HQPlayHeaderView(with: HQPlayHeaderViewModel(title: videoItem.title))
    private var footerView: HQPlayFooterView?
    private lazy var model = HQPlayerSettingsViewModel(with: videoItem.textTrack, audioList: videoItem.audioTrack!)
    private var currentPlayerState: PlayerState = .play
    private let disposeBag = DisposeBag()
    
    fileprivate let hooqPlayerConvivaManager = HQPlayerConvivaManager.shared
    
    private var heartBeatTimer = Timer()
    let videoContentId: String = ""
    
    init(_ videoItem: HQVideoItem) {
            self.videoItem = videoItem
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showsPlaybackControls = false
        initializePlayer()
        stubAudioTrack()
        setupHeaderViews()
        startHeartBeat()
        startPlayer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        setupControlView()
        player?.currentItem?.selectDefault(type: .audio)
        player?.currentItem?.selectDefault(type: .subtitle)
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeLeft
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(NSNotification.Name.AVPlayerItemDidPlayToEndTime)
        stopHeartBeatTimer()
        stopPlayer()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension HQPlayerViewController {
    private func setupControlView() {
        setupHeaderViews()
        createFooterView()
        setupFooterViews()
    }
    
    private func setupHeaderViews() {
        headerView.delegate = self
        contentOverlayView?.addSubview(headerView)
        headerView.becomeFirstResponder()
        headerView.snp.makeConstraints { make in
            make.top.right.left.equalToSuperview()
            make.height.equalTo(80)
        }
    }
    
    private func setupFooterViews() {
        footerView?.delegate = self
        contentOverlayView?.addSubview(footerView!)
        footerView?.becomeFirstResponder()
        footerView?.snp.makeConstraints { make in
            make.bottom.right.left.equalToSuperview()
            make.height.equalTo(80)
        }
    }
    
    private func addSettingView() {
        let settingsView = HQPlayerSettingsView(with: model)
        contentOverlayView?.addSubview(settingsView)
        settingsView.delegate = self
        settingsView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension HQPlayerViewController {
    private func stubAudioTrack() {
        let tracks = player?.currentItem?.audiotracks()
        videoItem.audioTrack = tracks
    }
    
    private func stopPlayer()  {
        player?.replaceCurrentItem(with: nil)
        player?.rate = 0.0
        hooqPlayerConvivaManager.clearConvivaSession()
    }
    
    private func initializePlayer() {
        guard let url = URL(string: videoItem.content) else { return }
        let asset = AVURLAsset(url: url)
        print("asset URL = \(url)")
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer.init(playerItem: playerItem)
        asset.resourceLoader.setDelegate(self, queue: DispatchQueue.main)
        NotificationCenter.default.addObserver(self, selector: #selector(finishVideo),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: nil)
    }
    
    @objc func finishVideo() {
        dismiss(animated: true, completion: nil)
    }
    
    private func createFooterView() {
        guard let cmTime = player?.currentItem?.duration else { return }
        let floatTime = Float(CMTimeGetSeconds(cmTime))
        let val = Variable(Float(0.0))
        let val2 = Variable(Float(cmTime.seconds))

        let model = HQPlayFooterViewModel(with: val, seekBarMaxValue: floatTime, remainingTime: val2)
        footerView = HQPlayFooterView(with: model)
        guard let item = player?.currentItem else { return }
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.rx.periodicTimeObserver(interval: interval)
            .map { [unowned self] in self.progress(currentTime: $0, duration: item.duration) }
            .bind(to: model.seekBarCurrentValue)
            .disposed(by: disposeBag)
        player?.rx.periodicTimeObserver(interval: interval)
            .map {Float($0.seconds)}
            .bind(to: model.currentTime)
            .disposed(by: disposeBag)
        player?.rx.periodicTimeObserver(interval: interval)
            .map { [unowned self] in self.timeRemaining(currentTime: $0, duration: item.duration) }
            .bind(to: model.remainingTime)
            .disposed(by: disposeBag)
    }
    
    private func timeRemaining(currentTime: CMTime, duration: CMTime) -> Float {
        if !duration.isValid || !currentTime.isValid {
            return 0
        }        
        let totalSeconds = duration.seconds
        let currentSeconds = currentTime.seconds
        if !totalSeconds.isFinite || !currentSeconds.isFinite {
            return 0
        }
        let p = totalSeconds - currentSeconds
        return Float(p)
    }
    
    private func progress(currentTime: CMTime, duration: CMTime) -> Float {
        if !duration.isValid || !currentTime.isValid {
            return 0
        }
        let totalSeconds = duration.seconds
        let currentSeconds = currentTime.seconds
        if !totalSeconds.isFinite || !currentSeconds.isFinite {
            return 0
        }
        let p = Float(currentSeconds/totalSeconds)
        return p
    }


    private func startPlayer()  {
        if let player = player {
            hooqPlayerConvivaManager.attachHOOQlayerToSession(avplayer: player)
            currentPlayerState = .play
            player.play()
        }
    }
    
    private func pauseVideo()  {
        currentPlayerState = .pause
        player?.pause()
        self.stopHeartBeatTimer()
    }
    
    private func resumeVideo()  {
        currentPlayerState = .play
        player?.play()
        self.startHeartBeat()
    }
}

extension HQPlayerViewController {
    private func updateSelectedAudioTrack() {
        guard let audioTracks = videoItem.audioTrack,
            let item = player?.currentItem else { return }
        let audioTrack = audioTracks[model.audioSelectedIndex]
        if let locale = audioTrack.locale {
            item.select(type: .audio, locale: locale)
        } else {
            item.select(type: .audio, name: audioTrack.name)
        }
    }
    
    private func updateSelectedSubtitleTrack() {
        guard let item = player?.currentItem else { return }
        if model.subtitleSelectedIndex < 0 {
            item.selectDefault(type: .subtitle)
        } else {
            let name = videoItem.textTrack[model.subtitleSelectedIndex].name
            item.select(type: .subtitle, name: name)
        }
    }
}

extension HQPlayerViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touchesBegan")
    }
}

extension HQPlayerViewController: HQPlayHeaderViewProtocol {
    func doneButton(_ view: HQPlayerSettingsView) {
        updateSelectedSubtitleTrack()
        updateSelectedAudioTrack()
        player?.play()
        view.removeFromSuperview()
        headerView.isHidden = false
    }

    func captionButtonTap(_ view: HQPlayHeaderView) {
        headerView.isHidden = true
        player?.pause()
        addSettingView()
    }

    func backButtonTap(_ view: HQPlayHeaderView) {
        dismiss(animated: true, completion: nil)
    }
}


extension HQPlayerViewController: HQPlayFooterViewProtocol {
    
    func sliderSeek(to value: Variable<Float>,
                    _ view: HQPlayFooterView) {
        player?.seek(to: value.value)
    }
    
    func playPauseButtonTap(_ view: HQPlayFooterView) {
        switch currentPlayerState {
        case .pause:
            resumeVideo()
        case .play:
            pauseVideo()
        }
        footerView?.updatePayerState(with: currentPlayerState)
    }
    
    func forwardButtonTap(_ view: HQPlayFooterView) {
        player?.forward()
    }
    
    func rewindButtonTap(_ view: HQPlayFooterView) {
        player?.rewind()
    }
}

extension HQPlayerViewController: HQPlayerSettingsViewProtocol {
    func didSelectRow(at index: Int, of type: HQAssetOption, tableView: UITableView, view: HQPlayerSettingsView) {
        print("DIDSELECT")
        switch type {
        case .audioTrack:
            model.audioSelectedIndex = index
        case .textTrack:
            model.subtitleSelectedIndex = index - 1
        default:
            print("default")
        }
    }
}

extension HQPlayerViewController: AVAssetResourceLoaderDelegate {
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                        shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        // We first check if a url is set in the manifest.
        print("came here")
        guard let url = loadingRequest.request.url else {
            loadingRequest.finishLoading(with: NSError(domain: "HOOQ", code: -1, userInfo: nil))
            return false
        }
        print("🔑", #function, url)
        print("=================", url)
        
        let certificateURL = URL.init(string: "http://api-sandbox.hooq.tv/2.0/afp/certificate/Singtel-Fairplay.cer")!
        
        guard let certificateData = try? Data(contentsOf: certificateURL) else {
            print("🔑", #function, "Unable to read the certificate data.")
            loadingRequest.finishLoading(with: NSError(domain: "HOOQ", code: -2, userInfo: nil))
            return false
        }
        
        // Request the Server Playback Context.
        let contentId = url.absoluteString.replacingOccurrences(of: "skd://", with: "")
        guard let contentIdData = contentId.data(using: String.Encoding.utf8),
            let spcData = try? loadingRequest.streamingContentKeyRequestData(forApp: certificateData,
                                                                             contentIdentifier: contentIdData,
                                                                             options: nil),
            let dataRequest = loadingRequest.dataRequest else {
                loadingRequest.finishLoading(with: NSError(domain: "HOOQ", code: -3, userInfo: nil))
                print("🔑", #function, "Unable to read the SPC data.")
                return false
        }
        
        // Request the Content Key Context from the Key Server Module.
        guard let ckcURL = URL(string: videoItem.license as String) else { return false }
        var request = URLRequest(url: ckcURL)
        request.httpMethod = "POST"
        request.httpBody = spcData
        request.addValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        let session = URLSession(configuration: URLSessionConfiguration.default)
        let task = session.dataTask(with: request) { data, response, error in
            if let data = data {
                dataRequest.respond(with: data)
                loadingRequest.finishLoading()
            } else {
                print("🔑", #function, "Unable to fetch the CKC.")
                loadingRequest.finishLoading(with: NSError(domain: "HOOQ", code: -4, userInfo: nil))
            }
        }
        task.resume()
        return true
    }
}

/*
 Heart Beat Method
 */
extension HQPlayerViewController {
    
    func startHeartBeat() -> Void {
        heartBeatTimer.invalidate()
        heartBeatTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(callHeartBeatAPI), userInfo: nil, repeats: true)
    }
    
    func stopHeartBeatTimer() -> Void {
        heartBeatTimer.invalidate()
    }
    
    @objc func callHeartBeatAPI() -> Void {
        /// Call HeartBeat API
        let duration:CMTime = player!.currentItem!.asset.duration;
        let durationSeconds:Float = Float(CMTimeGetSeconds(duration));
        let durationTimeInterval = durationSeconds
        //print(durationSeconds)
        
        let currentTime:CMTime = player!.currentItem!.currentTime();
        let currentTimeSeconds:Float = Float(CMTimeGetSeconds(currentTime));
        let currentTimeInterval = currentTimeSeconds
        //print(currentTimeSeconds)
        
        HQAPIManager.shared().callPlayHeartBeatAPI(contentId: videoContentId, contentTime: TimeInterval(durationTimeInterval), currentPlayTime: TimeInterval(currentTimeInterval), onCompletionBlock: {        
            HQServiceResponseBlock -> Void in
            print("Success")
        }, onFailure: {
            HQServiceResponseBlock -> Void in
            print("Fail")
        })
    }
}
