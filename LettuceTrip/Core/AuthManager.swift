//
//  AuthManager.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/27.
//

import AuthenticationServices
import FirebaseAuth
import Combine

class AuthManager: NSObject {

    private var currentNonce: String?
    weak var viewController: UIViewController?
    private var isDelete = false
    private var cancelBags: Set<AnyCancellable> = []
    private let fsManager = FirestoreManager()

    func signInWithApple(isDelete: Bool = false) {
        self.isDelete = isDelete

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

    func signOut(completion: @escaping (Error?) -> Void) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            completion(nil)
        } catch {
            completion(error)
        }
    }
}

extension AuthManager: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {

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

            if isDelete {
                guard let appleAuthCode = appleIDCredential.authorizationCode else {
                    print("Unable to fetch authorization code")
                    return
                }

                guard let authCodeString = String(data: appleAuthCode, encoding: .utf8) else {
                    print("Unable to serialize auth code string from data: \(appleAuthCode.debugDescription)")
                    return
                }

                let credential = OAuthProvider.credential(
                    withProviderID: "apple.com",
                    idToken: idTokenString,
                    rawNonce: nonce)

                deleteAccount(credential: credential, authCode: authCodeString)
            } else {
                let credential = OAuthProvider.appleCredential(
                    withIDToken: idTokenString,
                    rawNonce: nonce,
                    fullName: appleIDCredential.fullName)

                signIntoFirebase(credential: credential)
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

    private func signIntoFirebase(credential: OAuthCredential) {
        guard let viewController = viewController else { return }

        Auth.auth().signIn(with: credential) { [weak self] authResults, error in
            if let error = error {
                print("Error sign in with Firebase" + error.localizedDescription)

                DispatchQueue.main.async {
                    viewController.showAlertToUser(error: error)
                }

                return
            }

            guard
                let self = self,
                let userID = authResults?.user.uid,
                let userName = authResults?.user.displayName,
                let email = authResults?.user.email
            else {
                return
            }

            // User is signed in to Firebase with Apple.
            // Create user if first time...
            self.fsManager.checkUserExist(id: userID)
                .sink { _ in
                } receiveValue: { exist in
                    if !exist {
                        let user = LTUser(id: userID, name: userName, email: email)

                        self.fsManager.createUser(id: userID, user: user)
                            .receive(on: DispatchQueue.main)
                            .sink { completion in
                                switch completion {
                                case .finished:
                                    let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                                    let mainVC = storyBoard.instantiateViewController(withIdentifier: "TabBarController")
                                    mainVC.modalPresentationStyle = .fullScreen
                                    viewController.present(mainVC, animated: true)
                                case .failure(let error):
                                    viewController.showAlertToUser(error: error)
                                }
                            } receiveValue: { _ in }
                            .store(in: &self.cancelBags)
                    } else {
                        DispatchQueue.main.async {
                            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                            let mainVC = storyBoard.instantiateViewController(withIdentifier: "TabBarController")
                            mainVC.modalPresentationStyle = .fullScreen
                            viewController.present(mainVC, animated: true)
                        }
                    }
                }
                .store(in: &cancelBags)
        }
    }

    func deleteAccount(credential: OAuthCredential, authCode: String) {
        guard
            let viewController = viewController,
            let user = Auth.auth().currentUser
        else {
            return
        }

        user.reauthenticate(with: credential) { [weak self] _, error in
            guard
                let self = self,
                error == nil
            else {
                JGHudIndicator.shared.showHud(type: .failure)
                return
            }

            self.fsManager.deleteUser(userId: user.uid)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .finished:
                        let signInVC = SignInViewController()
                        signInVC.modalPresentationStyle = .fullScreen
                        viewController.present(signInVC, animated: true)
                    case .failure(let error):
                        viewController.showAlertToUser(error: error)
                    }
                } receiveValue: { _ in }
                .store(in: &self.cancelBags)

            Auth.auth().revokeToken(withAuthorizationCode: authCode)
            user.delete()
        }
    }
}
