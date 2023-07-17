//
//  GPlaceError.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/17.
//

import Foundation

enum GPlaceError: LocalizedError {
    case placeDetail
    case photos

    var errorDescription: String? {
        switch self {
        case .placeDetail:
            return String(localized: "Failed to get google place details.")
        case .photos:
            return String(localized: "Failed to get photos from google.")
        }
    }
}
