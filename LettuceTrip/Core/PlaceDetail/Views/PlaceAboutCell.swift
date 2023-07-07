//
//  PlaceAboutCell.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit
import TinyConstraints

class PlaceAboutCell: UITableViewCell {

    lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 18)
        label.sizeToFit()
        return label
    }()

    lazy var openingHourLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .light)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.sizeToFit()
        return label
    }()

    lazy var websiteLabel: UILabel = {
        let label = UILabel()
        label.textColor = .label
        label.font = .boldSystemFont(ofSize: 18)
        label.sizeToFit()
        label.text = String(localized: "Website")
        return label
    }()

    lazy var linkLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemBlue
        label.font = .systemFont(ofSize: 14)
        label.sizeToFit()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openWebsite))
        label.addGestureRecognizer(tapGesture)
        label.isUserInteractionEnabled = true
        return label
    }()

    var handler: ((URL) -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .systemBackground
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc func openWebsite(_ gesture: UIGestureRecognizer) {
        guard
            let website = linkLabel.text,
            !website.isEmpty
        else {
            return
        }

        if let url = URL(string: website) {
            handler?(url)
        }
    }

    private func setupViews() {
        [statusLabel, openingHourLabel, websiteLabel, linkLabel].forEach { contentView.addSubview($0) }

        statusLabel.topToSuperview()
        statusLabel.leadingToSuperview(offset: 20)

        openingHourLabel.topToBottom(of: statusLabel, offset: 8)
        openingHourLabel.leading(to: statusLabel)

        websiteLabel.topToBottom(of: openingHourLabel, offset: 16)
        websiteLabel.leading(to: statusLabel)

        linkLabel.topToBottom(of: websiteLabel, offset: 8)
        linkLabel.leading(to: statusLabel)
        linkLabel.trailingToSuperview(offset: 20)
        linkLabel.bottomToSuperview()
    }

    func config(with model: PlaceAboutCellViewModel) {
        let openingHours = model.openingHours.joined(separator: "\n")

        openingHourLabel.text = openingHours
        linkLabel.text = model.website ?? "This place not provide website."
    }
}
