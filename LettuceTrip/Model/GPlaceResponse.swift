//
//  GPlaceResponse.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/1.
//

import UIKit

struct GPlaceResponse: Decodable {
    let candidates: [Candidate]
    let status: String
}

struct Candidate: Decodable {
    let placeID: String

    enum CodingKeys: String, CodingKey {
        case placeID = "place_id"
    }
}

struct GPlacePhoto {
    var attribution: String?
    let image: UIImage

    var display: String {
        guard
            let attribution = attribution,
            let firstCut = attribution.split(separator: "{").first,
            let secondCut = firstCut.split(separator: "(").last
        else {
            return ""
        }

        let result = String(describing: secondCut)
        let display = String(localized: "Provide by:\n\(result)")

        return display
    }
}
