//
//  PlaceDetailViewModel.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/15.
//

import Foundation
import Combine
import GooglePlaces

class PlaceDetailViewModel {

    private let fsManager: FirestoreManager
    private let apiService: GooglePlaceServiceType

    private var cancelBags: Set<AnyCancellable> = []
    private let gmsPlaceSubject: CurrentValueSubject<GMSPlace?, GooglePlaceError> = .init(nil)
    private let photoSubject: CurrentValueSubject<[GPlacePhoto], GooglePlaceError> = .init([])

    var gmsPlace: GMSPlace? {
        gmsPlaceSubject.value
    }

    var photos: [GPlacePhoto] {
        photoSubject.value
    }

    init(fsManager: FirestoreManager, apiService: GooglePlaceServiceType) {
        self.fsManager = fsManager
        self.apiService = apiService
    }

    func fetchDetails(place: Place) {
        apiService
            .findPlaceFromText(place.name, location: place.coordinate)
            .compactMap(\.candidates.first?.placeID)
            .flatMap(apiService.fetchPlace)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    self?.gmsPlaceSubject.send(completion: .failure(.detail))
                }
            }, receiveValue: { [weak self] place in
                self?.gmsPlaceSubject.send(place)
            })
            .store(in: &cancelBags)
    }

//    func fetchPhotos(photos: [GMSPlacePhotoMetadata]) {
//        let photoIndices = photos.count > 3 ? 3 : photos.count
//
//        var counter = 1
//
//        for index in 0..<photoIndices {
//            let attributions = String(describing: photos[0].attributions)
//            apiService.fetchPhotos(metaData: photos[index])
//                .receive(on: DispatchQueue.main)
//                .sink { completion in
//                    switch completion {
//                    case .finished:
//                        break
//                    case .failure:
//
//                    }
//                } receiveValue: { [weak self] image in
//                    guard let self = self else { return }
//
//                    let place = GPlacePhoto(attribution: attributions, image: image)
//                    photoSubject.value.append(place)
//                    if counter == photoIndices {
//                        photoSubject.send()
//                    } else {
//                        counter += 1
//                    }
//                }
//                .store(in: &cancelBags)
//        }
//    }

    func fetchUserTrips() {
        
    }

    func updatePlace(_ place: Place, tripId: String) {
        
    }
}
