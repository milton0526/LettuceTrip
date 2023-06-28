//
//  ShareTrips.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/21.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestoreSwift

struct ShareTrips: Codable {
    @DocumentID var id: String?
    let tripID: String
}
