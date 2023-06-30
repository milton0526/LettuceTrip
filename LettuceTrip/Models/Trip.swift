//
//  Trip.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/21.
//

import Foundation
import MapKit
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Trip: Codable, Hashable {
    @DocumentID var id: String?
    var tripName: String
    var image: Data
    var startDate: Date
    var endDate: Date
    var duration: Int
    var destination: GeoPoint
    var members: [String]
    var isPublic: Bool
}

struct Message: Codable, Hashable {
    @DocumentID var id: String?
    let userID: String
    var message: String
    @ServerTimestamp var sendTime: Date?
}

struct Place: Codable, Hashable {
    @DocumentID var id: String?
    let name: String
    let location: GeoPoint
    let iconImage: Data
    var isArrange: Bool
    var arrangedTime: Date?
    var duration: Double?
    var memo: String?

    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
    }
}

struct PlaceArrangement {
    var arrangedTime: Date
    var duration: Double
    var memo: String
}
