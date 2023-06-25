//
//  CalendarCell.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/23.
//

import UIKit
import TinyConstraints

class CalendarCell: UICollectionViewCell {

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
        label.textColor = .white
        return label
    }()

    lazy var dayLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 14)
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
        stackView.addArrangedSubview(weekLabel)
        stackView.addArrangedSubview(dayLabel)
        stackView.backgroundColor = .systemTeal
        stackView.layer.cornerRadius = 10
        stackView.layer.masksToBounds = true

        contentView.addSubview(stackView)
        stackView.edgesToSuperview()
    }
}
