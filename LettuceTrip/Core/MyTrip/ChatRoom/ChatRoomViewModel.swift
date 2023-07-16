//
//  ChatRoomViewModel.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/16.
//

import Foundation
import Combine

enum ChatRoomVMInput {
    case fetchData
    case sendMessage(text: String)
}

enum ChatRoomVMOutput {
    case updateMembers([LTUser])
    case updateChatRoom
    case displayError(Error)
}

protocol ChatRoomViewModelType {

    var currentUser: String? { get }

    var members: [LTUser] { get }

    var chatMessages: [Message] { get }

    func transform(input: AnyPublisher<ChatRoomVMInput, Never>) -> AnyPublisher<ChatRoomVMOutput, Never>
}

final class ChatRoomViewModel: ChatRoomViewModelType {

    private let trip: Trip
    private let fsManager: FirestoreManager

    private var cancelBags: Set<AnyCancellable> = []
    private let output: PassthroughSubject<ChatRoomVMOutput, Never> = .init()

    var members: [LTUser] = []
    var chatMessages: [Message] = []
    var currentUser: String? {
        fsManager.user
    }

    init(trip: Trip, fsManager: FirestoreManager) {
        self.trip = trip
        self.fsManager = fsManager
    }

    func transform(input: AnyPublisher<ChatRoomVMInput, Never>) -> AnyPublisher<ChatRoomVMOutput, Never> {
        input.sink { [weak self] event in
            switch event {
            case .fetchData:
                self?.fetchData()
            case .sendMessage(let text):
                self?.sendMessage(text)
            }
        }
        .store(in: &cancelBags)

        return output.eraseToAnyPublisher()
    }

    private func fetchData() {
        trip.members.forEach { member in
            fsManager.getUserData(userId: member)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    switch completion {
                    case .finished:
                        if members.count == trip.members.count {
                            output.send(.updateMembers(members))
                            fetchMessages()
                        }
                    case .failure(let error):
                        output.send(.displayError(error))
                    }
                }, receiveValue: { [weak self] user in
                    self?.members.append(user)
                })
                .store(in: &cancelBags)
        }
    }

    private func fetchMessages() {
        guard let tripID = trip.id else { return }

        fsManager.chatRoomListener(tripID)
            .receive(on: DispatchQueue.main)

            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.output.send(.displayError(error))
                }
            } receiveValue: { [weak self] snapshot in
                guard let self = self else { return }
                if chatMessages.isEmpty {
                    let firstResult = snapshot.documents.compactMap { try? $0.data(as: Message.self) }
                    chatMessages = firstResult
                    output.send(.updateChatRoom)
                    return
                }

                snapshot.documentChanges.forEach { diff in
                    do {
                        let message = try diff.document.data(as: Message.self)
                        switch diff.type {
                        case .added:
                            self.chatMessages.append(message)
                        case .modified:
                            if let index = self.chatMessages.firstIndex(where: { $0.id == message.id }) {
                                self.chatMessages[index].sendTime = message.sendTime
                            }

                        default:
                            break
                        }
                    } catch {
                        print("Decode error...")
                    }
                }
                output.send(.updateChatRoom)
            }
            .store(in: &cancelBags)
    }

    private func sendMessage(_ text: String) {
        guard let tripId = trip.id else { return }
        fsManager.sendMessage(text, at: tripId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .finished:
                    output.send(.updateChatRoom)
                case .failure(let error):
                    output.send(.displayError(error))
                }
            } receiveValue: { _ in }
            .store(in: &cancelBags)
    }
}
