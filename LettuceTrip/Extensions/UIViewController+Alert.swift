//
//  UIViewController+Alert.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit

extension UIViewController {

    func showAlertToUser(error: Error) {
        if let error = error as? GMSError {
            let alert = UIAlertController(title: error.title, message: error.errorDescription, preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default)
            alert.addAction(action)
            self.present(alert, animated: true)
        }
    }
}
