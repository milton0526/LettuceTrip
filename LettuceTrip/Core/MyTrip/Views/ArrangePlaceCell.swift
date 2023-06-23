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

    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView(image: .init(systemName: "mappin.and.ellipse"))
        imageView.tintColor = .label
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        let subviews = [fromTimeLabel, toTimeLabel, lineView, placeLabel, locationLabel, iconImageView]
        subviews.forEach { contentView.addSubview($0) }

        fromTimeLabel.topToSuperview(offset: 8)
        fromTimeLabel.leadingToSuperview(offset: 16)
        fromTimeLabel.bottomToTop(of: lineView, offset: -8)
        fromTimeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        lineView.size(.init(width: 1.3, height: 14))
        lineView.centerX(to: fromTimeLabel)
        lineView.centerYToSuperview()

        toTimeLabel.topToBottom(of: lineView, offset: 8)
        toTimeLabel.leading(to: fromTimeLabel)
        toTimeLabel.bottomToSuperview(offset: -8)

        placeLabel.topToSuperview(offset: 12)
        placeLabel.leadingToTrailing(of: fromTimeLabel, offset: 24)
        placeLabel.trailingToSuperview(offset: 16, relation: .equalOrGreater)

        iconImageView.leading(to: placeLabel)
        iconImageView.size(.init(width: 10, height: 10))
        iconImageView.bottomToSuperview(offset: -12)

        locationLabel.centerY(to: iconImageView)
        locationLabel.leadingToTrailing(of: iconImageView, offset: 8)
        locationLabel.trailingToSuperview(offset: 16, relation: .equalOrGreater)
    }
}
