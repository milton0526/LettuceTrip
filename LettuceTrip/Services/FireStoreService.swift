//
//  FireStoreService.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/21.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class FireStoreService {

    static let shared = FireStoreService()

    private init() { }

    enum CollectionRef: String {
        case users
        case trips
        case shareTrips
        case chatRoom
        case places
    }

    private let database = Firestore.firestore()

    var currentUser: String? {
        // Test user id
        "U3K16S3A8vduG71uXhEq6GDkStg2"
        // Auth.auth().currentUser?.uid
    }

    func createUser(id: String, user: User, completion: @escaping (Result<User, Error>) -> Void) {
        let ref = database.collection(CollectionRef.users.rawValue)

        do {
            try ref.document(id).setData(from: user)
            completion(.success(user))
        } catch {
            print("Failed to add new user to Firebase")
            completion(.failure(error))
        }
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

    func updatePlace(_ place: Place, to trip: Trip, update: Bool = false, completion: @escaping (Bool) -> Void) {
        guard let tripID = trip.id else { return }
        let ref = database.collection(CollectionRef.trips.rawValue).document(tripID).collection(CollectionRef.places.rawValue)

        do {
            if update {
                guard let placeID = place.id else { return }
                try ref.document(placeID).setData(from: place, merge: true)
            } else {
                try ref.addDocument(from: place)
            }
            completion(true)
            print("Successfully add new place at tripID: \(tripID)")
        } catch {
            completion(false)
            print("Failed to add new place at tripID: \(tripID)")
        }
    }

    func sendMessage(with message: String, in tripID: String = "uxd7ge3gIVMnBu2jvJBs") {
        guard let userID = currentUser else { return }
        let ref = database.collection(CollectionRef.trips.rawValue).document(tripID).collection(CollectionRef.chatRoom.rawValue)
        let sendMessage = Message(userID: userID, message: message)

        do {
            try ref.addDocument(from: sendMessage)
            print("Successfully add new message at tripID: \(tripID)")
        } catch {
            print("Failed to add new message at tripID: \(tripID)")
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
        guard let userID = currentUser else { return }
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

    func addListenerInTripPlaces(tripId: String, isArrange: Bool = true, completion: @escaping (Result<Place?, Error>) -> Void) -> ListenerRegistration {
        let ref = database.collection(CollectionRef.trips.rawValue)

        let listener = ref
            .document(tripId)
            .collection(CollectionRef.places.rawValue)
            .whereField("isArrange", isEqualTo: isArrange)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error getting documents")
                    completion(.failure(error))
                } else {
                    guard let snapshot = snapshot else { return }

                    snapshot.documentChanges.forEach { diff in
                        switch diff.type {
                        case .added:
                            let place = try? diff.document.data(as: Place.self)
                            completion(.success(place))
                        case .modified, .removed:
                            completion(.success(nil))
                        }
                    }
                }
            }
        return listener
    }

    func addListenerToChatRoom(by tripID: String = "uxd7ge3gIVMnBu2jvJBs", completion: @escaping (Result<Message?, Error>) -> Void) -> ListenerRegistration {
        let ref = database.collection(CollectionRef.trips.rawValue)

        let listener = ref
            .document(tripID)
            .collection(CollectionRef.chatRoom.rawValue)
            .order(by: "sendTime")
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error getting documents")
                    completion(.failure(error))
                } else {
                    guard let snapshot = snapshot else { return }

                    snapshot.documentChanges.forEach { diff in
                        switch diff.type {
                        case .added:
                            let message = try? diff.document.data(as: Message.self)
                            completion(.success(message))
                        default:
                            break
                        }
                    }
                }
            }
        return listener
    }
}
