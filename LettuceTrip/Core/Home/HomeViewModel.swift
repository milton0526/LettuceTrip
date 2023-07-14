//
//  HomeViewModel.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/13.
//

import Foundation
import Combine

typealias HomeVMOutput = AnyPublisher<Void, FirebaseError>

protocol HomeViewModelType {

    var shareTrips: [Trip] { get }

    func transform(input: AnyPublisher<Void, Never>) -> HomeVMOutput
}

class HomeViewModel: HomeViewModelType {

    private let fsManager: FirestoreManager
    private var cancelBags: Set<AnyCancellable> = []
    private let tripSubject: CurrentValueSubject<[Trip], FirebaseError> = .init([])

    // Property
    var shareTrips: [Trip] {
        tripSubject.value
    }

    init(fsManager: FirestoreManager) {
        self.fsManager = fsManager
    }

    func transform(input: AnyPublisher<Void, Never>) -> HomeVMOutput {
        input
            .sink { [weak self] _ in
                self?.fetchTrips()
            }
            .store(in: &cancelBags)

        return tripSubject.map { _ in }.eraseToAnyPublisher()
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
