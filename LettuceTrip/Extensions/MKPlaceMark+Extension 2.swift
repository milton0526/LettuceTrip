//
//  MKPlaceMark+Extension.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/22.
//

import MapKit
import Contacts

extension MKPlacemark {

    var formattedAddress: String? {
        guard let postalAddress = postalAddress else { return nil }
        return CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress).replacingOccurrences(of: "\n", with: " ")
    }
}
