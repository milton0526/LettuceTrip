//
//  FireStoreManager.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/21.
//

import Foundation
import FirebaseFirestore

class FireStoreManager {

    static let shared = FireStoreManager()

    private init() { }

    enum CollectionRef: String {
        case users
        case trips
        case shareTrips
        case chatRoom
        case places
    }

    private let database = Firestore.firestore()

    var userID: String? {
        UserDefaults.standard.string(forKey: "userID")
    }

    func addDocument(at collection: CollectionRef, data: Encodable) {
        let ref = database.collection(collection.rawValue)

        do {
            try ref.addDocument(from: data)
            print("Successfully add new document at collection: \(collection.rawValue)")
        } catch {
            print("Failed to add new doc in Firebase collection: \(collection.rawValue)")
        }
    }

    func addPlace(_ place: Place, to trip: Trip) {
        guard let tripID = trip.id else { return }
        let ref = database.collection(CollectionRef.trips.rawValue).document(tripID).collection(CollectionRef.places.rawValue)

        do {
            try ref.addDocument(from: place)
            print("Successfully add new place at tripID: \(tripID)")
        } catch {
            print("Failed to add new place at tripID: \(tripID)")
        }
    }

    func getDocument<T: Decodable>(from collection: CollectionRef, docId: String, dataType: T.Type) {
        let ref = database.collection(collection.rawValue)

        ref.document(docId).getDocument(as: dataType) { result in
            switch result {
            case .success(let trip):
                print("Successfully get trip data: \(trip)")
            case .failure(let error):
                print("Failed get trip data: \(error)")
            }
        }
    }

    func fetchAllUserTrips(completion: @escaping (Result<[Trip], Error>) -> Void) {
        guard let userID = userID else { return }
        let ref = database.collection(CollectionRef.trips.rawValue)
        var trips: [Trip] = []

        ref
            .whereField("members", arrayContains: userID)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error getting user trips. \(error.localizedDescription)")
                    completion(.success([]))
                } else {
                    guard let snapshot = snapshot else { return }
                    snapshot.documents.forEach { document in
                        do {
                            let result = try document.data(as: Trip.self)
                            trips.append(result)
                        } catch {
                            completion(.failure(error))
                        }
                    }
                    completion(.success(trips))
                }
            }
    }

    func fetchTripChatRoom(id: String, completion: @escaping (Result<[ChatRoom], Error>) -> Void) {
        let ref = database.collection(CollectionRef.trips.rawValue)
        var chatRoom: [ChatRoom] = []

        ref.document(id).collection(CollectionRef.chatRoom.rawValue).getDocuments { snapshot, error in
            if let error = error {
                print("Error getting documents")
                completion(.failure(error))
            } else {
                guard let snapshot = snapshot else { return }
                snapshot.documents.forEach { document in
                    do {
                        let result = try document.data(as: ChatRoom.self)
                        chatRoom.append(result)
                    } catch {
                        completion(.failure(error))
                    }
                }
                completion(.success(chatRoom))
            }
        }
    }

    func fetchTripPlaces(id: String, completion: @escaping (Result<[Place], Error>) -> Void) {
        let ref = database.collection(CollectionRef.trips.rawValue)
        var chatRoom: [Place] = []

        ref.document(id).collection(CollectionRef.places.rawValue).getDocuments { snapshot, error in
            if let error = error {
                print("Error getting documents")
                completion(.failure(error))
            } else {
                guard let snapshot = snapshot else { return }
                snapshot.documents.forEach { document in
                    do {
                        let result = try document.data(as: Place.self)
                        chatRoom.append(result)
                    } catch {
                        completion(.failure(error))
                    }
                }
                completion(.success(chatRoom))
            }
        }
    }
}
