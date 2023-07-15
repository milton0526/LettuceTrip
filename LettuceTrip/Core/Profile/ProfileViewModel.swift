//
//  ProfileViewModel.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/14.
//

import Foundation
import Combine

enum ProfileVMInput {
    case signOut
    case deleteAccount
    case fetchUserData
    case updateImage(Data)
}

enum ProfileVMOutput {
    case signOut
    case signOutFailed(Error)
    case deleteAccount
    case fetchUserSuccess
    case fetchUserFailed(Error)
    case updateImageFailed(Error)
}

protocol ProfileViewModelType {
    var user: LTUser? { get }

    func transform(input: AnyPublisher<ProfileVMInput, Never>) -> AnyPublisher<ProfileVMOutput, Never>
}

final class ProfileViewModel: ProfileViewModelType {

    private let settings = SettingModel.profileSettings
    private let fsManager: FirestoreManager
    private let authManager: AuthManager
    private let storageManager: StorageManager

    private var cancelBags: Set<AnyCancellable> = []
    private let output: PassthroughSubject<ProfileVMOutput, Never> = .init()
    var user: LTUser?

    init(fsManager: FirestoreManager, authManager: AuthManager, storageManager: StorageManager) {
        self.fsManager = fsManager
        self.authManager = authManager
        self.storageManager = storageManager
    }

    func transform(input: AnyPublisher<ProfileVMInput, Never>) -> AnyPublisher<ProfileVMOutput, Never> {
        input
            .sink { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .signOut:
                    do {
                        try authManager.signOut()
                        output.send(.signOut)
                    } catch {
                        output.send(.signOutFailed(error))
                    }
                case .deleteAccount:
                    authManager.signInFlow(isDelete: true)
                case .fetchUserData:
                    fetchData()
                case .updateImage(let data):
                    updateUserImage(data)
                }
            }
            .store(in: &cancelBags)

        return output.eraseToAnyPublisher()
    }

    private func fetchData() {
        guard let userId = fsManager.user else { return }

        fsManager.getUserData(userId: userId)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .finished:
                    output.send(.fetchUserSuccess)
                case .failure(let error):
                    output.send(.fetchUserFailed(error))
                }
            }, receiveValue: { [weak self] user in
                self?.user = user
            })
            .store(in: &cancelBags)
    }

    private func updateUserImage(_ data: Data) {
        guard let userId = fsManager.user else { return }

        storageManager.uploadImage(data, at: .users, with: userId)
            .retry(1)
            .flatMap { [weak self] _ in
                self?.storageManager.downloadRef(at: .users, with: userId) ?? Empty<URL, Error>().eraseToAnyPublisher()
            }
            .flatMap { [weak self] url in
                self?.fsManager.updateUser(image: url.absoluteString) ?? Empty<Void, Error>().eraseToAnyPublisher()
            }
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .finished:
                    fetchData()
                case .failure(let error):
                    output.send(.updateImageFailed(error))
                }
            }, receiveValue: { _ in })
            .store(in: &cancelBags)
    }
}
