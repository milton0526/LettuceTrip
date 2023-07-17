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
        LabelFactory.build(
            text: "Discover best places to go on vacation and make itinerary with friends😍",
            font: .title,
            numberOfLines: 0,
            textAlignment: .center)
    }()

    private lazy var appleSignInButton = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: currentStyle)
    private let authManager: AuthManager

    init(authManager: AuthManager) {
        self.authManager = authManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        authManager.delegate = self
        appleSignInButton.addTarget(self, action: #selector(startSignInWithAppleFlow), for: .touchUpInside)
        setupUI()
    }

    @objc func startSignInWithAppleFlow(_ sender: UIColor) {
        authManager.signInFlow()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
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

// MARK: AuthManager Delegate
extension SignInViewController: AuthManagerDelegate {
    func presentAnchor(_ manager: AuthManager) -> UIWindow {
        // swiftlint: disable force_unwrapping
        return view.window!
        // swiftlint: enable force_unwrapping
    }

    func authorizationSuccess(_ manager: AuthManager) {
        let fsManager = FirestoreManager()
        let tabBarVC = TabBarViewController(fsManager: fsManager)
        tabBarVC.modalPresentationStyle = .fullScreen
        present(tabBarVC, animated: true)
    }

    func authorizationFailed(_ manager: AuthManager, error: Error) {
        showAuthErrorAlert()
    }
}
