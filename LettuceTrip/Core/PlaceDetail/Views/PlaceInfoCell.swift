//
//  PlaceInfoCell.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit
import TinyConstraints

class PlaceInfoCell: UITableViewCell {

    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView(image: .init(systemName: "mappin.and.ellipse"))
        imageView.tintColor = .label
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    lazy var addressLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .label
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.1
        return label
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()

    lazy var totalRatingLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()

    lazy var ratingView: RatingStarView = {
        let ratingView = RatingStarView()
        ratingView.customSetting()
        return ratingView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .systemBackground
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        ratingView.prepareForReuse()
    }

    private func setupViews() {
        [iconImageView, addressLabel, titleLabel, totalRatingLabel, ratingView].forEach { contentView.addSubview($0) }

        iconImageView.size(CGSize(width: 20, height: 20))
        iconImageView.topToSuperview(offset: 24)
        iconImageView.leadingToSuperview(offset: 24)

        addressLabel.centerY(to: iconImageView)
        addressLabel.leadingToTrailing(of: iconImageView, offset: 8)
        addressLabel.widthToSuperview(multiplier: 0.7)

        titleLabel.topToBottom(of: iconImageView, offset: 16)
        titleLabel.leading(to: iconImageView)
        titleLabel.trailingToSuperview(offset: 16)

        ratingView.topToBottom(of: titleLabel, offset: 16)
        ratingView.leading(to: iconImageView)
        ratingView.width(min: 80)
        ratingView.bottomToSuperview(offset: -8)

        totalRatingLabel.centerY(to: ratingView)
        totalRatingLabel.leadingToTrailing(of: ratingView, offset: 8)
    }

    func config(with model: PlaceInfoCellViewModel) {
        addressLabel.text = model.address
        titleLabel.text = model.name
        ratingView.rating = Double(model.rating)
        totalRatingLabel.text = String(model.totalUserRating)
    }
}
