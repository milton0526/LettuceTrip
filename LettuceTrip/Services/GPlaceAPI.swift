//
//  GPlaceAPI.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/1.
//

import UIKit
import Combine
import CoreLocation

class GPlaceAPI {

    private var languageCode: String? {
        Locale.current.language.languageCode?.identifier
    }

    private let decoder = JSONDecoder()

//    private func textCombineSearch(_ text: String, location: CLLocationCoordinate2D) -> AnyPublisher<String?, Error> {
//        guard
//            let languageCode = languageCode,
//            let key = key,
//            let searchText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
//        else {
//            return Empty().eraseToAnyPublisher()
//        }
//
//        let latitude = String(describing: location.latitude)
//        let longitude = String(describing: location.longitude)
//
//        let urlString = "https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=\(searchText)&inputtype=textquery&locationbias=point%3A\(latitude)%2C\(longitude)&language=\(languageCode)&key=\(key)"
//
//        guard let url = URL(string: urlString) else {
//            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
//        }
//
//        return URLSession.shared.dataTaskPublisher(for: url)
//            .retry(1)
//            .map(\.data)
//            .decode(type: GPlaceResponse.self, decoder: decoder)
//            .tryMap { result -> String? in
//                guard let placeID = result.candidates.first?.placeID else {
//                    return nil
//                }
//                return placeID
//            }
//            .eraseToAnyPublisher()
//    }

    func findPlaceFromText(_ text: String, location: CLLocationCoordinate2D, completion: @escaping (Result<String?, Error>) -> Void) {
        guard
            let languageCode = languageCode,
            let appDelegate = UIApplication.shared.delegate as? AppDelegate,
            let key = appDelegate.apiKey,
            let searchText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else {
            return
        }

        let latitude = String(describing: location.latitude)
        let longitude = String(describing: location.longitude)
        let urlString = "https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=\(searchText)&inputtype=textquery&locationbias=point%3A\(latitude)%2C\(longitude)&language=\(languageCode)&key=\(key)"

        guard let url = URL(string: urlString) else { return }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let data = data,
                let response = response as? HTTPURLResponse,
                response.statusCode == 200,
                error == nil
            else {
                print("Error fetch: \(error?.localizedDescription ?? "")")
                return
            }

            do {
                let result = try self.decoder.decode(GPlaceResponse.self, from: data)
                completion(.success(result.candidates.first?.placeID))
            } catch {
                print("Decode error: \(error.localizedDescription)")
            }
        }

        task.resume()
    }
}
