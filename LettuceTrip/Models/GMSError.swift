//
//  GMSError.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import Foundation

enum GMSError: LocalizedError {
    case fetchPlaceDetail


    var title: String {
        switch self {
        case .fetchPlaceDetail:
            return String(localized: "Failed to get place information!")
        }
    }

    var errorDescription: String? {
        switch self {
        case .fetchPlaceDetail:
            return String(localized: "Please check your internet and try again later.")
        }
    }
}
