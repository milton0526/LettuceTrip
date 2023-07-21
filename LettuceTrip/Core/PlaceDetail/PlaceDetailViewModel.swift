//
//  PlaceDetailViewModel.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/15.
//

import Foundation
import Combine
import GooglePlaces

enum PlaceDetailVMOutput {
    case updateView(showIndicator: Bool)
    case userTrips(trips: [Trip])
    case displayError(error: Error)
}

protocol PlaceDetailViewModelType {
    var place: Place { get }
    var gmsPlace: GMSPlace? { get }
    var allPhotos: [GPlacePhoto] { get }
    var outputPublisher: AnyPublisher<PlaceDetailVMOutput, Never> { get }

    func fetchDetails()
    func fetchUserTrips()
    func updatePlace(tripId: String)
}

class PlaceDetailViewModel: PlaceDetailViewModelType {

    let place: Place
    private let fsManager: FirestoreManager
    private let apiService: GooglePlaceServiceType

    private var cancelBags: Set<AnyCancellable> = []
    private let output: PassthroughSubject<PlaceDetailVMOutput, Never> = .init()
    var outputPublisher: AnyPublisher<PlaceDetailVMOutput, Never> {
        output.eraseToAnyPublisher()
    }

    var gmsPlace: GMSPlace?
    var allPhotos: [GPlacePhoto] = []

    init(place: Place, fsManager: FirestoreManager, apiService: GooglePlaceServiceType) {
        self.place = place
        self.fsManager = fsManager
        self.apiService = apiService
    }

    func fetchDetails() {
        apiService
            .findPlaceFromText(place.name, location: place.coordinate)
            .compactMap(\.candidates.first?.placeID)
            .flatMap(apiService.fetchPlace)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    self?.output.send(.displayError(error: GPlaceError.placeDetail))
                }
            }, receiveValue: { [weak self] place in
                self?.gmsPlace = place
                guard let photos = place.photos else { return }
                self?.fetchPhotos(photos: photos)
            })
            .store(in: &cancelBags)
    }

    private func fetchPhotos(photos: [GMSPlacePhotoMetadata]) {
        let photoIndices = photos.count > 3 ? 3 : photos.count

        var counter = 1

        for index in 0..<photoIndices {
            let attributions = String(describing: photos[0].attributions)
            apiService.fetchPhotos(metaData: photos[index])
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure:
                        self?.output.send(.displayError(error: GPlaceError.photos))
                    }
                } receiveValue: { [weak self] image in
                    guard let self = self else { return }

                    let photo = GPlacePhoto(attribution: attributions, image: image)
                    allPhotos.append(photo)

                    if counter == photoIndices {
                        output.send(.updateView(showIndicator: false))
                    } else {
                        counter += 1
                    }
                }
                .store(in: &cancelBags)
        }
    }

    func fetchUserTrips() {
        fsManager.getTrips()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.output.send(.displayError(error: error))
                }
            } receiveValue: { [weak self] trips in
                self?.output.send(.userTrips(trips: trips))
            }
            .store(in: &cancelBags)
    }

    func updatePlace(tripId: String) {
        fsManager.updatePlace(place, at: tripId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.output.send(.updateView(showIndicator: true))
            } receiveValue: { _ in }
            .store(in: &cancelBags)
    }
}
