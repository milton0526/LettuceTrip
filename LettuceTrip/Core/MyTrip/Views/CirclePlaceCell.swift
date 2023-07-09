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
        let imageView = UIImageView(image: .init(systemName: "person"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.1
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
        titleLabel.height(14)
        titleLabel.bottomToSuperview(offset: -8, relation: .equalOrGreater)
    }

    func config(user: LTUser) {
        if let data = user.image {
            iconImageView.image = UIImage(data: data)
        }

        titleLabel.text = user.name
    }
}
