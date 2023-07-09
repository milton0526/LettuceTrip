//
//  User.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/21.
//

import Foundation
import FirebaseFirestoreSwift

struct LTUser: Codable {
    let id: String
    let name: String
    let email: String
    var image: Data?
    var deviceToken: String?
}
