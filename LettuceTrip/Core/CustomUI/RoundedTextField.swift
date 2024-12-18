//
//  RoundedTextField.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit

class RoundedTextField: UITextField {
    var textPadding = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)

    var cornerRadius: CGFloat = 10

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .tertiarySystemBackground
        self.layer.cornerRadius = cornerRadius
        self.layer.masksToBounds = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }

    override func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        let imageSize = UIImage(systemName: "magnifyingglass")?.size.width ?? 0
        let centerY = bounds.midY - (imageSize / 2)
        return CGRect(x: 16, y: centerY, width: imageSize, height: imageSize)
    }
}
