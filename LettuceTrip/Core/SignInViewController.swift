//
//  SignInViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/27.
//

import UIKit
import TinyConstraints
import AuthenticationServices

class SignInViewController: UIViewController {

    private let appleSignInButton = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: .black)
    private let viewModel = SignInViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.viewController = self
        appleSignInButton.addTarget(self, action: #selector(startSignInWithAppleFlow), for: .touchUpInside)

        view.backgroundColor = .systemBackground
        view.addSubview(appleSignInButton)
        appleSignInButton.widthToSuperview(multiplier: 0.7)
        appleSignInButton.height(44)
        appleSignInButton.centerInSuperview()
    }

    @objc func startSignInWithAppleFlow(_ sender: UIColor) {
        viewModel.signInWithApple()
    }
}
