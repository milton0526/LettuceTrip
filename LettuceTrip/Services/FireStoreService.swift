//
//  FireStoreService.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/21.
//

import Foundation
import FirebaseFirestore

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

    func sendMessage(with message: String, in tripID: String = "uxd7ge3gIVMnBu2jvJBs") {
        guard let userID = userID else { return }
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

    func fetchTripChatRoom(id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        let ref = database.collection(CollectionRef.trips.rawValue)
        var chatRoom: [Message] = []

        ref.document(id).collection(CollectionRef.chatRoom.rawValue).getDocuments { snapshot, error in
            if let error = error {
                print("Error getting documents")
                completion(.failure(error))
            } else {
                guard let snapshot = snapshot else { return }
                snapshot.documents.forEach { document in
                    do {
                        let result = try document.data(as: Message.self)
                        chatRoom.append(result)
                    } catch {
                        completion(.failure(error))
                    }
                }
                completion(.success(chatRoom))
            }
        }
    }

    func addListenerInTripPlaces(tripId: String, completion: @escaping (Result<Place?, Error>) -> Void) -> ListenerRegistration {
        let ref = database.collection(CollectionRef.trips.rawValue)

        let listener = ref
            .document(tripId)
            .collection(CollectionRef.places.rawValue)
            .whereField("isArrange", isEqualTo: false)
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
                            // remove from view then add to arrange section
                            break
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
