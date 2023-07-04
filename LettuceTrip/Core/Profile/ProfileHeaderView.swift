//
//  ProfileHeaderView.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/28.
//

import UIKit
import TinyConstraints

class ProfileHeaderView: UIView {

    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "person.crop.circle"))
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 20
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        return label
    }()

    lazy var emailLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
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
        backgroundColor = .tintColor
        layer.cornerRadius = 34
        layer.masksToBounds = true
        layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        [imageView, nameLabel, emailLabel].forEach { addSubview($0) }

        imageView.size(CGSize(width: 60, height: 60))
        imageView.centerYToSuperview()
        imageView.leadingToSuperview(offset: 24)

        nameLabel.centerY(to: imageView, offset: -12)
        nameLabel.leadingToTrailing(of: imageView, offset: 24)
        nameLabel.trailingToSuperview(offset: 8)

        emailLabel.centerY(to: imageView, offset: 12)
        emailLabel.leading(to: nameLabel)
        emailLabel.trailing(to: nameLabel)
    }
}
