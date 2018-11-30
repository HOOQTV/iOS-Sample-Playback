//
//  HQOptionView.swift
//  HOOQ-Player
//
//  Created by Rohan Chalana on 1/8/18.
//  Copyright © 2018 HOOQ. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

protocol HQPlayerOptionViewProtocol: class {
    func didSelectRow(at index: Int, of type: HQAssetOption, tableView: UITableView, view: HQPlayerOptionView)
}

final class HQPlayerOptionView: UIView {
    
    private var optionType: HQAssetOption
    private var selectedIndex: Int
    
    private let disposeBag = DisposeBag()
    
    weak var delegate: HQPlayerOptionViewProtocol?
    
    private lazy var optionTableView: UITableView = {
        let optionTableView = UITableView()
        optionTableView.delegate = self
        optionTableView.dataSource = self
        optionTableView.backgroundColor = .clear
        optionTableView.layoutMargins = UIEdgeInsets.zero
        optionTableView.separatorInset = UIEdgeInsets.zero
        optionTableView.separatorColor = UIColor(red: 255.0/255.0, green: 255.0/255.0, blue: 255.0/255.0, alpha: 0.08)
        optionTableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: optionTableView.frame.size.width, height: 1))
        return optionTableView
    }()
    
    private lazy var optionNameLabel: UILabel = {
        let optionNameLabel = UILabel()
        optionNameLabel.textAlignment = .center
        optionNameLabel.textColor = .white
        optionNameLabel.text = optionLableText
        optionNameLabel.font = optionNameLabel.font.withSize(15)
        return optionNameLabel
    }()
    
    private lazy var optionLableText: String = {
        switch optionType {
        case .textTrack:
            return "SUBTITLE"
        case .audioTrack:
            return  "AUDIO TRACK"
        case .quality:
            return "AUDIO QUALITY"
        }
    }()

    init(optionType: HQAssetOption, selectedIndex: Int) {
        self.selectedIndex = selectedIndex
        self.optionType = optionType
        super.init(frame: .zero)
        backgroundColor = .clear
        setupView()
        setupConstraints()
    }
    
    private func setupView() {
        addSubview(optionNameLabel)
        addSubview(optionTableView)
    }
    
    private func setupConstraints() {
        optionNameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalTo(optionTableView.snp.top).offset(-9)
            make.left.right.equalTo(optionTableView)
        }
        optionTableView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    private func setLocalIndex(with indexPath: IndexPath) {
        switch optionType {
        case .textTrack:
            selectedIndex = indexPath.row - 1
        case .audioTrack:
            selectedIndex = indexPath.row
        case .quality:
            selectedIndex = indexPath.row
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension HQPlayerOptionView: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch optionType {
        case .textTrack(let tracks):
            return tracks.count + 1
        case .audioTrack(let tracks):
            return tracks.count
        case .quality(let tracks):
            return tracks.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // TODO: custom cell
        var cell: UITableViewCell? = optionTableView.dequeueReusableCell(withIdentifier: "cellReuseIdentifier")
        if cell == nil {
            cell = UITableViewCell.init(style: UITableViewCellStyle.default, reuseIdentifier: "cellReuseIdentifier")
        }
        var index = indexPath.row
        switch optionType {
        case .textTrack(let track):
            index = indexPath.row - 1
            cell?.textLabel?.text = index < 0 ? "None" : track[index].name
        case .audioTrack(let track):
            cell?.textLabel?.text = track[index].name
        case .quality(let track):
            cell?.textLabel?.text = track[index].name
        }
        
        let colour = index == selectedIndex ?
            UIColor(red: 0/255.0, green: 172/255.0, blue: 169/255.0, alpha: 1.0) :
            UIColor(red: 155/255.0, green: 155/255.0, blue: 155/255.0, alpha: 1.0)

        cell?.backgroundColor = .clear
        cell?.textLabel?.textColor = colour
        cell?.textLabel?.textAlignment = .center
        cell?.selectionStyle = .none
        cell?.textLabel?.font = optionNameLabel.font.withSize(15)
        cell?.layoutMargins = UIEdgeInsets.zero
        return cell!
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.didSelectRow(at: indexPath.row,
                               of: optionType,
                               tableView: tableView,
                               view: self)
        setLocalIndex(with: indexPath)
        tableView.reloadData()
    }
}
