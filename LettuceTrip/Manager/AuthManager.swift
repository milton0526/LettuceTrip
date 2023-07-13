//
//  AuthManager.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/27.
//

import AuthenticationServices
import FirebaseAuth
import Combine

protocol AuthManagerDelegate: AnyObject {

    func presentAnchor(_ manager: AuthManager) -> UIWindow

    func authorizationSuccess(_ manager: AuthManager)

    func authorizationFailed(_ manager: AuthManager, error: Error)
}

class AuthManager: NSObject {

    private var currentNonce: String?
    private var isDelete = false
    private var cancelBags: Set<AnyCancellable> = []
    private let fsManager: FirestoreManager

    weak var delegate: AuthManagerDelegate?

    init(fsManager: FirestoreManager) {
        self.fsManager = fsManager
        super.init()
    }

    func signInFlow(isDelete: Bool = false) {
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

    func signOut() throws {
        try Auth.auth().signOut()
    }
}

extension AuthManager: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {

            guard
                let nonce = currentNonce,
                let appleIDToken = appleIDCredential.identityToken,
                let idTokenString = String(data: appleIDToken, encoding: .utf8)
            else {
                return
            }

            if isDelete {
                guard
                    let appleAuthCode = appleIDCredential.authorizationCode,
                    let authCodeString = String(data: appleAuthCode, encoding: .utf8)
                else {
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
        delegate?.authorizationFailed(self, error: error)
    }


    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let window = delegate?.presentAnchor(self) else {
            let keyWindow = UIApplication.shared.connectedScenes
                .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                .last { $0.isKeyWindow }
            // swiftlint: disable force_unwrapping
            return keyWindow!
            // swiftlint: enable force_unwrapping
        }
        return window
    }

    private func signIntoFirebase(credential: OAuthCredential) {
        Auth.auth().signIn(with: credential) { [weak self] authResults, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.delegate?.authorizationFailed(self, error: error)
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

            // Create user if first time
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
                                    self.delegate?.authorizationSuccess(self)
                                case .failure(let error):
                                    self.delegate?.authorizationFailed(self, error: error)
                                }
                            } receiveValue: { _ in }
                            .store(in: &self.cancelBags)
                    } else {
                        self.delegate?.authorizationSuccess(self)
                    }
                }
                .store(in: &cancelBags)
        }
    }

    func deleteAccount(credential: OAuthCredential, authCode: String) {
        guard let user = Auth.auth().currentUser else { return }

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
                        self.delegate?.authorizationSuccess(self)
                    case .failure(let error):
                        self.delegate?.authorizationFailed(self, error: error)
                    }
                } receiveValue: { _ in }
                .store(in: &self.cancelBags)

            Auth.auth().revokeToken(withAuthorizationCode: authCode)
            user.delete()
        }
    }
}
