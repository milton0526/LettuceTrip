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
    @DocumentID var id: String?
    var tripName: String
    var startDate: Date
    var endDate: Date
    var duration: Int
    var destination: GeoPoint
    var members: [String]
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
    var arrangedTime: Date?
}
