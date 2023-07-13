//
//  StorageManager.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/10.
//

import Foundation
import Combine
import FirebaseStorage

final class StorageManager {

    enum StoragePath: String {
        case users
        case trips
    }

    private let storage = Storage.storage()

    func uploadImage(_ imageData: Data, at path: StoragePath, with id: String) -> AnyPublisher<Void, Error> {
        let imageRef = storage.reference().child("\(path.rawValue)/\(id).jpg")

        return Future { promise in
            imageRef.putData(imageData) { _, error in
                if let error = error {
                    return promise(.failure(error))
                }

                promise(.success(()))
            }
        }.eraseToAnyPublisher()
    }

    func downloadRef(at path: StoragePath, with id: String) -> AnyPublisher<URL, Error> {
        let imageRef = storage.reference().child("\(path.rawValue)/\(id).jpg")

        return Future { promise in
            imageRef.downloadURL { url, error in
                guard
                    let url = url,
                    error == nil else {
                    return promise(.failure(error!))
                }
                promise(.success(url))
            }
        }.eraseToAnyPublisher()
    }
}
