//
//  POILocationCardCell.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit
import TinyConstraints

class POILocationCardCell: UICollectionViewCell {

    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "kyoto"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 24
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Kyoto"
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        return label
    }()

    lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Description: sfhkshnfksnefkjsnfkjnsfknsfkjsdsgkjns"
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .white
        label.alpha = 0.9
        label.numberOfLines = 2
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = .systemGray
        contentView.alpha = 0.85
        contentView.layer.cornerRadius = 24
        contentView.layer.masksToBounds = true
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        [imageView, titleLabel, subtitleLabel].forEach { contentView.addSubview($0) }

        imageView.size(CGSize(width: 68, height: 68))
        imageView.centerY(to: contentView)
        imageView.leading(to: contentView, offset: 16)

        titleLabel.leadingToTrailing(of: imageView, offset: 8)
        titleLabel.top(to: imageView, offset: 4)
        titleLabel.trailingToSuperview(offset: 8)

        subtitleLabel.leadingToTrailing(of: imageView, offset: 8)
        subtitleLabel.trailingToSuperview(offset: 8)
        subtitleLabel.bottom(to: imageView)
    }
}
