//
//  WishListViewModel.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/16.
//

import Foundation
import Combine

enum WishListVMInput {
    case fetchPlace
    case deletePlace(item: String)
}

enum WishListVMOutput {
    case success
    case anyError(Error)
}

protocol WishListViewModelType {

    var trip: Trip { get }

    var places: [Place] { get }

    func transform(input: AnyPublisher<WishListVMInput, Never>) -> AnyPublisher<WishListVMOutput, Never>
}

final class WishListViewModel: WishListViewModelType {

    let trip: Trip
    private let fsManager: FirestoreManager
    private var cancelBags: Set<AnyCancellable> = []
    private let output: PassthroughSubject<WishListVMOutput, Never> = .init()

    var places: [Place] = []

    init(trip: Trip, fsManager: FirestoreManager) {
        self.trip = trip
        self.fsManager = fsManager
    }

    func transform(input: AnyPublisher<WishListVMInput, Never>) -> AnyPublisher<WishListVMOutput, Never> {
        input
            .sink { [weak self] event in
                switch event {
                case .fetchPlace:
                    self?.fetchPlaces()
                case .deletePlace(let item):
                    self?.deletePlace(item: item)
                }
            }
            .store(in: &cancelBags)

        return output.eraseToAnyPublisher()
    }


    private func fetchPlaces() {
        guard let tripID = trip.id else { return }

        fsManager.placeListener(at: tripID, isArrange: false)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.output.send(.anyError(error))
                }
            } receiveValue: { [weak self] snapshot in
                guard let self = self else { return }
                if places.isEmpty {
                    let firstResult = snapshot.documents.compactMap { try? $0.data(as: Place.self) }
                    places = firstResult
                    output.send(.success)
                    return
                }

                snapshot.documentChanges.forEach { diff in
                    guard let modifiedPlace = try? diff.document.data(as: Place.self) else { return }

                    switch diff.type {
                    case .added:
                        self.places.append(modifiedPlace)
                    case .modified:
                        if let index = self.places.firstIndex(where: { $0.id == modifiedPlace.id }) {
                            self.places[index].arrangedTime = modifiedPlace.arrangedTime
                        }
                    case .removed:
                        if let index = self.places.firstIndex(where: { $0.id == modifiedPlace.id }) {
                            self.places.remove(at: index)
                        }
                    }
                }

                output.send(.success)
            }
            .store(in: &cancelBags)
    }

    private func deletePlace(item: String) {
        guard let tripId = trip.id else { return }

        fsManager.deleteTrip(tripId, place: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .finished:
                    output.send(.success)
                case .failure(let error):
                    output.send(.anyError(error))
                }
            } receiveValue: { _ in }
            .store(in: &cancelBags)
    }
}
