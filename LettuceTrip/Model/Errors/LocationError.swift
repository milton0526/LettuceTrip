//
//  LocationError.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/13.
//

import Foundation

enum LocationError: LocalizedError {
    case denied
    case restrict
    case unknown
    case update

    var errorDescription: String? {
        switch self {
        case .denied:
            return String(localized: "Location Service denied.")
        case .restrict:
            return String(localized: "Location Service restrict.")
        case .unknown:
            return String(localized: "Unknown Location Service state.")
        case .update:
            return String(localized: "Failed to update location.")
        }
    }
}
