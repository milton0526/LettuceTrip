//
//  ProfileViewModel.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/14.
//

import Foundation
import Combine

protocol ProfileViewModelType {
    var user: LTUser? { get }

    func transform()
}

final class ProfileViewModel {

    private let settings = SettingModel.profileSettings
    private let fsManager: FirestoreManager
    private let authManager: AuthManager
    private let storageManager: StorageManager

    private var cancelBags: Set<AnyCancellable> = []

    init(fsManager: FirestoreManager, authManager: AuthManager, storageManager: StorageManager) {
        self.fsManager = fsManager
        self.authManager = authManager
        self.storageManager = storageManager
    }
}
