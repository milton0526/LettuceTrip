//
//  UITableView+Identifier.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit

extension UITableViewCell {
    static var identifier: String {
        String(describing: self)
    }
}

extension UITableViewHeaderFooterView {
    static var identifier: String {
        String(describing: self)
    }
}
