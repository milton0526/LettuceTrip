//
//  MKPointOfInterestCategory+Extension.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/21.
//

import Foundation
import MapKit

extension MKPointOfInterestCategory {

    static let travelPointsOfInterest: [MKPointOfInterestCategory] = [.bakery, .brewery, .cafe, .restaurant, .winery, .hotel, .nightlife, .nationalPark, .museum, .store, .beach, .zoo]
    static let defaultPointOfInterestSymbolName = "mappin.and.ellipse"

    var symbolName: String {
        switch self {
        case .airport:
            return "airplane"
        case .atm, .bank:
            return "banknote"
        case .bakery, .brewery, .cafe, .foodMarket, .restaurant, .winery:
            return "fork.knife"
        case .campground, .hotel:
            return "bed.double"
        case .carRental, .evCharger, .gasStation, .parking:
            return "car"
        case .laundry, .store:
            return "tshirt"
        case .library, .museum, .school, .theater, .university:
            return "building.columns"
        case .nationalPark, .park:
            return "leaf"
        case .postOffice:
            return "envelope"
        case .publicTransport:
            return "bus"
        default:
            return MKPointOfInterestCategory.defaultPointOfInterestSymbolName
        }
    }
}
