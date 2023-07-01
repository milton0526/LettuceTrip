//
//  GMSPlace+Combine.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/1.
//

import Foundation
import Combine
import GooglePlaces

extension GMSPlacesClient {

    public func loadPlacePhoto(
        photoMetadata: GMSPlacePhotoMetadata,
        constrainedTo size: CGSize,
        scale: CGFloat
    ) -> Future<UIImage, Error> {
        Future<UIImage, Error> { promise in
            self.loadPlacePhoto(photoMetadata, constrainedTo: size, scale: scale) { image, error in
                if let error = error {
                    promise(.failure(error))
                } else if let image = image {
                    promise(.success(image))
                }
            }
        }
    }

    public func fetchPlace(
        id: String,
        fields: GMSPlaceField,
        sessionToken: GMSAutocompleteSessionToken? = nil
    ) -> Future<GMSPlace, Error> {
        Future<GMSPlace, Error> { promise in
            self.fetchPlace(
                fromPlaceID: id,
                placeFields: fields,
                sessionToken: sessionToken
            ) { place, error in
                if let error = error {
                    promise(.failure(error))
                } else if let place = place {
                    promise(.success(place))
                }
            }
        }
    }
}
