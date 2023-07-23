//
//  HomeViewModelTests.swift
//  LettuceTripTests
//
//  Created by Milton Liu on 2023/7/23.
//

import XCTest
import Combine
import Firebase
@testable import LettuceTrip

final class HomeViewModelTests: XCTestCase {

    var sut: HomeViewModelType!
    var mockFirestoreManager: MockFirestoreManager!
    var cancelBags: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockFirestoreManager = MockFirestoreManager()
        sut = HomeViewModel(fsManager: mockFirestoreManager)
        cancelBags = .init()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
        mockFirestoreManager = nil
        cancelBags = nil
    }

    func testFetchTripSuccess() {
        // Given
        let trips: [Trip] = [
            Trip(
            tripName: "Test",
            startDate: .now,
            endDate: .now,
            duration: 5,
            destination: "location",
            geoLocation: .init(latitude: 23.54, longitude: 132.45),
            members: ["Some person"],
            isPublic: false)
        ]

        mockFirestoreManager.tripsToReturn.send(trips)

        // When
        sut.fetchTrips()

        // Then
        XCTAssertEqual(trips, sut.shareTrips, "If fetch data success then trips should be equal.")
    }

    func testFetchTripFailure() {
        // Given
        let testError: FirebaseError = .get
        mockFirestoreManager.tripsToReturn.send(completion: .failure(testError))

        // When
        sut.fetchTrips()

        // Then
        XCTAssertTrue(sut.shareTrips.isEmpty, "shareTrips should be empty due to the failure.")
    }
}

class MockFirestoreManager: FirestoreService {

    var tripsToReturn: CurrentValueSubject<[Trip], FirebaseError> = .init([])

    func getTrips(isPublic: Bool) -> AnyPublisher<[Trip], FirebaseError> {
        return tripsToReturn.eraseToAnyPublisher()
    }
}
