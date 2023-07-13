//
//  LocationManager.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/23.
//

import Foundation
import CoreLocation

protocol LocationManagerDelegate: AnyObject {

    func getCurrentLocation(_ manager: LocationManager, location: CLLocation?)

    func updateLocationFailed(_ manager: LocationManager, error: LocationError)

    func authorizationFailed(_ manager: LocationManager, error: LocationError)
}

class LocationManager: NSObject {

    private let coreLocationManager = CLLocationManager()
    weak var delegate: LocationManagerDelegate?

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
        case .restricted:
            delegate?.authorizationFailed(self, error: .restrict)
        case .denied:
            delegate?.authorizationFailed(self, error: .denied)
        case .authorizedWhenInUse:
            coreLocationManager.requestLocation()
        default:
            delegate?.authorizationFailed(self, error: .unknown)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        delegate?.getCurrentLocation(self, location: locations.last)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.updateLocationFailed(self, error: .update)
    }
}
