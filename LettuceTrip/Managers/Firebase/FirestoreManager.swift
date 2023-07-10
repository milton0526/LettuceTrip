//
//  FirestoreManager.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/8.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

final class FirestoreManager {

    let database = Firestore.firestore()

    var user: String? {
        "LpDb7nvzvSZZcTtJZOld4OS3aEB3"
        // Auth.auth().currentUser?.uid
    }

    // MARK: Trip Method
    func createTrip(_ trip: Trip) -> AnyPublisher<String, Error> {
        let ref = FirestoreHelper.makeCollectionRef(database, at: .trips)
        let docId = ref.document().documentID
        var newTrip = trip
        newTrip.id = docId

        return Future { promise in
            do {
                try ref.document(docId).setData(from: newTrip) { error in
                    guard error == nil else {
                        return promise(.failure(FirebaseError.createTrip))
                    }
                    promise(.success(docId))
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }

    func getTrips(isPublic: Bool = false) -> AnyPublisher<[Trip], Error> {
        let ref = FirestoreHelper.makeCollectionRef(database, at: .trips)
        var allTrips: [Trip] = []

        if isPublic {
            return Future { promise in
                ref.whereField("isPublic", isEqualTo: true)
                    .limit(to: 10)
                    .getDocuments { snapshot, error in
                        guard error == nil else {
                            return promise(.failure(FirebaseError.get))
                        }
                        snapshot?.documents.forEach { doc in
                            if let trip = try? doc.data(as: Trip.self) {
                                allTrips.append(trip)
                            }
                        }
                        promise(.success(allTrips))
                    }
            }.eraseToAnyPublisher()
        } else {
            return Future { [unowned self] promise in
                ref.whereField("members", arrayContains: self.user)
                    .getDocuments { snapshot, error in
                        guard error == nil else {
                            return promise(.failure(FirebaseError.get))
                        }
                        snapshot?.documents.forEach { doc in
                            if let trip = try? doc.data(as: Trip.self) {
                                allTrips.append(trip)
                            }
                        }
                        promise(.success(allTrips))
                    }
            }.eraseToAnyPublisher()
        }
    }

    func update(_ trip: Trip, with userId: String? = nil, isRemove: Bool = false) -> AnyPublisher<Void, Error> {
        guard let tripId = trip.id else {
            return Fail(error: FirebaseError.wrongId(trip.id)).eraseToAnyPublisher()
        }

        let ref = FirestoreHelper.makeCollectionRef(database, at: .trips).document(tripId)

        if let userId = userId {
            return Future { promise in
                ref.updateData([
                    "members": isRemove ? FieldValue.arrayRemove([userId]) : FieldValue.arrayUnion([userId])
                ]) { error in
                    guard error == nil else {
                        return promise(.failure(FirebaseError.update("Member")))
                    }
                    promise(.success(()))
                }
            }.eraseToAnyPublisher()
        } else {
            return Future { promise in
                do {
                    try ref.setData(from: trip, merge: true) { error in
                        guard error == nil else {
                            return promise(.failure(FirebaseError.update("Trip")))
                        }
                        promise(.success(()))
                    }
                } catch {
                    promise(.failure(error))
                }
            }.eraseToAnyPublisher()
        }
    }

    func delete(_ tripId: String, place placeId: String? = nil) -> AnyPublisher<Void, Error> {
        let ref: DocumentReference

        if let placeId = placeId {
            let subDirectory = SubDirectory(documentId: tripId, collection: .places)
            ref = FirestoreHelper.makeCollectionRef(database, at: .trips, inside: subDirectory).document(placeId)
        } else {
            ref = FirestoreHelper.makeCollectionRef(database, at: .trips).document(tripId)
        }

        return Future { promise in
            ref.delete { error in
                guard error == nil else {
                    return promise(.failure(FirebaseError.delete))
                }
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    func tripListener() -> AnyPublisher<QuerySnapshot, Error> {
        guard let user = user else {
            return Fail(error: FirebaseError.wrongId(user)).eraseToAnyPublisher()
        }

        let ref = FirestoreHelper.makeCollectionRef(database, at: .trips)
        let subject = PassthroughSubject<QuerySnapshot, Error>()

        let listener = ref.whereField("members", arrayContains: user)
            .addSnapshotListener { querySnapshot, error in
                guard let querySnapshot = querySnapshot, error == nil else {
                    // swiftlint: disable force_unwrapping
                    return subject.send(completion: .failure(error!))
                    // swiftlint: enable force_unwrapping
                }
                subject.send(querySnapshot)
            }

        return subject.handleEvents(receiveCancel: listener.remove).eraseToAnyPublisher()
    }
}
