//
//  TripCell.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit
import TinyConstraints

class TripCell: UITableViewCell {

    lazy var photoImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "placeholder"))
        imageView.setContentMode()
        imageView.makeCornerRadius(20)
        return imageView
    }()

    lazy var titleLabel: UILabel = {
        let label = LabelFactory.build(text: nil, font: .title, textColor: .white)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.1
        return label
    }()

    lazy var subtitleLabel: UILabel = {
        let label = LabelFactory.build(text: nil, font: .subtitle, textColor: .white)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.1
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        photoImageView.image = UIImage(named: "placeholder")
    }

    private func setupViews() {
        contentView.addSubview(photoImageView)
        photoImageView.addSubview(titleLabel)
        photoImageView.addSubview(subtitleLabel)

        photoImageView.edgesToSuperview(excluding: .bottom, insets: .uniform(16))
        photoImageView.bottomToSuperview()

        titleLabel.leadingToSuperview(offset: 16, relation: .equalOrGreater)
        titleLabel.trailingToSuperview(offset: 16)
        titleLabel.bottomToTop(of: subtitleLabel, offset: -8)
        titleLabel.height(25)

        subtitleLabel.bottomToSuperview(offset: -8)
        subtitleLabel.trailingToSuperview(offset: 16)
        subtitleLabel.leadingToSuperview(offset: 16, relation: .equalOrGreater)
        subtitleLabel.height(25)
    }

    func config(with trip: Trip) {
        titleLabel.text = trip.tripName
        if let url = URL(string: trip.image ?? "") {
            photoImageView.setTripImage(url: url)
        }

        let fromDate = trip.startDate.formatted(date: .numeric, time: .omitted)
        let toDate = trip.endDate.formatted(date: .numeric, time: .omitted)
        subtitleLabel.text = fromDate + " - " + toDate
    }
}
