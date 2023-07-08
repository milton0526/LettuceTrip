//
//  FirestoreManager.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/8.
//

import Foundation
import Combine
import FirebaseFirestore

final class FirestoreManager {

    let userId: String
    private let database = Firestore.firestore()

    init(userId: String) {
        self.userId = userId
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
                ref.whereField("isPublic", isEqualTo: true).limit(to: 10)
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
                ref.whereField("members", arrayContains: self.userId)
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

    func update(_ trip: Trip, with userId: String? = nil) -> AnyPublisher<Void, Error> {
        guard let tripId = trip.id else {
            return Fail(error: FirebaseError.wrongId(trip.id)).eraseToAnyPublisher()
        }

        let ref = FirestoreHelper.makeCollectionRef(database, at: .trips).document(tripId)

        if let userId = userId {
            return Future { promise in
                ref.updateData([
                    "members": FieldValue.arrayUnion([userId])
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

    func delete(_ tripId: String, and placeId: String? = nil) -> AnyPublisher<Void, Error> {
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

    func userTripsListener(completion: @escaping (Result<[Trip], Error>) -> Void) -> ListenerRegistration {
        let ref = FirestoreHelper.makeCollectionRef(database, at: .trips)
        var allTrips: [Trip] = []

        let listener = ref.whereField("members", arrayContains: userId)
            .addSnapshotListener { snapshot, error in
                guard error == nil else {
                    completion(.failure(FirebaseError.listenerError("UserTrips")))
                    return
                }
                snapshot?.documentChanges.forEach { diff in

                    do {
                        let trip = try diff.document.data(as: Trip.self)

                        switch diff.type {
                        case .added:
                            allTrips.append(trip)
                        case .modified:
                            if let index = allTrips.firstIndex(where: { $0.id == trip.id }) {
                                allTrips[index].image = trip.image
                            }
                        case .removed:
                            if let index = allTrips.firstIndex(where: { $0.id == trip.id }) {
                                allTrips.remove(at: index)
                            }
                        }
                    } catch {
                        completion(.failure(error))
                    }
                }
                completion(.success(allTrips))
            }
        return listener
    }

    // MARK: Place Method
    func updatePlace(_ place: Place, at tripId: String, isUpdate: Bool = false) -> AnyPublisher<Void, Error> {
        guard let placeId = place.id else {
            return Fail(error: FirebaseError.wrongId(place.id)).eraseToAnyPublisher()
        }

        let subDirectory = SubDirectory(documentId: tripId, collection: .places)
        let ref = FirestoreHelper.makeCollectionRef(database, at: .trips, inside: subDirectory)

        return Future { promise in
            do {
                if isUpdate {
                    try ref.document(placeId).setData(from: place, merge: true) { error in
                        guard error == nil else {
                            return promise(.failure(FirebaseError.update("Place")))
                        }
                        promise(.success(()))
                    }
                } else {
                    try ref.addDocument(from: place) { error in
                        guard error == nil else {
                            return promise(.failure(FirebaseError.update("Place")))
                        }
                        promise(.success(()))
                    }
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }

    func copyPlaces(at tripID: String, with places: [Place]) -> AnyPublisher<Void, Error> {
        let batch = database.batch()
        let subDirectory = SubDirectory(documentId: tripID, collection: .places)
        let baseRef = FirestoreHelper.makeCollectionRef(database, at: .trips, inside: subDirectory)

        places.forEach { place in
            if let placeID = place.id {
                do {
                    try batch.setData(from: place, forDocument: baseRef.document(placeID))
                } catch {
                    print("Error set batch update copy places: \(error.localizedDescription)")
                }
            }
        }

        return Future { promise in
            batch.commit { error in
                guard error == nil else {
                    return promise(.failure(FirebaseError.copy))
                }
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    func batchUpdatePlaces(at trip: Trip, from source: Place, to destination: Place) -> AnyPublisher<Void, Error> {
        guard
            let tripId = trip.id,
            let sourceId = source.id,
            let destinationId = destination.id
        else {
            return Fail(error: FirebaseError.update("Batch update place.")).eraseToAnyPublisher()
        }

        let batch = database.batch()
        let subDirectory = SubDirectory(documentId: tripId, collection: .places)
        let baseRef = FirestoreHelper.makeCollectionRef(database, at: .trips, inside: subDirectory)

        do {
            try batch.setData(from: source, forDocument: baseRef.document(sourceId), merge: true)
            try batch.setData(from: destination, forDocument: baseRef.document(destinationId), merge: true)
        } catch {
            print("Error set batch update items: \(error.localizedDescription)")
        }

        return Future { promise in
            batch.commit { error in
                guard error == nil else {
                    return promise(.failure(FirebaseError.update("Batch update places")))
                }
                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    func placeListener(at tripId: String, isArrange: Bool = true, completion: @escaping (Result<[Place], Error>) -> Void) -> ListenerRegistration {
        let subDirectory = SubDirectory(documentId: tripId, collection: .places)
        let ref = FirestoreHelper.makeCollectionRef(database, at: .trips, inside: subDirectory)
        var allPlaces: [Place] = []

        let listener = ref.whereField("isArrange", isEqualTo: isArrange)
            .addSnapshotListener { snapshot, error in
                guard error == nil else {
                    completion(.failure(FirebaseError.listenerError("Place")))
                    return
                }

                snapshot?.documentChanges.forEach { diff in
                    do {
                        let place = try diff.document.data(as: Place.self)

                        switch diff.type {
                        case .added:
                            allPlaces.append(place)
                        case .modified:
                            if let index = allPlaces.firstIndex(where: { $0.id == place.id }) {
                                allPlaces[index].arrangedTime = place.arrangedTime
                            }
                        case .removed:
                            if let index = allPlaces.firstIndex(where: { $0.id == place.id }) {
                                allPlaces.remove(at: index)
                            }
                        }
                    } catch {
                        completion(.failure(error))
                    }
                    completion(.success(allPlaces))
                }
            }
        return listener
    }

    // MARK: ChatRoom Method
    func sendMessage(_ message: Message, at tripId: String) -> AnyPublisher<Void, Error> {
        let subDirectory = SubDirectory(documentId: tripId, collection: .chatRoom)
        let ref = FirestoreHelper.makeCollectionRef(database, at: .trips, inside: subDirectory)

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
}
