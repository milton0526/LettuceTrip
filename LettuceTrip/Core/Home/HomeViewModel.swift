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
    
    func fetchTrips()
}

class HomeViewModel: HomeViewModelType {

    private let fsManager: FirestoreManager
    private var cancelBags: Set<AnyCancellable> = []
    private let tripSubject: CurrentValueSubject<[Trip], FirebaseError> = .init([])

    // Property
    var shareTrips: [Trip] {
        tripSubject.value
    }

    // Publisher for View controller to subscribe
    var updateViewPublisher: AnyPublisher<Void, FirebaseError> {
        tripSubject.map { _ in }.eraseToAnyPublisher()
    }

    init(fsManager: FirestoreManager) {
        self.fsManager = fsManager
    }

    func fetchTrips() {
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
