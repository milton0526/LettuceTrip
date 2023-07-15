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
        imageView.setContentMode()
        imageView.makeCornerRadius(30)
        imageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(changeUserImage))
        imageView.addGestureRecognizer(tapGesture)
        return imageView
    }()

    lazy var nameLabel: UILabel = {
        LabelFactory.build(text: nil, font: .headline, textColor: .white)
    }()

    lazy var emailLabel: UILabel = {
        LabelFactory.build(text: nil, font: .headline, textColor: .white)
    }()

    var imageHandler: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func changeUserImage(_ gesture: UIGestureRecognizer) {
        imageHandler?()
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

    func config(with user: LTUser) {
        nameLabel.text = user.name
        emailLabel.text = user.email

        if let url = URL(string: user.image ?? "") {
            imageView.setUserImage(url: url)
        }
    }
}
