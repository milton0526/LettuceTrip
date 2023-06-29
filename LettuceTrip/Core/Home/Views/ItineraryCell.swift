//
//  ItineraryCell.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit
import TinyConstraints

class ItineraryCollectionViewCell: UICollectionViewCell {

    lazy var userImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "person.circle"))
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy var userNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Milton liu"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .label
        return label
    }()

    lazy var menuButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        button.tintColor = .tintColor
        button.addTarget(self, action: #selector(didTapMenuButton), for: .touchUpInside)
        return button
    }()

    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "kyoto"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy var tripNameLabel: UILabel = {
        let label = UILabel()
        label.text = "Trip to Kyoto"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        return label
    }()

    lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.text = "2022/06/16"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func didTapMenuButton(_ sender: UIButton) {
        // show action sheet
    }

    private func setupViews() {
        [userImageView, userNameLabel, menuButton, imageView, tripNameLabel, timeLabel].forEach { contentView.addSubview($0) }

        imageView.horizontalToSuperview()
        imageView.centerYToSuperview()
        imageView.widthToSuperview()

        userImageView.aspectRatio(1.0)
        userImageView.leadingToSuperview(offset: 8)
        userImageView.topToSuperview(offset: 4)
        userImageView.bottomToTop(of: imageView, offset: -4)

        userNameLabel.centerY(to: userImageView)
        userNameLabel.leadingToTrailing(of: userImageView, offset: 4)
        userNameLabel.height(20)
        userNameLabel.trailing(to: menuButton, offset: 8, relation: .equalOrGreater)

        menuButton.centerY(to: userImageView)
        menuButton.trailingToSuperview(offset: 8)
        menuButton.size(CGSize(width: 20, height: 20))

        tripNameLabel.leading(to: userImageView)
        tripNameLabel.topToBottom(of: imageView, offset: 4)
        tripNameLabel.height(20)
        tripNameLabel.bottomToSuperview(offset: -4)
        tripNameLabel.trailingToLeading(of: timeLabel, offset: -8, relation: .equalOrGreater)

        timeLabel.centerY(to: tripNameLabel)
        timeLabel.trailingToSuperview(offset: 8)
        timeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
    }

    func config(with trip: Trip) {
        userNameLabel.text = trip.members.first
        tripNameLabel.text = trip.tripName
        timeLabel.text = trip.startDate.formatted(date: .numeric, time: .omitted)

        // Need to use dispatch group to fetch user data
    }
}
