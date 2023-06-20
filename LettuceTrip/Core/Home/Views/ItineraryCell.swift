//
//  ItineraryCell.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit
import TinyConstraints

class ItineraryCollectionViewCell: UICollectionViewCell {

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
        label.text = "Trip to Kyoto"
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textColor = .label
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
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        imageView.size(CGSize(width: 68, height: 68))
        imageView.centerY(to: contentView)
        imageView.leading(to: contentView)

        titleLabel.leadingToTrailing(of: imageView, offset: 8)
        titleLabel.top(to: imageView, offset: 8)
    }
}
