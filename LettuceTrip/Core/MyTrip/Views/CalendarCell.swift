//
//  CalendarCell.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/23.
//

import UIKit
import TinyConstraints

class CalendarCell: UICollectionViewCell {

    override var isSelected: Bool {
        didSet {
            stackView.backgroundColor = isSelected ? .tintColor : .secondarySystemBackground
            weekLabel.textColor = isSelected ? .white : .systemGray
            dayLabel.textColor = isSelected ? .white : .systemGray
        }
    }

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        return stackView
    }()

    lazy var weekLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 14)
        return label
    }()

    lazy var dayLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 14)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        isSelected = false
    }

    private func setupViews() {
        stackView.addArrangedSubview(weekLabel)
        stackView.addArrangedSubview(dayLabel)
        stackView.layer.cornerRadius = 10
        stackView.layer.masksToBounds = true

        contentView.addSubview(stackView)
        stackView.edgesToSuperview()
    }
}
