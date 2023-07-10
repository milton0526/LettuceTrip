//
//  SDWebImage+Wrapper.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/10.
//

import UIKit

extension UIImageView {

    func setUserImage(url: URL) {
        self.sd_setImage(with: url, placeholderImage: UIImage(systemName: "person.crop.circle"))
    }

    func setTripImage(url: URL) {
        self.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder"))
    }
}
