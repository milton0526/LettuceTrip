//
//  DiscoverViewModel.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/13.
//

import Foundation
import CoreLocation
import Combine

protocol DiscoverViewModelType {

    var locationPublisher: AnyPublisher<CLLocation?, Never> { get }

    var errorPublisher: AnyPublisher<Void, LocationError> { get }
}

final class DiscoverViewModel: DiscoverViewModelType {

    private let locationManager: LocationManager

    private let locationSubject: CurrentValueSubject<CLLocation?, Never> = .init(nil)
    private let errorSubject: PassthroughSubject<Void, LocationError> = .init()

    var locationPublisher: AnyPublisher<CLLocation?, Never> {
        locationSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<Void, LocationError> {
        errorSubject.eraseToAnyPublisher()
    }

    init(locationManager: LocationManager) {
        self.locationManager = locationManager
        locationManager.delegate = self
    }
}

extension DiscoverViewModel: LocationManagerDelegate {

    func getCurrentLocation(_ manager: LocationManager, location: CLLocation?) {
        locationSubject.send(location)
    }

    func updateLocationFailed(_ manager: LocationManager, error: LocationError) {
        errorSubject.send(completion: .failure(error))
    }

    func authorizationFailed(_ manager: LocationManager, error: LocationError) {
        errorSubject.send(completion: .failure(error))
    }
}
