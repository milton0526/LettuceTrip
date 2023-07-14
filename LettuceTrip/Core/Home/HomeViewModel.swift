//
//  HomeViewModel.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/13.
//

import Foundation
import Combine

protocol HomeViewModelType {

    var shareTrips: [Trip] { get }

    var updateViewPublisher: AnyPublisher<Void, FirebaseError> { get }

    func transform(input: AnyPublisher<Void, Never>)
}

class HomeViewModel: HomeViewModelType {

    private let fsManager: FirestoreManager
    private var cancelBags: Set<AnyCancellable> = []

    // Publisher
    private let tripSubject: CurrentValueSubject<[Trip], FirebaseError> = .init([])
    var updateViewPublisher: AnyPublisher<Void, FirebaseError> {
        tripSubject.map { _ in }.eraseToAnyPublisher()
    }

    // Property
    var shareTrips: [Trip] {
        tripSubject.value
    }

    init(fsManager: FirestoreManager) {
        self.fsManager = fsManager
    }

    func transform(input: AnyPublisher<Void, Never>) {
        input
            .sink { [weak self] _ in
                self?.fetchTrips()
            }
            .store(in: &cancelBags)
    }

    private func fetchTrips() {
        fsManager.getTrips(isPublic: true)
            .sink { [weak self] completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    self?.tripSubject.send(completion: .failure(error))
                }
            } receiveValue: { [weak self] result in
                self?.tripSubject.send(result)
            }
            .store(in: &cancelBags)
    }
}
