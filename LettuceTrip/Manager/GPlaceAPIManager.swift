//
//  GPlaceAPIManager.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/1.
//

import UIKit
import Combine
import CoreLocation
import GooglePlaces

protocol GooglePlaceServiceType {

    func findPlaceFromText(_ text: String, location: CLLocationCoordinate2D) -> AnyPublisher<GPlaceResponse, Error>

    func fetchPlace(id: String) -> AnyPublisher<GMSPlace, Error>

    func fetchPhotos(metaData: GMSPlacePhotoMetadata) -> AnyPublisher<UIImage, Error>
}

class GPlaceAPIManager: GooglePlaceServiceType {

    private var languageCode: String? {
        Locale.current.language.languageCode?.identifier
    }

    private let decoder = JSONDecoder()
    private let client = GMSPlacesClient()

    func findPlaceFromText(_ text: String, location: CLLocationCoordinate2D) -> AnyPublisher<GPlaceResponse, Error> {
        guard
            let languageCode = languageCode,
            let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let key = appDelegate.apiKey,
            let searchText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else {
            return Empty().eraseToAnyPublisher()
        }

        let latitude = String(describing: location.latitude)
        let longitude = String(describing: location.longitude)
        let urlString = "https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=\(searchText)&inputtype=textquery&locationbias=point%3A\(latitude)%2C\(longitude)&language=\(languageCode)&key=\(key)"

        guard let url = URL(string: urlString) else { return Empty().eraseToAnyPublisher() }

        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { element -> Data in
                guard
                    let httpResponse = element.response as? HTTPURLResponse,
                    httpResponse.statusCode == 200
                else {
                    throw URLError(.badServerResponse)
                }
                return element.data
            }
            .decode(type: GPlaceResponse.self, decoder: decoder)
            .eraseToAnyPublisher()
    }

    func fetchPlace(id: String) -> AnyPublisher<GMSPlace, Error> {
        let placeField: GMSPlaceField = [.name, .formattedAddress, .openingHours, .photos, .website, .rating]
        return client.fetchPlace(id: id, fields: placeField).eraseToAnyPublisher()
    }

    func fetchPhotos(metaData: GMSPlacePhotoMetadata) -> AnyPublisher<UIImage, Error> {
        let size = CGSize(width: 800, height: 600)
        let scale: CGFloat = 1.0
        return client.loadPlacePhoto(photoMetadata: metaData, constrainedTo: size, scale: scale).eraseToAnyPublisher()
    }
}
