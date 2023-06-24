//
//  UserMessageCell.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/24.
//

import UIKit
import TinyConstraints

class UserMessageCell: UICollectionViewCell {

    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: .init(systemName: "figure.australian.football"))
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 10
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.font = .systemFont(ofSize: 14, weight: .medium)
        textView.backgroundColor = .tintColor
        textView.textColor = .white
        textView.textContainerInset = .init(top: 8, left: 8, bottom: 8, right: 8)
        textView.layer.cornerRadius = 12
        textView.layer.masksToBounds = true
        textView.text = "這是測試訊息cell，我希望能順利產生我要的畫面"
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
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .light)
        label.textColor = .label
        label.sizeToFit()
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
        imageView.size(.init(width: 20, height: 20))
        imageView.aspectRatio(1.0)

        textView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        stackView.addArrangedSubview(textView)
        stackView.addArrangedSubview(imageView)

        contentView.addSubview(stackView)
        contentView.addSubview(timeLabel)
        stackView.verticalToSuperview(insets: .vertical(10))
        stackView.trailingToSuperview(offset: 12)
        stackView.widthToSuperview(multiplier: 0.6)

        timeLabel.trailingToLeading(of: stackView, offset: -8)
        timeLabel.height(14)
        timeLabel.bottom(to: stackView)
    }

    func config(with message: Message) {
        textView.text = message.message
        timeLabel.text = message.sendTime?.formatted(date: .omitted, time: .shortened)
    }
}
