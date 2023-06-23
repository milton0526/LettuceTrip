//
//  GoogleServiceManager.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import Foundation
import GooglePlaces

protocol GooglePlaceServiceType {
    func fetchPlaceDetail(by placeID: String, completion: @escaping (Result<GMSPlace, Error>) -> Void)
    func fetchPlacePhoto(with metaData: GMSPlacePhotoMetadata, completion: @escaping (Result<(UIImage, String?), Error>) -> Void)
}

class GooglePlaceService: GooglePlaceServiceType {

    private let placesClient = GMSPlacesClient.shared()

    func fetchPlaceDetail(by placeID: String, completion: @escaping (Result<GMSPlace, Error>) -> Void) {
        let fields: GMSPlaceField = [
            .name, .coordinate, .formattedAddress,
            .businessStatus, .photos, .rating,
            .openingHours, .website, .userRatingsTotal
        ]

        placesClient.fetchPlace(fromPlaceID: placeID, placeFields: fields, sessionToken: nil) { place, error in
            if let error = error {
                print("An error occur while fetch place detail: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            if let place = place {
                completion(.success(place))
            }
        }
    }

    func fetchPlacePhoto(with metaData: GMSPlacePhotoMetadata, completion: @escaping (Result<(UIImage, String?), Error>) -> Void) {

        placesClient.loadPlacePhoto(metaData) { image, error in
            if let error = error {
                print("An error occur while fetch place photos: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            if let image = image {
                let attribution = String(describing: metaData.attributions)
                completion(.success((image, attribution)))
            }
        }
    }
}
