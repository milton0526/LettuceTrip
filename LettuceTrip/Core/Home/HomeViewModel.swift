//
//  HomeViewModel.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/13.
//

import Foundation
import Combine

enum HomeViewModelInput {
    case viewDidLoad
    case pullToRefresh
}

struct HomeViewModelOutput {
    let updateView: AnyPublisher<Void, Never>
    let displayError: AnyPublisher<Void, FirebaseError>
}

protocol HomeViewModelType {
    var shareTrips: [Trip] { get }

    func transform(input: AnyPublisher<HomeViewModelInput, Never>) -> HomeViewModelOutput
}

class HomeViewModel: HomeViewModelType {

    private let fsManager: FirestoreManager
    private var cancelBags: Set<AnyCancellable> = []

    // Subject
    private let tripSubject: CurrentValueSubject<[Trip], Never> = .init([])
    private let errorSubject: PassthroughSubject<Void, FirebaseError> = .init()
    private let output: PassthroughSubject<HomeViewModelOutput, Never> = .init()

    // Property
    var shareTrips: [Trip] {
        tripSubject.value
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
                    self?.errorSubject.send(completion: .failure(error))
                }
            } receiveValue: { [weak self] result in
                self?.tripSubject.send(result)
            }
            .store(in: &cancelBags)
    }

    func transform(input: AnyPublisher<HomeViewModelInput, Never>) -> HomeViewModelOutput {
        input
            .sink { [weak self] event in
                switch event {
                case .viewDidLoad, .pullToRefresh:
                    self?.fetchTrips()
                }
            }
            .store(in: &cancelBags)

        let updateViewPublisher = tripSubject.map { _ in }.eraseToAnyPublisher()
        let errorPublisher = errorSubject.eraseToAnyPublisher()

        return HomeViewModelOutput(
            updateView: updateViewPublisher,
            displayError: errorPublisher)
    }
}
