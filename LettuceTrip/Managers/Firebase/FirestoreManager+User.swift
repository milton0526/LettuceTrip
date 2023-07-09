//
//  FirestoreManager+User.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/8.
//

import Foundation
import Combine

extension FirestoreManager {

    func createUser(id: String, user: User) -> AnyPublisher<Void, Error> {
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

    func getUserData(userId: String?) -> AnyPublisher<User, Error> {
        guard let userId = userId else {
            return Fail(error: FirebaseError.wrongId(userId)).eraseToAnyPublisher()
        }
        let ref = FirestoreHelper.makeCollectionRef(database, at: .users)

        return Future { promise in
            ref.document(userId).getDocument(as: User.self) { result in
                switch result {
                case .success(let user):
                    promise(.success(user))
                case .failure:
                    promise(.failure(FirebaseError.get))
                }
            }
        }.eraseToAnyPublisher()
    }

    func deleteUser() -> AnyPublisher<Void, Error> {
        guard let userId = userId else {
            return Fail(error: FirebaseError.wrongId(userId)).eraseToAnyPublisher()
        }
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
}
