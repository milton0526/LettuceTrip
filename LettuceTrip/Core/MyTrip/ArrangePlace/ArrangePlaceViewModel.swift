//
//  ArrangePlaceViewModel.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/16.
//

import Foundation
import Combine

protocol ArrangePlaceViewModelType {
    var trip: Trip { get }
    var place: Place { get }
    var popViewPublisher: AnyPublisher<Void, Error> { get }
    func savePlace(arrangement: PlaceArrangement)
}

final class ArrangePlaceViewModel: ArrangePlaceViewModelType {

    let trip: Trip
    var place: Place
    private let fsManager: FirestoreManager
    private var cancelBags: Set<AnyCancellable> = []
    private let popViewSubject: PassthroughSubject<Void, Error> = .init()

    var popViewPublisher: AnyPublisher<Void, Error> {
        popViewSubject.eraseToAnyPublisher()
    }

    init(trip: Trip, place: Place, fsManager: FirestoreManager) {
        self.trip = trip
        self.place = place
        self.fsManager = fsManager
    }

    func savePlace(arrangement: PlaceArrangement) {
        guard let tripId = trip.id else { return }
        place.isArrange = true
        place.arrangedTime = arrangement.arrangedTime
        place.duration = arrangement.duration
        place.memo = arrangement.memo

        fsManager.updatePlace(place, at: tripId, isUpdate: true)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    self?.popViewSubject.send(completion: .finished)
                case .failure(let error):
                    self?.popViewSubject.send(completion: .failure(error))
                }
            } receiveValue: { _ in }
            .store(in: &cancelBags)
    }
}
