//
//  SectionBackgroundDecorationView.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/23.
//

import UIKit

class SectionBackgroundDecorationView: UICollectionReusableView {
    static let identifier = String(describing: SectionBackgroundDecorationView.self)
    static let kind = "BackgroundDecoration"

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemTeal
        layer.cornerRadius = 20
        layer.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
