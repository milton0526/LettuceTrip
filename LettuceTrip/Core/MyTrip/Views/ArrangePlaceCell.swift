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
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .label
        return label
    }()

    lazy var toTimeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .label
        return label
    }()

    lazy var placeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()

    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView(image: .init(systemName: "mappin.and.ellipse")?.withTintColor(.tintColor))
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
        let subviews = [fromTimeLabel, toTimeLabel, lineView, placeLabel, iconImageView]
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

        placeLabel.centerYToSuperview()
        placeLabel.leadingToTrailing(of: fromTimeLabel, offset: 24)
        placeLabel.widthToSuperview(multiplier: 0.5)

        iconImageView.size(.init(width: 35, height: 35))
        iconImageView.centerYToSuperview()
        iconImageView.trailingToSuperview(offset: 16)
    }

    func config(with place: Place) {
        guard let duration = place.duration else { return }
        let toTime = place.arrangedTime?.addingTimeInterval(duration)

        fromTimeLabel.text = place.arrangedTime?.formatted(date: .omitted, time: .shortened)
        toTimeLabel.text = toTime?.formatted(date: .omitted, time: .shortened)
        placeLabel.text = place.name
        iconImageView.image = UIImage(data: place.iconImage)?.withTintColor(.tintColor)
    }
}
