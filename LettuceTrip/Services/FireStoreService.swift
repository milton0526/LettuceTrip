//
//  FireStoreService.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/21.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// swiftlint: disable type_body_length
class FireStoreService {

    static let shared = FireStoreService()

    private init() { }

    enum CollectionRef: String {
        case users
        case trips
        case chatRoom
        case places
    }

    private let database = Firestore.firestore()

    var currentUser: String? {
        // Test user id
        "LpDb7nvzvSZZcTtJZOld4OS3aEB3"
        // Auth.auth().currentUser?.uid
    }

    func signOut(completion: @escaping (Error?) -> Void) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            completion(nil)
        } catch {
            completion(error)
            print("Error signing out: \(error.localizedDescription)")
        }
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

    func updateDeviceToken(token: String?) {
        guard
            let currentUser = currentUser,
            let token = token
        else {
            return
        }

        let ref = database.collection(CollectionRef.users.rawValue).document(currentUser)

        ref.updateData([
            "deviceToken": token
        ]) { error in
            if let error = error {
                print("Error update device token: \(error.localizedDescription)")
            } else {
                print("Successfully update device token.")
            }
        }
    }

    func deleteUserInFireStore() {
        guard let currentUser = currentUser else { return }
        database.collection(CollectionRef.users.rawValue).document(currentUser).delete()
    }

    func addNewTrip(at collection: CollectionRef, trip: Trip, completion: @escaping (Result<String, Error>) -> Void) {
        let ref = database.collection(collection.rawValue)
        let tempID = ref.document().documentID
        var newTrip = trip
        newTrip.id = tempID

        do {
            try ref.document(tempID).setData(from: newTrip)
            completion(.success((tempID)))
            print("Successfully add new document at collection: \(collection.rawValue)")
        } catch {
            completion(.failure(error))
            print("Failed to add new doc in Firebase collection: \(collection.rawValue)")
        }
    }

    func updatePlace(_ place: Place, to trip: Trip, update: Bool = false, completion: @escaping (Error?) -> Void) {
        guard let tripID = trip.id else { return }
        let ref = database.collection(CollectionRef.trips.rawValue).document(tripID).collection(CollectionRef.places.rawValue)

        do {
            if update {
                guard let placeID = place.id else { return }
                try ref.document(placeID).setData(from: place, merge: true)
            } else {
                try ref.addDocument(from: place)
            }
            completion(nil)
            print("Successfully add new place at tripID: \(tripID)")
        } catch {
            completion(error)
            print("Failed to add new place at tripID: \(tripID)")
        }
    }

    func batchUpdateInOrder(at trip: Trip, from source: Place, to destination: Place, completion: @escaping (Result<Void, Error>) -> Void) {
        guard
            let tripID = trip.id,
            let sourceID = source.id,
            let destinationID = destination.id
        else {
            return
        }

        let batch = database.batch()
        let baseRef = database.collection(CollectionRef.trips.rawValue).document(tripID).collection(CollectionRef.places.rawValue)

        do {
            try batch.setData(from: source, forDocument: baseRef.document(sourceID), merge: true)
            try batch.setData(from: destination, forDocument: baseRef.document(destinationID), merge: true)
        } catch {
            print("Error set batch update items: \(error.localizedDescription)")
        }

        batch.commit { error in
            if let error = error {
                completion(.failure(error))
                print("Error to commit batch: \(error.localizedDescription)")
            } else {
                completion(.success(()))
                print("Successfully update batch.")
            }
        }
    }

    func copyPlaces(tripID: String, places: [Place], completion: @escaping (Result<Void, Error>) -> Void) {
        let batch = database.batch()
        let baseRef = database.collection(CollectionRef.trips.rawValue).document(tripID).collection(CollectionRef.places.rawValue)

        places.forEach { place in
            if let placeID = place.id {
                do {
                    try batch.setData(from: place, forDocument: baseRef.document(placeID))
                } catch {
                    print("Error set batch update copy places: \(error.localizedDescription)")
                }
            }
        }

        batch.commit { error in
            if let error = error {
                completion(.failure(error))
                print("Error to commit batch: \(error.localizedDescription)")
            } else {
                completion(.success(()))
                print("Successfully update copy batch.")
            }
        }
    }

    func updateMembers(userID: String, at tripID: String, completion: @escaping (Error?) -> Void) {
        let ref = database.collection(CollectionRef.trips.rawValue).document(tripID)

        ref.updateData([
            "members": FieldValue.arrayUnion([userID])
        ]) { error in
            completion(error)
        }
    }

    func deleteDocument(id: String) {
        database.collection(CollectionRef.trips.rawValue).document(id).delete { error in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("Delete successfully")
            }
        }
    }

    func deletePlace(at trip: Trip, place: Place) {
        guard let tripID = trip.id, let placeID = place.id else { return }
        database.collection(CollectionRef.trips.rawValue)
            .document(tripID)
            .collection(CollectionRef.places.rawValue)
            .document(placeID)
            .delete { error in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    print("Delete successfully")
                }
            }
    }

    func updateTrip(trip: Trip, completion: @escaping (Error?) -> Void) {
        guard let tripID = trip.id else { return }

        let ref = database.collection(CollectionRef.trips.rawValue).document(tripID)

        do {
            try ref.setData(from: trip, merge: true)
            completion(nil)
        } catch {
            print("Error update trip state")
            completion(error)
        }
    }

    func sendMessage(with message: String, in tripID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userID = currentUser else { return }
        let ref = database.collection(CollectionRef.trips.rawValue).document(tripID).collection(CollectionRef.chatRoom.rawValue)
        let sendMessage = Message(userID: userID, message: message)

        do {
            try ref.addDocument(from: sendMessage)
            completion(.success(()))
            print("Successfully add new message at tripID: \(tripID)")
        } catch {
            completion(.failure(error))
            print("Failed to add new message at tripID: \(tripID)")
        }
    }

    func getUserData(userId: String?, completion: @escaping (Result<User, Error>) -> Void) {
        guard let userId = userId else { return }
        let ref = database.collection(CollectionRef.users.rawValue)

        ref.document(userId).getDocument(as: User.self) { result in
            switch result {
            case .success(let user):
                completion(.success(user))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchShareTrips(completion: @escaping (Result<[Trip], Error>) -> Void) {
        let ref = database.collection(CollectionRef.trips.rawValue)
        var trips: [Trip] = []

        ref
            .whereField("isPublic", isEqualTo: true)
            .limit(to: 10)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error getting Share trips")
                    completion(.failure(error))
                } else {
                    guard let snapshot = snapshot else { return }
                    snapshot.documents.forEach { doc in
                        if let trip = try? doc.data(as: Trip.self) {
                            trips.append(trip)
                        }
                    }
                    completion(.success(trips))
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
                    completion(.failure(error))
                } else {
                    guard let snapshot = snapshot else { return }
                    snapshot.documents.forEach { doc in

                        if let trip = try? doc.data(as: Trip.self) {
                            trips.append(trip)
                        }
                    }
                    completion(.success(trips))
                }
            }
    }

    func addListenerToAllUserTrips(completion: @escaping (Result<[Trip], Error>) -> Void) -> ListenerRegistration? {
        guard let userID = currentUser else { return nil }
        let ref = database.collection(CollectionRef.trips.rawValue)
        var trips: [Trip] = []

        let listener = ref
            .whereField("members", arrayContains: userID)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error getting user trips. \(error.localizedDescription)")
                    completion(.success([]))
                } else {
                    guard let snapshot = snapshot else { return }

                    snapshot.documentChanges.forEach { diff in
                        switch diff.type {
                        case .added:
                            if let trip = try? diff.document.data(as: Trip.self) {
                                trips.append(trip)
                            }

                        case .modified:
                            if let modifyTrip = try? diff.document.data(as: Trip.self) {
                                if let index = trips.firstIndex(where: { $0.id == modifyTrip.id }) {
                                    trips[index].image = modifyTrip.image
                                }
                            }

                        case .removed:
                            if let removedTrip = try? diff.document.data(as: Trip.self) {
                                if let index = trips.firstIndex(where: { $0.id == removedTrip.id }) {
                                    trips.remove(at: index)
                                }
                            }
                        }
                    }
                    completion(.success(trips))
                }
            }

        return listener
    }

    func addListenerInTripPlaces(tripId: String, isArrange: Bool = true, completion: @escaping (Result<[Place], Error>) -> Void) -> ListenerRegistration {
        let ref = database.collection(CollectionRef.trips.rawValue)
        var places: [Place] = []

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
                            if let place = try? diff.document.data(as: Place.self) {
                                places.append(place)
                            }

                        case .modified:
                            if let modifiedPlace = try? diff.document.data(as: Place.self) {
                                if let index = places.firstIndex(where: { $0.id == modifiedPlace.id }) {
                                    places[index].arrangedTime = modifiedPlace.arrangedTime
                                }
                            }

                        case .removed:
                            if let removedPlace = try? diff.document.data(as: Place.self) {
                                if let index = places.firstIndex(where: { $0.id == removedPlace.id }) {
                                    places.remove(at: index)
                                }
                            }
                        }
                    }

                    completion(.success(places))
                }
            }
        return listener
    }

    func addListenerToChatRoom(by tripID: String, completion: @escaping (Result<[Message], Error>) -> Void) -> ListenerRegistration {
        let ref = database.collection(CollectionRef.trips.rawValue)
        var messages: [Message] = []

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
                            if let message = try? diff.document.data(as: Message.self) {
                                messages.append(message)
                            }
                        case .modified:
                            if let modifiedMSG = try? diff.document.data(as: Message.self) {
                                if let index = messages.firstIndex(where: { $0.id == modifiedMSG.id }) {
                                    messages[index].sendTime = modifiedMSG.sendTime
                                }
                            }
                        default:
                            break
                        }
                    }
                    completion(.success(messages))
                }
            }
        return listener
    }
}
// swiftlint: enable type_body_length
