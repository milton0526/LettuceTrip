//
//  PopularCityHeaderView.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit
import TinyConstraints

class ItineraryHeaderView: UICollectionReusableView {
    static let identifier = String(describing: ItineraryHeaderView.self)

    lazy var titleLabel: UILabel = {
        LabelFactory.build(text: nil, font: .title)
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        addSubview(titleLabel)
        titleLabel.centerY(to: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
