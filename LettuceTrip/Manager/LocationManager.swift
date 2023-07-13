//
//  LocationManager.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/23.
//

import Foundation
import CoreLocation

class LocationManager: NSObject {

    private let coreLocationManager = CLLocationManager()
    @objc dynamic var currentLocation: CLLocation?
    var errorHandler: (() -> Void)?

    override init() {
        super.init()
        coreLocationManager.delegate = self
        coreLocationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }
}

extension LocationManager: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = coreLocationManager.authorizationStatus

        switch status {
        case .notDetermined:
            coreLocationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            errorHandler?()
        case .authorizedWhenInUse:
            coreLocationManager.requestLocation()
            JGHudIndicator.shared.showHud(type: .loading())
        default:
            print("Unknown location service status.")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        JGHudIndicator.shared.dismissHUD()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Handle any errors that `CLLocationManager` returns.
        JGHudIndicator.shared.dismissHUD()
        JGHudIndicator.shared.showHud(type: .failure)
        print("locationManager error: \(error.localizedDescription)")
    }
}
