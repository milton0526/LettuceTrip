//
//  JGProgressHUD+Wrapper.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/7.
//

import UIKit
import JGProgressHUD

final class JGHudIndicator {
    static let shared = JGHudIndicator()

    private let hud = JGProgressHUD(style: .dark)

    private var view: UIView {
        // swiftlint: disable force_unwrapping
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first!.rootViewController!.view
        // swiftlint: enable force_unwrapping
    }

    private init() { }

    enum HudType {
        case success
        case failure
        case loading(text: String = String(localized: "Loading..."))
    }

    func showHud(type: HudType) {
        switch type {
        case .success:
            showSuccess()
        case .failure:
            showFailure()
        case .loading(let text):
            showLoading(text: text)
        }
    }

    private func showSuccess() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [unowned self] in
                self.showSuccess()
            }
            return
        }
        hud.textLabel.text = String(localized: "Success")
        hud.indicatorView = JGProgressHUDSuccessIndicatorView()
        hud.show(in: view)
        hud.dismiss(afterDelay: 1.5)
    }

    private func showFailure() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [unowned self] in
                self.showFailure()
            }
            return
        }
        hud.textLabel.text = String(localized: "Failure")
        hud.indicatorView = JGProgressHUDErrorIndicatorView()
        hud.show(in: view)
        hud.dismiss(afterDelay: 1.5)
    }

    private func showLoading(text: String) {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [unowned self] in
                self.showLoading(text: text)
            }
            return
        }
        hud.textLabel.text = text
        hud.indicatorView = JGProgressHUDIndeterminateIndicatorView()
        hud.show(in: view)
    }

    func dismissHUD() {
        if !Thread.isMainThread {
            DispatchQueue.main.async { [unowned self] in
                self.dismissHUD()
            }
            return
        }
        hud.dismiss()
    }
}
