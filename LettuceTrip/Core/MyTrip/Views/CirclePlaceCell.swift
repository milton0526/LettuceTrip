//
//  CirclePlaceCell.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/23.
//

import UIKit
import TinyConstraints

class CirclePlaceCell: UICollectionViewCell {

    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView(image: .init(systemName: "leaf"))
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.tintColor = .white
        imageView.layer.borderColor = UIColor.systemYellow.cgColor
        return imageView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.text = "Some National Park"
        label.textAlignment = .center
        label.numberOfLines = 2
        label.sizeToFit()
        label.textColor = .white
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .tintColor
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        [iconImageView, titleLabel].forEach { contentView.addSubview($0) }

        iconImageView.size(.init(width: 32, height: 32))
        iconImageView.centerXToSuperview()
        iconImageView.topToSuperview(offset: 4)

        titleLabel.topToBottom(of: iconImageView, offset: 8)
        titleLabel.horizontalToSuperview(insets: .horizontal(8))
        titleLabel.bottomToSuperview(offset: -8, relation: .equalOrGreater)
    }
}
