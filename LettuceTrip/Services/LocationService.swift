//
//  LocationService.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/23.
//

import Foundation
import CoreLocation
import UIKit

class LocationService: NSObject {

    private let locationManager = CLLocationManager()
    /// This property is  `@objc` so that the view controllers can observe when the user location changes through key-value observing.
    @objc dynamic var currentLocation: CLLocation?

    /// The view controller that presents any errors coming from location services.
    weak var viewController: UIViewController?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }

    private func displayLocationServicesDeniedAlert() {
        let message = String(localized: "Enable location service to give you better experience while using app.")
        let alert = UIAlertController(
            title: String(localized: "Location Service denied!"),
            message: message,
            preferredStyle: .alert)

        let openSettings = UIAlertAction(title: String(localized: "Settings"), style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }

        let cancel = UIAlertAction(title: String(localized: "Cancel"), style: .cancel)
        alert.addAction(openSettings)
        alert.addAction(cancel)

        viewController?.present(alert, animated: true)
    }
}

extension LocationService: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            displayLocationServicesDeniedAlert()
        case .authorizedWhenInUse:
            locationManager.requestLocation()
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
