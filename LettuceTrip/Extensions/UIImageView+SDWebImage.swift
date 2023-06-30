//
//  UIImageView+SDWebImage.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/30.
//

import UIKit
import SDWebImage

extension UIImageView {

    func setImage(with url: URL, placeholder: UIImage = UIImage(named: "placeholder")!) {
        self.sd_setImage(with: url)
    }
}
