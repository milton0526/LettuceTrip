//
//  EditTripViewModel.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/22.
//

import Foundation
import Combine
import MapKit

enum EditTripVMOutput {
    case updateView
    case showIndicator(loading: Bool)
    case dismissHud
    case displayError(Error)
}

final class EditTripViewModel {
    var trip: Trip
    let isEditMode: Bool
    var listenerSubscription: AnyCancellable?
    lazy var currentSelectedDate = trip.startDate

    private let fsManager: FirestoreManager
    private let storageManager: StorageManager
    private var cancelBags: Set<AnyCancellable> = []

    private(set) var allPlaces: [Place] = []
    private(set) var sortedPlaces: [Place] = []
    private(set) var estimatedTimes: [Int: String] = [:]


    private let outputSubject: PassthroughSubject<EditTripVMOutput, Never> = .init()
    var outputPublisher: AnyPublisher<EditTripVMOutput, Never> {
        outputSubject.eraseToAnyPublisher()
    }

    init(trip: Trip, isEditMode: Bool, fsManager: FirestoreManager, storageManager: StorageManager) {
        self.trip = trip
        self.isEditMode = isEditMode
        self.fsManager = fsManager
        self.storageManager = storageManager
    }

    func convertDateToDisplay() -> [Date] {
        let dayRange = 0...trip.duration
        let travelDays = dayRange.map { range -> Date in
            if let components = Calendar.current.date(byAdding: .day, value: range, to: trip.startDate)?.resetHourAndMinute() {
                return components
            } else {
                return Date()
            }
        }

        return travelDays
    }

    func fetchPlaces() {
        guard let tripID = trip.id else { return }
        allPlaces.removeAll(keepingCapacity: true)

        listenerSubscription = fsManager.placeListener(at: tripID)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.outputSubject.send(.displayError(error))
                }
            } receiveValue: { [weak self] snapshot in
                guard let self = self else { return }
                if allPlaces.isEmpty {
                    let firstResult = snapshot.documents.compactMap { try? $0.data(as: Place.self) }
                    allPlaces = firstResult
                    filterPlace(by: currentSelectedDate)
                    return
                }

                snapshot.documentChanges.forEach { diff in
                    guard let modifiedPlace = try? diff.document.data(as: Place.self) else { return }

                    switch diff.type {
                    case .added:
                        self.allPlaces.append(modifiedPlace)
                    case .modified:
                        if let index = self.allPlaces.firstIndex(where: { $0.id == modifiedPlace.id }) {
                            self.allPlaces[index] = modifiedPlace
                        }
                    case .removed:
                        if let index = self.allPlaces.firstIndex(where: { $0.id == modifiedPlace.id }) {
                            self.allPlaces.remove(at: index)
                        }
                    }
                }
                filterPlace(by: currentSelectedDate)
            }
    }

    func filterPlace(by date: Date) {
        let filterResults = allPlaces.filter { $0.arrangedTime?.resetHourAndMinute() == date.resetHourAndMinute() }
        // swiftlint: disable force_unwrapping
        let sortedResults = filterResults.sorted { $0.arrangedTime! < $1.arrangedTime! }
        sortedPlaces = sortedResults
        // swiftlint: enable force_unwrapping

        if isEditMode && !sortedPlaces.isEmpty {
            outputSubject.send(.showIndicator(loading: true))
            calculateEstimatedTravelTime()
        } else {
            outputSubject.send(.updateView)
        }
    }

    private func calculateEstimatedTravelTime() {
        estimatedTimes.removeAll(keepingCapacity: true)
        let group = DispatchGroup()

        for i in 1..<sortedPlaces.count {
            group.enter()

            let source = sortedPlaces[i - 1]
            let destination = sortedPlaces[i]
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: source.coordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
            request.departureDate = source.endTime
            request.transportType = [.automobile, .transit]

            let directions = MKDirections(request: request)

            directions.calculateETA { response, error in
                if error != nil {
                    self.estimatedTimes.updateValue(String(localized: "Not available"), forKey: i - 1)
                    return
                }
                guard let response = response else { return }
                let minutes = response.expectedTravelTime / 60
                let formattedMins = (String(format: "%.0f", minutes))
                self.estimatedTimes.updateValue(formattedMins, forKey: i - 1)
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            if estimatedTimes.count == sortedPlaces.count - 1 {
                outputSubject.send(.updateView)
            }
        }
    }

    func updateTrip() {
        guard let tripId = trip.id else { return }
        fsManager.updateTrip(tripId, field: .isPublic, data: true)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    self?.outputSubject.send(.showIndicator(loading: false))
                case .failure(let error):
                    self?.outputSubject.send(.displayError(error))
                }
            } receiveValue: { _ in }
            .store(in: &cancelBags)
    }

    func deletePlace(_ placeId: String) {
        guard let tripId = trip.id else { return }
        fsManager.deleteTrip(tripId, place: placeId)
            .sink { [weak self] result in
                switch result {
                case .finished:
                    self?.outputSubject.send(.updateView)
                case .failure(let error):
                    self?.outputSubject.send(.displayError(error))
                }
            } receiveValue: { _ in }
            .store(in: &cancelBags)
    }

    func dragAndDropItem(placeTime: String?, fromIndex: Int, toIndex: Int) {
        let formatter = ISO8601DateFormatter()
        guard
            let placeTime = placeTime,
            let date = formatter.date(from: placeTime)
        else {
            return
        }

        var sourceItem = sortedPlaces[fromIndex]
        var destinationItem = sortedPlaces[toIndex]

        sourceItem.arrangedTime = destinationItem.arrangedTime
        sourceItem.lastEditor = fsManager.userName
        destinationItem.arrangedTime = date
        destinationItem.lastEditor = fsManager.userName

        fsManager.batchUpdatePlaces(at: trip, from: sourceItem, to: destinationItem)
            .sink { [weak self] result in
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    self?.outputSubject.send(.displayError(error))
                }
            } receiveValue: { _ in }
            .store(in: &cancelBags)
    }

    func updateTripImage(data: Data) {
        guard let tripId = trip.id else { return }

        storageManager.uploadImage(data, at: .trips, with: tripId)
            .flatMap { _ in
                self.storageManager.downloadRef(at: .trips, with: tripId)
            }
            .flatMap { url in
                self.fsManager.updateTrip(tripId, field: .image, data: url.absoluteString)
            }
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    self?.outputSubject.send(.dismissHud)
                case .failure(let error):
                    self?.outputSubject.send(.displayError(error))
                }
            } receiveValue: { _ in }
            .store(in: &cancelBags)
    }
}
