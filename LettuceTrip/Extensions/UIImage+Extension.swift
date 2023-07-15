//
//  UIImage+Extension.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/10.
//

import UIKit

extension UIImage {
    static let person = UIImage(systemName: "person.crop.circle")
    static let scene = UIImage(named: "placeholder")
}

extension UIImageView {

    func setContentMode(contentMode: UIView.ContentMode = .scaleAspectFill) {
        self.contentMode = contentMode
        self.clipsToBounds = true
    }

    func makeCornerRadius(_ radius: CGFloat) {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
}
