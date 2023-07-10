//
//  ArrangePlaceCell.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/23.
//

import UIKit
import TinyConstraints

class ArrangePlaceCell: UITableViewCell {

    lazy var fromTimeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .label
        return label
    }()

    lazy var toTimeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .regular)
        label.textColor = .label
        return label
    }()

    lazy var placeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()

    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView(image: .init(systemName: "mappin.and.ellipse")?.withTintColor(.tintColor))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray
        return view
    }()

    lazy var hareImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "hare.fill"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .tintColor
        return imageView
    }()

    lazy var estimatedTimeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        return label
    }()

    lazy var timeVStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [fromTimeLabel, lineView, toTimeLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        return stackView
    }()

    lazy var placeHStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [timeVStack, placeLabel, iconImageView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        return stackView
    }()

    lazy var estimatedHStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [hareImageView, estimatedTimeLabel, UIView()])
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        estimatedHStack.isHidden = false
    }

    private func setupViews() {
        [placeHStack, estimatedHStack].forEach { contentView.addSubview($0) }

        iconImageView.size(.init(width: 35, height: 35))
        lineView.size(.init(width: 1.3, height: 14))

        placeHStack.topToSuperview(offset: 8)
        placeHStack.horizontalToSuperview(insets: .horizontal(8))
        placeHStack.height(68, relation: .equalOrGreater)
        placeHStack.backgroundColor = .secondarySystemBackground
        placeHStack.layer.cornerRadius = 10
        placeHStack.layer.masksToBounds = true
        placeHStack.layoutMargins = .init(top: 8, left: 16, bottom: 8, right: 16)
        placeHStack.isLayoutMarginsRelativeArrangement = true

        estimatedHStack.topToBottom(of: placeHStack, offset: 8)
        estimatedHStack.height(16, relation: .equalOrGreater)
        estimatedHStack.horizontalToSuperview(insets: .horizontal(16))
        estimatedHStack.bottomToSuperview()
    }

    func config(with place: Place, travelTime: String? = nil) {
        let toTime = place.endTime

        fromTimeLabel.text = place.arrangedTime?.formatted(date: .omitted, time: .shortened)
        toTimeLabel.text = toTime?.formatted(date: .omitted, time: .shortened)
        placeLabel.text = place.name
        iconImageView.image = UIImage(data: place.iconImage)?.withTintColor(.tintColor)

        if let travelTime = travelTime {
            estimatedTimeLabel.text = travelTime == String(localized: "Not available") ? travelTime : String(localized: "\(travelTime) minutes")
        } else {
            estimatedHStack.isHidden = true
        }
    }
}
