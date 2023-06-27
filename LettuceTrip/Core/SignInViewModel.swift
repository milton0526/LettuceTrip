//
//  SignInViewModel.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/27.
//

import UIKit
import AuthenticationServices
import FirebaseAuth

class SignInViewModel: NSObject {

    private var currentNonce: String?
    weak var viewController: UIViewController?

    func signInWithApple() {
        let nonce = FirebaseAuthHelper.randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = FirebaseAuthHelper.sha256(nonce)

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
}

extension SignInViewModel: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let viewController = viewController {
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login request was sent.")
            }

            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }

            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }

            // sign into firebase
            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName)

            // Sign in with Firebase.
            Auth.auth().signIn(with: credential) { authResults, error in
                if let error = error {
                    print("Error sign in with Firebase" + error.localizedDescription)

                    DispatchQueue.main.async {
                        viewController.showAlertToUser(error: error)
                    }

                    return
                }

                guard
                    let userID = authResults?.user.uid,
                    let userName = authResults?.user.displayName,
                    let email = authResults?.user.email
                else {
                    return
                }

                // User is signed in to Firebase with Apple.
                let user = User(id: userID, name: userName, email: email)

                FireStoreService.shared.setUser(id: userID, user: user) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success:
                            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                            let mainVC = storyBoard.instantiateViewController(withIdentifier: "TabBarController")
                            mainVC.modalPresentationStyle = .fullScreen
                            viewController.present(mainVC, animated: true)
                        case .failure(let error):
                            viewController.showAlertToUser(error: error)
                        }
                    }
                }
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        // Handle error.
        if let viewController = viewController {
            viewController.showAlertToUser(error: error)
        }
        print("Sign in with Apple errored: \(error)")
    }


    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let window = viewController?.view.window {
            return window
        } else {
            let keyWindow = UIApplication.shared.connectedScenes
                .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                .last { $0.isKeyWindow }
            // swiftlint: disable force_unwrapping
            return keyWindow!
            // swiftlint: enable force_unwrapping
        }
    }
}
