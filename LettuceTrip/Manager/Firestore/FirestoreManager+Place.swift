//
//  FirestoreManager+Place.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/8.
//

import Foundation
import Combine
import FirebaseFirestore

extension FirestoreManager {

    func updatePlace(_ place: Place, at tripId: String, isUpdate: Bool = false) -> AnyPublisher<Void, Error> {
        let subDirectory = SubDirectory(documentId: tripId, collection: .places)
        let ref = FirestoreHelper.makeCollectionRef(database, at: .trips, inside: subDirectory)

        return Future { promise in
            do {
                if isUpdate {
                    if let placeId = place.id {
                        try ref.document(placeId).setData(from: place, merge: true) { error in
                            guard error == nil else {
                                return promise(.failure(FirebaseError.update("Place")))
                            }
                            promise(.success(()))
                        }
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

    func copyPlaces(at tripID: String, places: [Place]) -> AnyPublisher<Void, Error> {
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

    func placeListener(at tripId: String, isArrange: Bool = true) -> AnyPublisher<QuerySnapshot, Error> {
        let subDirectory = SubDirectory(documentId: tripId, collection: .places)
        let ref = FirestoreHelper.makeCollectionRef(database, at: .trips, inside: subDirectory)
        let subject = PassthroughSubject<QuerySnapshot, Error>()

        let listener = ref.whereField("isArrange", isEqualTo: isArrange)
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
