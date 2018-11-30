//
//  HQPlayHeaderView.swift
//  MiniHooq
//
//  Created by Rohan Chalana on 27/6/18.
//  Copyright © 2018 Rohan Chalana. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import SnapKit

protocol HQPlayHeaderViewProtocol: class {
    func captionButtonTap(_ view: HQPlayHeaderView)
    func backButtonTap(_ view: HQPlayHeaderView)
}

struct HQPlayHeaderViewModel {
    let title: String?
}

final class HQPlayHeaderView: UIView {
    
    private let captionButton = UIButton(withImage: "HQSubtitlesIcon")
    private let backButton = UIButton(withImage: "Icon_back")
    
    private lazy var tilteLabel: UILabel = {
        let tilteLabel = UILabel()
        tilteLabel.textAlignment = .left
        tilteLabel.textColor = .white
        tilteLabel.numberOfLines = 0
        tilteLabel.text = viewModel.title
        tilteLabel.font = tilteLabel.font.withSize(18)
        return tilteLabel
    }()

    private let disposeBag = DisposeBag()
    private let viewModel: HQPlayHeaderViewModel
    weak var delegate: HQPlayHeaderViewProtocol?
    
    init(with model: HQPlayHeaderViewModel) {
        viewModel = model
        super.init(frame: .zero)
        backgroundColor = .black
        alpha = 0.4
        setupView()
        setupConstraints()
        addEventHandlers()
    }
    
    private func setupView() {
        addSubview(captionButton)
        addSubview(tilteLabel)
        addSubview(backButton)
    }
    
    private func setupConstraints() {
        tilteLabel.snp.makeConstraints { make in
            make.left.equalTo(backButton.snp.right).offset(16)
            make.right.equalTo(captionButton.snp.left).offset(-16)
            make.centerY.equalTo(backButton)
        }
        
        captionButton.snp.makeConstraints { make in
            make.right.bottom.equalToSuperview().offset(-16)
            make.top.equalToSuperview().offset(16)
        }
        
        backButton.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.top.height.bottom.equalTo(captionButton)
        }
    }
    
    private func addEventHandlers() {
        captionButton.rx.tap.subscribe({ [weak self] _ in
            guard let `self` = self else { return }
            self.delegate?.captionButtonTap(self)
        }).disposed(by: disposeBag)
        backButton.rx.tap.subscribe({ [weak self] _ in
            guard let `self` = self else { return }
            self.delegate?.backButtonTap(self)
        }).disposed(by: disposeBag)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension UIButton {
    convenience init(withImage imageName: String) {
        self.init()
        let image = UIImage(named: imageName)
        backgroundColor = .clear
        setImage(image,
                 for: .normal)
    }
}
