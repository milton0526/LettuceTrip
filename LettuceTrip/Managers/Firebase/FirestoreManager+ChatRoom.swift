//
//  FirestoreManager+ChatRoom.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/8.
//

import Foundation
import Combine
import FirebaseFirestore

extension FirestoreManager {

    enum ListenerType<T: Decodable> {
        case add(T)
        case modify(T)
        case removed(T)
    }

    func sendMessage(_ text: String, at tripId: String) -> AnyPublisher<Void, Error> {
        guard let userId = user else {
            return Fail(error: FirebaseError.wrongId(user)).eraseToAnyPublisher()
        }

        let subDirectory = SubDirectory(documentId: tripId, collection: .chatRoom)
        let ref = FirestoreHelper.makeCollectionRef(database, at: .trips, inside: subDirectory)
        let message = Message(userID: userId, message: text)

        return Future { promise in
            do {
                try ref.addDocument(from: message) { error in
                    guard error == nil else {
                        return promise(.failure(FirebaseError.sendMessage))
                    }
                    promise(.success(()))
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }

    func chatRoomListener(_ tripId: String, completion: @escaping (Result<[Message], Error>) -> Void) -> ListenerRegistration {
        let subDirectory = SubDirectory(documentId: tripId, collection: .chatRoom)
        let ref = FirestoreHelper.makeCollectionRef(database, at: .trips, inside: subDirectory)
        var allMessages: [Message] = []

        let listener =
        ref.order(by: "sendTime").addSnapshotListener { snapshot, error in
            guard error == nil else {
                completion(.failure(FirebaseError.listenerError("ChatRoom")))
                return
            }

            snapshot?.documentChanges.forEach { diff in
                do {
                    let message = try diff.document.data(as: Message.self)
                    switch diff.type {
                    case .added:
                        allMessages.append(message)
                    case .modified:
                        if let index = allMessages.firstIndex(where: { $0.id == message.id }) {
                            allMessages[index].sendTime = message.sendTime
                        }
                    default:
                        break
                    }
                } catch {
                    completion(.failure(error))
                }
            }
            completion(.success(allMessages))
        }

        return listener
    }

    func chatRoomListener(_ tripId: String) -> AnyPublisher<QuerySnapshot, Error> {
        let subDirectory = SubDirectory(documentId: tripId, collection: .chatRoom)
        let ref = FirestoreHelper.makeCollectionRef(database, at: .trips, inside: subDirectory)
        let subject = PassthroughSubject<QuerySnapshot, Error>()

        let listener = ref.order(by: "sendTime")
            .addSnapshotListener { querySnapshot, error in
                guard let querySnapshot = querySnapshot else {
                    return subject.send(completion: .failure(error!))
                }
                subject.send(querySnapshot)
            }

        return subject.handleEvents(receiveCancel: listener.remove).eraseToAnyPublisher()
    }
}
