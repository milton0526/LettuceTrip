//
//  GooglePlaceError.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/15.
//

import Foundation

enum GooglePlaceError: LocalizedError {
    case detail
    case photo

    var errorDescription: String? {
        switch self {
        case .detail:
            return String(localized: "Failed to get place details.")
        case .photo:
            return String(localized: "Failed to fetch place photos.")
        }
    }
}
