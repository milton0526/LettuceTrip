//
//  ItineraryCell.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit
import TinyConstraints

protocol ItineraryCellDelegate: AnyObject {
    func reportAction(_ cell: ItineraryCell)
}

class ItineraryCell: UICollectionViewCell {

    weak var delegate: ItineraryCellDelegate?

    lazy var menuButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        button.tintColor = .tintColor
        button.showsMenuAsPrimaryAction = true
        button.menu = UIMenu(children: [
            UIAction(title: String(localized: "Report"), handler: reportActionHandler(_:))
        ])
        return button
    }()

    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: .scene)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy var tripNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()

    lazy var timeLabel: UILabel = {
        let label = UILabel()
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

    private func setupViews() {
        [menuButton, imageView, tripNameLabel, timeLabel].forEach { contentView.addSubview($0) }

        imageView.horizontalToSuperview()
        imageView.topToSuperview()
        imageView.widthToSuperview()

        tripNameLabel.topToBottom(of: imageView, offset: 8)
        tripNameLabel.height(18)
        tripNameLabel.widthToSuperview(multiplier: 0.5)
        tripNameLabel.centerXToSuperview()
        tripNameLabel.bottomToSuperview(offset: -4)

        timeLabel.centerY(to: tripNameLabel)
        timeLabel.leadingToSuperview(offset: 8)
        timeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        menuButton.trailingToSuperview(offset: 8)
        menuButton.size(CGSize(width: 28, height: 28))
        menuButton.bottomToSuperview()
    }

    func config(with trip: Trip) {
        tripNameLabel.text = trip.tripName
        timeLabel.text = trip.startDate.formatted(date: .numeric, time: .omitted)
        if let url = URL(string: trip.image ?? "") {
            imageView.setTripImage(url: url)
        }
    }

    private func reportActionHandler(_ action: UIAction) {
        delegate?.reportAction(self)
    }
}
