//
//  FirebaseError.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/8.
//

import Foundation

enum FirebaseError: LocalizedError {
    case wrongId(String?)
    case createTrip
    case updateTrip
    case updatePlace
    case sendMessage
    case listenerError(String)

    var errorDescription: String? {
        switch self {
        case .wrongId(let id):
            return "Trip ID error :\(id ?? "No Id")."
        case .createTrip:
            return String(localized: "Failed to create new trip.")
        case .updateTrip:
            return String(localized: "Failed to update trip.")
        case .updatePlace:
            return String(localized: "Failed to update place.")
        case .sendMessage:
            return String(localized: "Failed to send message.")
        case .listenerError(let listener):
            return "Listener at \(listener) error."
        }
    }
}
