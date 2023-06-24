//
//  FriendMessageCell.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/24.
//

import UIKit

class FriendMessageCell: UICollectionViewCell {

    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: .init(systemName: "figure.archery"))
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.font = .systemFont(ofSize: 14, weight: .medium)
        textView.backgroundColor = .secondarySystemBackground
        textView.textColor = .label
        textView.textContainerInset = .init(top: 8, left: 8, bottom: 8, right: 8)
        textView.layer.cornerRadius = 12
        textView.layer.masksToBounds = true
        textView.text = "你覺得我們是好朋友嗎？\n我認為你想太多了吧🤣"
        return textView
    }()

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.distribution = .fill
        stackView.spacing = 10
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        imageView.size(.init(width: 20, height: 20))
        imageView.aspectRatio(1.0)

        textView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(textView)

        contentView.addSubview(stackView)
        stackView.verticalToSuperview(insets: .vertical(10))
        stackView.leadingToSuperview(offset: 12)
        stackView.widthToSuperview(multiplier: 0.6)
    }
}
