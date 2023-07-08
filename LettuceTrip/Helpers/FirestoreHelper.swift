//
//  FirestoreHelper.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/8.
//

import Foundation
import Combine
import FirebaseFirestore

struct SubDirectory {
    let documentId: String
    let collection: FirestoreHelper
}

enum FirestoreHelper: String {
    case users
    case trips
    case chatRoom
    case places

    static func makeCollectionRef(
        _ database: Firestore,
        at root: FirestoreHelper,
        inside subDirectory: SubDirectory? = nil
    ) -> CollectionReference {

        let reference: CollectionReference

        if let subDirectory = subDirectory {
            reference = database
                .collection(root.rawValue)
                .document(subDirectory.documentId)
                .collection(subDirectory.collection.rawValue)
        } else {
            reference = database
                .collection(root.rawValue)
        }

        return reference
    }
}
