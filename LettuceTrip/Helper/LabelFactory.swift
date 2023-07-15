//
//  UILabel+Extension.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/15.
//

import UIKit

enum LabelFactory {

    case title
    case subtitle
    case headline
    case body
    case caption

    var style: UIFont {
        switch self {
        case .title:
            return .systemFont(ofSize: 20, weight: .heavy)
        case .subtitle:
            return .systemFont(ofSize: 18, weight: .black)
        case .headline:
            return .systemFont(ofSize: 16, weight: .bold)
        case .body:
            return .systemFont(ofSize: 14, weight: .medium)
        case .caption:
            return .systemFont(ofSize: 12, weight: .regular)
        }
    }

    static func build(
        text: String?,
        font: LabelFactory,
        textColor: UIColor = .label,
        numberOfLines: Int = 1,
        textAlignment: NSTextAlignment = .left
    ) -> UILabel {
        let label = UILabel()
        if let text = text {
            label.text = NSLocalizedString(text, comment: "")
        }
        label.font = font.style
        label.textColor = textColor
        label.numberOfLines = numberOfLines
        label.textAlignment = textAlignment
        return label
    }
}
