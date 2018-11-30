//
//  HQPlayFooterView.swift
//  HOOQ-Player
//
//  Created by Rohan Chalana on 6/8/18.
//  Copyright © 2018 HOOQ. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import SnapKit

protocol HQPlayFooterViewProtocol: class {
    func playPauseButtonTap(_ view: HQPlayFooterView)
    func forwardButtonTap(_ view: HQPlayFooterView)
    func rewindButtonTap(_ view: HQPlayFooterView)
    func sliderSeek(to value: Variable<Float>,_ view: HQPlayFooterView)
}

struct HQPlayFooterViewModel {
    var seekBarCurrentValue: Variable<Float>
    var seekBarMaxValue: Float
    var remainingTime: Variable<Float>
    var currentTime: Variable<Float>
    init(with seekBarInitialValue: Variable<Float>,
         seekBarMaxValue: Float,
         remainingTime: Variable<Float>,
         currentTime: Variable<Float> = Variable(Float(0.0))) {
        self.seekBarMaxValue = seekBarMaxValue
        self.remainingTime = remainingTime
        self.currentTime = currentTime
        seekBarCurrentValue = seekBarInitialValue
    }
}

final class HQPlayFooterView: UIView {
    
    private let timeRemainLabel = UILabel(withFrame: .zero)
    
    private var currentTimeLabel: UILabel?
    
    private let playPauseButton = UIButton(withImage: "HQPauseIcon")
    private let forwardButton = UIButton(withImage: "HQForward15Icon")
    private let rewindButton = UIButton(withImage: "HQRewind15Icon")
    private let slider = HQPlayerSlider()
    private let disposeBag = DisposeBag()
    private let viewModel: HQPlayFooterViewModel
    weak var delegate: HQPlayFooterViewProtocol?
    
    init(with model: HQPlayFooterViewModel) {
        viewModel = model
        super.init(frame: .zero)
        backgroundColor = .black
        alpha = 0.4
        setupView()
        setupConstraints()
        addEventHandlers()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


extension HQPlayFooterView {
    
    private func setupView() {
        addSubview(playPauseButton)
        addSubview(forwardButton)
        addSubview(rewindButton)
        addSubview(timeRemainLabel)
        addSubview(slider)
        slider.addTarget(self, action: #selector(dragInprogress), for: .touchDragInside)
        slider.addTarget(self, action: #selector(dragExit), for: .touchCancel)
        slider.minimumTrackTintColor = UIColor.init(red: 179/255, green: 37/255, blue: 156/255, alpha: 1)
        slider.maximumTrackTintColor = UIColor.init(red: 190/255, green: 190/255, blue: 190/255, alpha: 1)
    }
    
    @objc func dragInprogress(){
        guard let timeLabel = currentTimeLabel else {
            setupSliderLabel()
            return
        }
        timeLabel.isHidden = false
    }
    
    @objc func dragExit(){
        currentTimeLabel?.isHidden = true
    }
    
    private func setupSliderLabel() {
        if let handleView = slider.subviews.last as? UIImageView {
            let label = UILabel(withFrame: handleView.bounds)
            label.backgroundColor = .black
            handleView.addSubview(label)
            label.snp.makeConstraints { make in
                make.bottom.equalTo(handleView.snp.top)
                make.centerX.equalTo(handleView)
            }
            self.currentTimeLabel = label
        }
        currentTimeLabel?.isHidden = true
        if let currentTimeLabel = self.currentTimeLabel {
            viewModel.currentTime.asObservable()
                .map{[unowned self] in self.timeString(seconds: $0) }
                .bind(to: currentTimeLabel.rx.text)
                .disposed(by: disposeBag)
        }
    }
    
    private func setupConstraints() {
        rewindButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(24)
            make.centerY.height.bottom.equalTo(playPauseButton)
        }
        
        playPauseButton.snp.makeConstraints { make in
            make.left.equalTo(rewindButton.snp.right).offset(24)
            make.bottom.equalToSuperview().offset(-24)
        }
        
        timeRemainLabel.snp.makeConstraints { make in
            make.centerY.equalTo(playPauseButton)
            make.width.equalTo(50)
            make.right.equalToSuperview().offset(-24)
        }
        
        slider.snp.makeConstraints { make in
            make.centerY.equalTo(playPauseButton)
            make.right.equalTo(timeRemainLabel.snp.left).offset(-24)
            make.left.equalTo(forwardButton.snp.right).offset(24)
        }
        
        forwardButton.snp.makeConstraints { make in
            make.left.equalTo(playPauseButton.snp.right).offset(24)
            make.height.centerY.bottom.equalTo(playPauseButton)
        }
    }
    
    private func addEventHandlers() {
        playPauseButton.rx.tap.subscribe({ [weak self] _ in
            guard let `self` = self else { return }
            self.delegate?.playPauseButtonTap(self)
        }).disposed(by: disposeBag)
        forwardButton.rx.tap.subscribe({ [weak self] _ in
            guard let `self` = self else { return }
            self.delegate?.forwardButtonTap(self)
        }).disposed(by: disposeBag)
        rewindButton.rx.tap.subscribe({ [weak self] _ in
            guard let `self` = self else { return }
            self.delegate?.rewindButtonTap(self)
        }).disposed(by: disposeBag)
        slider.rx.value
            .subscribe(onNext: { [weak self] (value) in
                guard let `self` = self else { return }
                self.currentTimeLabel?.isHidden = true
                self.delegate?.sliderSeek(to: self.viewModel.currentTime, self)
            }).disposed(by: disposeBag)
        slider.rx.value
            .bind(to: viewModel.seekBarCurrentValue)
            .disposed(by: disposeBag)
        slider.rx.value
            .map {[unowned self] in $0 * self.viewModel.seekBarMaxValue}
            .bind(to: viewModel.currentTime)
            .disposed(by: disposeBag)
        viewModel.seekBarCurrentValue.asObservable()
            .bind(to: slider.rx.value)
            .disposed(by: disposeBag)
        viewModel.remainingTime.asObservable()
            .map{[unowned self] in self.timeString(seconds: $0)}
            .bind(to: timeRemainLabel.rx.text)
            .disposed(by: disposeBag)
    }
}

extension HQPlayFooterView {
    func updatePayerState(with state: HQPlayerViewController.PlayerState) {
        let image = state != .play ? UIImage(named: "HQPlayIcon") : UIImage(named: "HQPauseIcon")
        playPauseButton.setImage(image, for: .normal)
    }
    
    private func timeString(seconds: Float) -> String {
        if seconds.isNaN {
            return "00:00"
        }
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        let seconds = Int((seconds.truncatingRemainder(dividingBy: 3600)).truncatingRemainder(dividingBy: 60))
        var timeRemainingString = String(format: "%02ld", seconds)
            timeRemainingString = String(format: "%02ld:", minutes) + timeRemainingString
        if hours > 0 {
            timeRemainingString = "\(hours):" + timeRemainingString
        }
        return timeRemainingString
    }
}

private extension UIButton {
    convenience init(withImage imageName: String) {
        self.init()
        let image = UIImage(named: imageName)
        backgroundColor = .clear
        setImage(image, for: .normal)
    }
}

private extension UILabel {
    convenience init(withFrame frame: CGRect) {
        self.init(frame: frame)
        textAlignment = .center
        textColor = .white
        text = "00:00"
        font = font.withSize(15)
    }
}
