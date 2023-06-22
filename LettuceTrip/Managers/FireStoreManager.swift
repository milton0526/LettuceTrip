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
    }

    private let database = Firestore.firestore()

    func addDocument(at collection: CollectionRef, data: Encodable) {
        let ref = database.collection(collection.rawValue)

        do {
            try ref.addDocument(from: data)
            print("Successfully add new document at collection: \(collection.rawValue)")
        } catch {
            print("Failed to add new doc in Firebase collection: \(collection.rawValue)")
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

    func fetchTripChatRoom(id: String, completion: @escaping (Result<[ChatRoom], Error>) -> Void) {
        let ref = database.collection("trips")
        var chatRoom: [ChatRoom] = []

        ref.document(id).collection("chatRoom").getDocuments { snapshot, error in
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
        let ref = database.collection("trips")
        var chatRoom: [Place] = []

        ref.document(id).collection("places").getDocuments { snapshot, error in
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
