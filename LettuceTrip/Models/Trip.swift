//
//  Trip.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/21.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Trip: Codable {
    let id: String
    var tripName: String
    var startDate: Date
    var endDate: Date
    var destination: GeoPoint
    var members: [String]

    var chatRoomRef: String {
        "trips/\(id)/chatRoom"
    }

    var placesRef: String {
        "trips/\(id)/places"
    }
}

struct ChatRoom: Codable {
    let id: String
    let userID: String
    var message: String
}

struct Place: Codable {
    let id: String
    let placeID: String
    var arrangedTime: Date?
}
