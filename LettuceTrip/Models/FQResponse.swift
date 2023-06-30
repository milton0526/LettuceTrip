//
//  FQResponse.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/23.
//

import Foundation

struct FQResponse: Decodable {
    let results: [FQPlace]
}

struct FQPlace: Decodable {
    let id: String?
    let location: Location?
    let description: String?
    let hours: Hours?
    let photos: [Photo]?
    let rating: Double?
    let tel: String?
    let website: String?

    enum CodingKeys: String, CodingKey {
        case id = "fsq_id"
        case location, description, hours, photos, rating, tel, website
    }
}

// MARK: - Location
struct Location: Decodable {
    let address: String

    enum CodingKeys: String, CodingKey {
        case address = "formatted_address"
    }
}

// MARK: - Hours
struct Hours: Decodable {
    let display: String?
    let openNow: Bool
    let regular: [Regular]?

    enum CodingKeys: String, CodingKey {
        case openNow = "open_now"
        case display, regular
    }
}

// MARK: - Regular
struct Regular: Decodable {
    let close: String
    let day: Int
    let open: String
}

// MARK: - Photo
struct Photo: Decodable {
    let id: String
    let prefix: String
    let suffix: String

    var url: URL? {
        URL(string: prefix + "800x600" + suffix)
    }
}
