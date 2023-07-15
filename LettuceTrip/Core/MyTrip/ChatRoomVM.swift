//
//  ChatRoomVM.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/8.
//

import Foundation
import Combine

final class ChatRoomVM {

    struct Input {
        let fetchPublisher: AnyPublisher<String, Never>
        let messagePublisher: AnyPublisher<(text: String, id: String), Never>
    }

    struct Output {
        let updateViewPublisher: AnyPublisher<Void, Never>
        let sendMSGPublisher: AnyPublisher<Void, Never>
    }

    private let fsManager: FirestoreManager

    init(fsManager: FirestoreManager = FirestoreManager()) {
        self.fsManager = fsManager
    }
}
