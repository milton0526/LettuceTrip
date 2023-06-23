//
//  ArrangePlaceCell.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/23.
//

import UIKit
import TinyConstraints

class ArrangePlaceCell: UICollectionViewCell {

    lazy var fromTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "9:00 am"
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .systemGray
        return label
    }()

    lazy var toTimeLabel: UILabel = {
        let label = UILabel()
        label.text = "11:00 am"
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .systemGray
        return label
    }()

    lazy var placeLabel: UILabel = {
        let label = UILabel()
        label.text = "Milano Park"
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .label
        return label
    }()

    lazy var locationLabel: UILabel = {
        let label = UILabel()
        label.text = "Sant Paulo, Milan, Italy"
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .systemGray
        return label
    }()

    

}
