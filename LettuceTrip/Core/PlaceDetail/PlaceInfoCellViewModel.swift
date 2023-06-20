//
//  PlaceInfoCellViewModel.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import Foundation

struct PlaceInfoCellViewModel: Identifiable {
    let id: String
    let name: String
    let address: String
    let rating: Float
    let totalUserRating: UInt
}
