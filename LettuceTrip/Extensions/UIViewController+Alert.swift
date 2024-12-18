//
//  UIViewController+Alert.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit
import TinyConstraints

extension UIViewController {

    func showAlertToUser(error: Error) {
        let alert = UIAlertController(
            title: String(localized: "Something went wrong!"),
            message: error.localizedDescription,
            preferredStyle: .alert)
        let action = UIAlertAction(
            title: String(localized: "OK"),
            style: .default)
        alert.addAction(action)
        self.present(alert, animated: true)
    }

    func showAuthErrorAlert() {
        let alert = UIAlertController(
            title: String(localized: "Operation cancel!"),
            message: nil,
            preferredStyle: .alert)
        let action = UIAlertAction(
            title: String(localized: "OK"),
            style: .default)
        alert.addAction(action)
        self.present(alert, animated: true)
    }
}
