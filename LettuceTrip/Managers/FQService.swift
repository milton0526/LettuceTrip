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

    func placeSearch(by placeMark: CLPlacemark? = nil) {
        guard
            let key = key
                //            let placeName = placeMark.name,
                //            let latitude = placeMark.location?.coordinate.latitude,
                //            let longitude = placeMark.location?.coordinate.longitude
        else {
            return
        }

        let placeName = "Anzac Square Arcade".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let latitude = "-27.467313"
        let longitude = "153.026154"

        let urlString = "https://api.foursquare.com/v3/places/search?query=\(placeName ?? "")&ll=\(latitude)%2C\(longitude)&fields=description%2Cphotos%2Ctel%2Cwebsite%2Chours%2Crating%2Cfeatures&sort=POPULARITY&limit=1"

        guard let url = URL(string: urlString) else { return }

        let headers = [
            "accept": "application/json",
            "Authorization": key
        ]

        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = headers

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print(error.localizedDescription)
            }

            guard
                let data = data,
                let response = response as? HTTPURLResponse,
                response.statusCode == 200
            else {
                return
            }

            do {
                let result = try JSONSerialization.jsonObject(with: data)
                print(result)
            } catch {
                print("Decode error: \(error.localizedDescription)")
            }
        }
        task.resume()
    }
}
