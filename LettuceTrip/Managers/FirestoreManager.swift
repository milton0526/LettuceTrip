//
//  FirestoreManager.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/8.
//

import Foundation
import Combine
import FirebaseFirestore

protocol FirebaseService: AnyObject {
}


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

    func updateTrip(_ trip: Trip) -> AnyPublisher<Void, Error> {
        guard let tripId = trip.id else {
            return Fail(error: FirebaseError.wrongId(trip.id)).eraseToAnyPublisher()
        }

        let ref = FirestoreHelper.makeCollectionRef(database, at: .trips)

        return Future { promise in
            do {
                try ref.document(tripId).setData(from: trip, merge: true) { error in
                    guard error == nil else {
                        return promise(.failure(FirebaseError.updateTrip))
                    }
                    promise(.success(()))
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }

    func userTripsListener(completion: @escaping (Result<[Trip], Error>) -> Void) -> ListenerRegistration {
        let ref = FirestoreHelper.makeCollectionRef(database, at: .trips)
        var allTrips: [Trip] = []

        let listener = ref.whereField("members", arrayContains: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
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
                            return promise(.failure(FirebaseError.updatePlace))
                        }
                        promise(.success(()))
                    }
                } else {
                    try ref.addDocument(from: place) { error in
                        guard error == nil else {
                            return promise(.failure(FirebaseError.updatePlace))
                        }
                        promise(.success(()))
                    }
                }
            } catch {
                promise(.failure(error))
            }
        }.eraseToAnyPublisher()
    }

    func placeListener(at tripId: String, isArrange: Bool = true, completion: @escaping (Result<[Place], Error>) -> Void) -> ListenerRegistration {
        let subDirectory = SubDirectory(documentId: tripId, collection: .places)
        let ref = FirestoreHelper.makeCollectionRef(database, at: .trips, inside: subDirectory)
        var allPlaces: [Place] = []

        let listener = ref.whereField("isArrange", isEqualTo: isArrange)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    completion(.failure(error))
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
            if let error = error {
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
