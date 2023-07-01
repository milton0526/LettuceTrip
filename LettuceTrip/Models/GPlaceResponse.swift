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
}
