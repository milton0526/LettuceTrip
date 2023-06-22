//
//  GMSError.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import Foundation

enum LTError: LocalizedError {
    case fetchGooglePlaceDetail
    case searchCity

    var title: String {
        switch self {
        case .fetchGooglePlaceDetail:
            return String(localized: "Failed to get place information!")
        case .searchCity:
            return String(localized: "Failed to search city!")
        }
    }

    var errorDescription: String? {
        switch self {
        case .fetchGooglePlaceDetail:
            return String(localized: "Please check your internet and try again later.")
        case .searchCity:
            return String(localized: "Please try again later.")
        }
    }
}
