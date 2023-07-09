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

//    func transform(input: Input) -> Output {
//        let updatePublisher = input.fetchPublisher
//            .flatMap { [unowned self] id in
//                self.fsManager.chatRoomListener(id) { <#Result<[Message], Error>#> in
//                    <#code#>
//                }
//            }
//
//        let sendMSGPublisher = input.messagePublisher
//            .flatMap { [unowned self] text, tripId in
//                self.fsManager.sendMessage(text, at: tripId)
//            }
//            .replaceError(with: JGHudIndicator.shared.showHud(type: .failure))
//            .eraseToAnyPublisher()
//
//        let output = Output(updateViewPublisher: sendMSGPublisher, sendMSGPublisher: sendMSGPublisher)
//        return output
//    }
}
