//
//  PlaceInfoHeaderView.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit
import TinyConstraints

class PlaceInfoHeaderView: UITableViewHeaderFooterView {

    lazy var titleLabel: UILabel = {
        LabelFactory.build(text: nil, font: .title)
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        contentView.addSubview(titleLabel)
        titleLabel.centerYToSuperview()
        titleLabel.leadingToSuperview(offset: 16)
    }

    func config(with title: String) {
        titleLabel.text = title
    }
}
