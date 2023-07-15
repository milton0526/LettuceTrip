//
//  MemberCircleCell.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/23.
//

import UIKit
import TinyConstraints

class MemberCircleCell: UICollectionViewCell {

    lazy var personImageView: UIImageView = {
        let imageView = UIImageView(image: .person)
        imageView.setContentMode()
        imageView.makeCornerRadius(16)
        return imageView
    }()

    lazy var titleLabel: UILabel = {
        LabelFactory.build(
            text: nil,
            font: .caption,
            textColor: .white,
            numberOfLines: 2,
            textAlignment: .center)
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
        [personImageView, titleLabel].forEach { contentView.addSubview($0) }

        personImageView.size(.init(width: 32, height: 32))
        personImageView.centerXToSuperview()
        personImageView.topToSuperview(offset: 4)

        titleLabel.topToBottom(of: personImageView, offset: 8)
        titleLabel.horizontalToSuperview(insets: .horizontal(8))
        titleLabel.height(30)
        titleLabel.bottomToSuperview(offset: -8, relation: .equalOrGreater)
    }

    func config(user: LTUser) {
        titleLabel.text = user.name

        guard
            let image = user.image,
            let url = URL(string: image)
        else {
            return
        }
        personImageView.setUserImage(url: url)
    }
}
