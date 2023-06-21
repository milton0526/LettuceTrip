//
//  PlaceAboutCellViewModel.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import Foundation

struct PlaceAboutCellViewModel {

    let businessStatus: Int
    let openingHours: [String]
    let website: URL?

    var isOpening: String {
        return businessStatus == 0 ? String(localized: "Opening") : String(localized: "Close")
    }
}
