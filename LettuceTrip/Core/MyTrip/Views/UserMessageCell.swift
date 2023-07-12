//
//  UserMessageCell.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/24.
//

import UIKit
import Combine
import TinyConstraints

class UserMessageCell: UICollectionViewCell {

    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.font = .systemFont(ofSize: 14, weight: .medium)
        textView.backgroundColor = .tintColor
        textView.textColor = .white
        textView.textContainerInset = .init(top: 8, left: 8, bottom: 8, right: 8)
        textView.layer.cornerRadius = 12
        textView.layer.masksToBounds = true
        textView.isEditable = false
        return textView
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
        contentView.addSubview(textView)
        contentView.addSubview(timeLabel)
        textView.verticalToSuperview(insets: .vertical(10))
        textView.trailingToSuperview(offset: 12)
        textView.widthToSuperview(multiplier: 0.6, relation: .equalOrLess)
        textView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        timeLabel.trailingToLeading(of: textView, offset: -8)
        timeLabel.height(14)
        timeLabel.bottom(to: textView)
    }

    func config(with message: Message) {
        textView.text = message.message
        timeLabel.text = message.sendTime?.formatted(date: .omitted, time: .shortened)
    }
}
