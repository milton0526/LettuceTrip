//
//  FriendMessageCell.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/24.
//

import UIKit

class FriendMessageCell: UICollectionViewCell {

    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: .person)
        imageView.setContentMode()
        imageView.makeCornerRadius(15)
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
        textView.isEditable = false
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

    lazy var timeLabel: UILabel = {
        LabelFactory.build(text: nil, font: .caption)
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        imageView.size(.init(width: 30, height: 30))
        imageView.aspectRatio(1.0)

        textView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(textView)

        contentView.addSubview(stackView)
        contentView.addSubview(timeLabel)
        stackView.verticalToSuperview(insets: .vertical(10))
        stackView.leadingToSuperview(offset: 12)
        stackView.widthToSuperview(multiplier: 0.6, relation: .equalOrLess)

        timeLabel.leadingToTrailing(of: stackView, offset: 8)
        timeLabel.height(14)
        timeLabel.bottom(to: stackView)
    }

    func config(with message: Message, from user: LTUser?) {
        textView.text = message.message
        timeLabel.text = message.sendTime?.formatted(date: .omitted, time: .shortened)

        guard
            let image = user?.image,
            let url = URL(string: image)
        else {
            return
        }
        imageView.setUserImage(url: url)
    }
}
