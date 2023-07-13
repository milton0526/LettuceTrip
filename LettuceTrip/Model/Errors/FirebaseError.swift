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
    case update(String)
    case sendMessage
    case listenerError(String)
    case copy
    case delete
    case get
    case user(String)

    var errorDescription: String? {
        switch self {
        case .wrongId(let id):
            return "Trip ID error :\(id ?? "No Id")."
        case .createTrip:
            return String(localized: "Failed to create new trip.")
        case .update(let type):
            return String(localized: "Failed to update \(type).")
        case .sendMessage:
            return String(localized: "Failed to send message.")
        case .listenerError(let listener):
            return "Listener at \(listener) error."
        case .copy:
            return String(localized: "Failed to copy places.")
        case .delete:
            return String(localized: "Failed to delete.")
        case .get:
            return String(localized: "Failed to get data.")
        case .user(let type):
            return String(localized: "Error message: \(type).")
        }
    }
}
