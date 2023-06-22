//
//  User.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/21.
//

import Foundation
import FirebaseFirestoreSwift

struct User: Codable {
    @DocumentID var id: String?
    var name: String
    let email: String
}
