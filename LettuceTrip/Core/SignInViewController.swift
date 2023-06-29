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

    var currentStyle: ASAuthorizationAppleIDButton.Style {
        UITraitCollection.current.userInterfaceStyle == .light ? .black : .white
    }

    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "Welcome"))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    lazy var welcomeLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "Discover best places to go on vacation and make itinerary with friends😍")
        label.font = .systemFont(ofSize: 22, weight: .heavy)
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private lazy var appleSignInButton = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: currentStyle)
    private let viewModel = SignInViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.viewController = self
        appleSignInButton.addTarget(self, action: #selector(startSignInWithAppleFlow), for: .touchUpInside)
        view.backgroundColor = .systemBackground
        setupUI()
    }

    @objc func startSignInWithAppleFlow(_ sender: UIColor) {
        viewModel.signInWithApple()
    }

    private func setupUI() {
        [imageView, welcomeLabel, appleSignInButton].forEach { view.addSubview($0) }

        imageView.edgesToSuperview(excluding: .bottom, usingSafeArea: true)
        imageView.heightToSuperview(multiplier: 0.5)

        welcomeLabel.horizontalToSuperview(insets: .horizontal(16))
        welcomeLabel.topToSuperview(view.centerYAnchor, offset: 60)

        appleSignInButton.topToBottom(of: welcomeLabel, offset: 44)
        appleSignInButton.horizontalToSuperview(insets: .horizontal(60))
        appleSignInButton.height(44)
        appleSignInButton.bottomToSuperview(offset: -20, relation: .equalOrGreater, priority: .defaultLow, usingSafeArea: true)
        appleSignInButton.cornerRadius = 8
    }
}
