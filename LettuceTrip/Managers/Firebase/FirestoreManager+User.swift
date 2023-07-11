//
//  FirestoreManager+User.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/8.
//

import Foundation
import Combine
import FirebaseFirestore

extension FirestoreManager {

    func createUser(id: String, user: LTUser) -> AnyPublisher<Void, Error> {
        let ref = FirestoreHelper.makeCollectionRef(database, at: .users)

        return Future { promise in
            do {
                try ref.document(id).setData(from: user) { error in
                    guard error == nil else {
                        return promise(.failure(FirebaseError.user("Failed to create user")))
                    }
                    promise(.success(()))
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }

    func getUserData(userId: String?) -> AnyPublisher<LTUser, Error> {
        guard let userId = userId else {
            return Fail(error: FirebaseError.wrongId(userId)).eraseToAnyPublisher()
        }
        let ref = FirestoreHelper.makeCollectionRef(database, at: .users)

        return Future { promise in
            ref.document(userId).getDocument(as: LTUser.self) { result in
                switch result {
                case .success(let user):
                    promise(.success(user))
                case .failure:
                    promise(.failure(FirebaseError.get))
                }
            }
        }.eraseToAnyPublisher()
    }

    func updateUser(image: String) -> AnyPublisher<Void, Error> {
        guard let userId = user else {
            return Fail(error: FirebaseError.wrongId(user)).eraseToAnyPublisher()
        }
        let ref = FirestoreHelper.makeCollectionRef(database, at: .users)

        return Future { promise in
            ref.document(userId).updateData([
                "image": image
            ]) { error in
                guard error == nil else {
                    return promise(.failure(FirebaseError.user("Failed to update user image.")))
                }
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    func updateMember(userId: String, atTrip tripId: String, isRemove: Bool = false) -> AnyPublisher<Void, Error> {
        let ref = FirestoreHelper.makeCollectionRef(database, at: .trips).document(tripId)

        return Future { promise in
            ref.updateData([
                "members": isRemove ? FieldValue.arrayRemove([userId]) : FieldValue.arrayUnion([userId])
            ]) { error in
                guard error == nil else {
                    return promise(.failure(FirebaseError.user("Failed to update member.")))
                }
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    func deleteUser(userId: String) -> AnyPublisher<Void, Error> {
        let ref = FirestoreHelper.makeCollectionRef(database, at: .users)

        return Future { promise in
            ref.document(userId).delete { error in
                guard error == nil else {
                    return promise(.failure(FirebaseError.user("Failed to delete user")))
                }
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    func checkUserExist(id: String) -> AnyPublisher<Bool, Error> {
        let ref = FirestoreHelper.makeCollectionRef(database, at: .users).document(id)

        return Future { promise in
            ref.getDocument { document, error in
                guard error == nil else {
                    // swiftlint: disable force_unwrapping
                    return promise(.failure(error!))
                    // swiftlint: enable force_unwrapping
                }

                if let document = document, document.exists {
                    promise(.success(true))
                } else {
                    promise(.success(false))
                }
            }
        }.eraseToAnyPublisher()
    }
}
