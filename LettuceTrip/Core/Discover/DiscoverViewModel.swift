//
//  DiscoverViewModel.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/13.
//

import Foundation
import CoreLocation
import Combine

final class DiscoverViewModel {

    private let locationManager: LocationManager

    @Published var currentLocation: CLLocation? = .none

    private let errorSubject: PassthroughSubject<LocationError, Never> = .init()
    var errorPublisher: AnyPublisher<LocationError, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    init(locationManager: LocationManager = LocationManager()) {
        self.locationManager = locationManager
        locationManager.delegate = self
    }
}

extension DiscoverViewModel: LocationManagerDelegate {

    func getCurrentLocation(_ manager: LocationManager, location: CLLocation?) {
        currentLocation = location
    }

    func updateLocationFailed(_ manager: LocationManager, error: LocationError) {
        errorSubject.send(error)
    }

    func authorizationFailed(_ manager: LocationManager, error: LocationError) {
        errorSubject.send(error)
    }
}
