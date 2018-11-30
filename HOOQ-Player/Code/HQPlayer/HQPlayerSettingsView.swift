//
//  HQPlayerSettingsView.swift
//  MiniHooq
//
//  Created by Rohan Chalana on 28/6/18.
//  Copyright © 2018 Rohan Chalana. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol HQPlayerSettingsViewProtocol: class {
    func doneButton(_ view: HQPlayerSettingsView)
    func didSelectRow(at index: Int,
                      of type: HQAssetOption,
                      tableView: UITableView,
                      view: HQPlayerSettingsView)
}

final class HQPlayerSettingsView: UIView {
    
    private lazy var audioOptionTableView = HQPlayerOptionView(optionType: .audioTrack(settingsModel.audioArray),
                                                               selectedIndex: settingsModel.audioSelectedIndex)
    private lazy var subtitleOptionTableView = HQPlayerOptionView(optionType: .textTrack(settingsModel.subtitleArray),
                                                                  selectedIndex: settingsModel.subtitleSelectedIndex)

    private let disposeBag = DisposeBag()
    
    weak var delegate: HQPlayerSettingsViewProtocol?
    
    private var settingsModel: HQPlayerSettingsViewModel
    private let sepratorView = UIView()
    
    private let doneButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor(red: 18/255.0, green: 18/255.0, blue: 18/255.0, alpha: 1.0)
        button.setTitle("Done", for: .normal)
        return button
    }()
    
    init(with model: HQPlayerSettingsViewModel,
         frame: CGRect = .zero) {
        settingsModel = model
        super.init(frame: frame)
        backgroundColor = UIColor(red: 30/255.0, green: 30/255.0, blue: 30/255.0, alpha: 1.0)
        alpha = 0.85
        audioOptionTableView.delegate = self
        subtitleOptionTableView.delegate = self
        setupView()
        setupConstraints()
        addEventHandlers()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension HQPlayerSettingsView {
    
    private func setupView() {
        sepratorView.backgroundColor = .white
        sepratorView.alpha = 0.08
        addSubview(subtitleOptionTableView)
        addSubview(audioOptionTableView)
        addSubview(sepratorView)
        addSubview(doneButton)
    }
    
    private func setupConstraints() {
        subtitleOptionTableView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(60)
            make.right.equalToSuperview().offset(-60)
            make.width.bottom.equalTo(audioOptionTableView)
        }
        
        sepratorView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalTo(doneButton.snp.top)
            make.width.equalTo(1)
            make.right.equalTo(subtitleOptionTableView.snp.left).offset(-60)
            make.left.equalTo(audioOptionTableView.snp.right).offset(60)
        }
        
        audioOptionTableView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(60)
            make.left.equalToSuperview().offset(60)
            make.bottom.equalTo(doneButton.snp.top)
        }
        
        doneButton.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(60)
        }
    }
    
    private func addEventHandlers() {
        doneButton.rx.tap.subscribe({ [weak self] _ in
            guard let `self` = self else { return }
            self.delegate?.doneButton(self)
        }).disposed(by: disposeBag)
    }
}

extension HQPlayerSettingsView: HQPlayerOptionViewProtocol {
    func didSelectRow(at index: Int,
                      of type: HQAssetOption,
                      tableView: UITableView,
                      view: HQPlayerOptionView) {
        delegate?.didSelectRow(at: index,
                               of: type,
                               tableView: tableView,
                               view: self)
    }
}
