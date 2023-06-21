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
        let imageView = UIImageView(image: .init(named: "placeholder2"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 24
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .heavy)
        label.textColor = .white
        label.sizeToFit()
        return label
    }()

    lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = .white
        label.sizeToFit()
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(photoImageView)
        photoImageView.addSubview(titleLabel)
        photoImageView.addSubview(subtitleLabel)

        photoImageView.edgesToSuperview(excluding: .bottom, insets: .uniform(16))
        photoImageView.bottomToSuperview()

        titleLabel.leadingToSuperview(offset: 16)
        titleLabel.bottomToSuperview(offset: -16)

        subtitleLabel.bottom(to: titleLabel)
        subtitleLabel.trailingToSuperview(offset: 16)
        subtitleLabel.leadingToTrailing(of: titleLabel, offset: 16, relation: .equalOrGreater)
    }
}
