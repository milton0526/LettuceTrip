//
//  MyTripViewModel.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/24.
//

import Foundation
import Combine

enum MyTripVMOutput {
    case reloadData
    case displayError(Error)
}

protocol MyTripViewModelType {
    var filterTrips: [MyTripViewController.Segment: [Trip]] { get }
    var outputPublisher: AnyPublisher<MyTripVMOutput, Never> { get }

    func fetchUserTrips()
    func updateMember(tripId: String)
}

final class MyTripViewModel: MyTripViewModelType {

    private let fsManager: FirestoreManager
    private var allTrips: [Trip] = []
    private(set) var filterTrips: [MyTripViewController.Segment: [Trip]] = [.upcoming: [], .closed: []]
    private var cancelBags: Set<AnyCancellable> = []
    private let outputSubject: PassthroughSubject<MyTripVMOutput, Never> = .init()
    var outputPublisher: AnyPublisher<MyTripVMOutput, Never> {
        outputSubject.eraseToAnyPublisher()
    }

    init(fsManager: FirestoreManager) {
        self.fsManager = fsManager
    }

    func fetchUserTrips() {
        fsManager.tripListener()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.outputSubject.send(.displayError(error))
                }
            } receiveValue: { [weak self] snapshot in
                guard let self = self else { return }
                if allTrips.isEmpty {
                    let firstResult = snapshot.documents.compactMap { try? $0.data(as: Trip.self) }
                    allTrips = firstResult
                    filterByDate()
                    return
                }

                snapshot.documentChanges.forEach { diff in
                    guard let modifiedTrip = try? diff.document.data(as: Trip.self) else { return }

                    switch diff.type {
                    case .added:
                        self.allTrips.append(modifiedTrip)
                    case .modified:
                        if let index = self.allTrips.firstIndex(where: { $0.id == modifiedTrip.id }) {
                            self.allTrips[index] = modifiedTrip
                        }
                    case .removed:
                        if let index = self.allTrips.firstIndex(where: { $0.id == modifiedTrip.id }) {
                            self.allTrips.remove(at: index)
                        }
                    }
                }
                filterByDate()
            }
            .store(in: &cancelBags)
    }

    private func filterByDate() {
        filterTrips = [.upcoming: [], .closed: []]
        allTrips.forEach { trip in
            if trip.endDate > .now {
                filterTrips[.upcoming, default: []].append(trip)
            } else {
                filterTrips[.closed, default: []].append(trip)
            }
        }

        filterTrips[.upcoming]?.sort { $0.startDate < $1.startDate }
        filterTrips[.closed]?.sort { $0.startDate < $1.startDate }
        outputSubject.send(.reloadData)
    }

    func updateMember(tripId: String) {
        guard let userId = fsManager.user else { return }

        fsManager.updateMember(userId: userId, atTrip: tripId, isRemove: true)
            .sink { [weak self] completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    self?.outputSubject.send(.displayError(error))
                }
            } receiveValue: { _ in }
            .store(in: &self.cancelBags)
    }
}
