//
//  FQService.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/23.
//

import Foundation
import CoreLocation

class FQService {

    struct APIKeyInfo: Decodable {
        let apiKey: String
    }

    private let key: String? = {
        guard let url = Bundle.main.url(forResource: "FQKey", withExtension: "plist") else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let result = try PropertyListDecoder().decode(APIKeyInfo.self, from: data)
            return result.apiKey
        } catch {
            return nil
        }
    }()

    func placeSearch(name: String, coordinate: CLLocationCoordinate2D, completion: @escaping (Result<FQPlace, Error>) -> Void) {
        guard
            let key = key,
            let placeName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else {
            return
        }

        let latitude = String(describing: coordinate.latitude)
        let longitude = String(describing: coordinate.longitude)

        let urlString = "https://api.foursquare.com/v3/places/search?query=\(placeName)&ll=\(latitude)%2C\(longitude)&fields=fsq_id%2Clocation%2Cdescription%2Cphotos%2Ctel%2Cwebsite%2Chours%2Crating%2Cfeatures&sort=POPULARITY&limit=1"

        guard let url = URL(string: urlString) else { return }

        let headers = [
            "accept": "application/json",
            "Authorization": key
        ]

        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                print(error.localizedDescription)
            }

            guard
                let data = data,
                let response = response as? HTTPURLResponse,
                response.statusCode == 200
            else {
                print("Bad response.")
                return
            }

            do {
                let result = try JSONDecoder().decode(FQResponse.self, from: data)

                if let place = result.results.first {
                    completion(.success(place))
                }
            } catch {
                print("Decode error: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
}
