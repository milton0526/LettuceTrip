//
//  DiscoverViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit

import UIKit
import GoogleMaps
import GooglePlaces
import TinyConstraints

class DiscoverViewController: UIViewController {

    var mapView: GMSMapView!

    lazy var searchTextField: SearchTextField = {
        let textField = SearchTextField()
        textField.backgroundColor = .tertiarySystemBackground
        textField.placeholder = String(localized: "Search places...")
        textField.layer.cornerRadius = 24
        textField.layer.masksToBounds = true
        textField.leftViewMode = .always
        textField.leftView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        textField.delegate = self
        return textField
    }()

    lazy var poiCollectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.delegate = self
        collectionView.isScrollEnabled = false
        collectionView.register(POILocationCardCell.self, forCellWithReuseIdentifier: POILocationCardCell.identifier)
        return collectionView
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Int, GMSPlace>!

    var locationManager: CLLocationManager!
    var currentLocation: CLLocation?
    var placesClient: GMSPlacesClient!
    let defaultLocation = CLLocation(latitude: -33.869405, longitude: 151.199)
    var zoomLevel: Float = 13.0
    var likelyPlaces: [GMSPlace] = [] {
        didSet {
            print("Likely Places count: \(likelyPlaces.count)")
        }
    }
    var selectedPlace: GMSPlace?

    override func viewDidLoad() {
        super.viewDidLoad()
        configLocationServices()
        configMapView()
        setupUI()
        configureDataSource()
        updateSnapshot()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        locationManager.stopUpdatingLocation()
    }

    private func configLocationServices() {
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.distanceFilter = kCLLocationAccuracyHundredMeters
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.pausesLocationUpdatesAutomatically = true
        locationManager.allowsBackgroundLocationUpdates = false

        placesClient = GMSPlacesClient.shared()
    }

    private func configMapView() {
        GMSServices.setMetalRendererEnabled(true)
        let camera = GMSCameraPosition.camera(
            withLatitude: defaultLocation.coordinate.latitude,
            longitude: defaultLocation.coordinate.longitude,
            zoom: zoomLevel)
        mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        mapView.settings.myLocationButton = true
        mapView.isMyLocationEnabled = true
        mapView.isHidden = true
    }

    private func setupUI() {
        navigationController?.isNavigationBarHidden = true
        [mapView, searchTextField, poiCollectionView].forEach { view.addSubview($0) }

        mapView.edgesToSuperview(excluding: .bottom)
        mapView.bottomToSuperview(usingSafeArea: true)

        searchTextField.height(50)
        searchTextField.edgesToSuperview(excluding: .bottom, insets: .top(24) + .left(16) + .right(16), usingSafeArea: true)

        poiCollectionView.backgroundColor = .clear
        poiCollectionView.height(120)
        poiCollectionView.edgesToSuperview(excluding: .top, insets: .bottom(20), usingSafeArea: true)
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.9), heightDimension: .absolute(104))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPagingCentered
        section.interGroupSpacing = 10
        section.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)

        return UICollectionViewCompositionalLayout(section: section)
    }

    private func showLocationAccessAlert(message: String) {
        let alert = UIAlertController(
            title: String(localized: "Location Service Denied!"),
            message: message,
            preferredStyle: .alert)
        let openSettings = UIAlertAction(title: String(localized: "Settings"), style: .default) { _ in
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }

        let cancel = UIAlertAction(title: String(localized: "Cancel"), style: .cancel)
        alert.addAction(openSettings)
        alert.addAction(cancel)
        present(alert, animated: true)
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: poiCollectionView) { collectionView, indexPath, place in
            guard let cardCell = collectionView.dequeueReusableCell(
                withReuseIdentifier: POILocationCardCell.identifier,
                for: indexPath) as? POILocationCardCell
            else {
                fatalError("Failed to dequeue POILocationCardCell")
            }

            cardCell.titleLabel.text = place.name
            cardCell.subtitleLabel.text = place.description

            return cardCell
        }
    }

    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, GMSPlace>()

        snapshot.appendSections([0])
        snapshot.appendItems(likelyPlaces)
        dataSource.apply(snapshot)
    }

    private func listLikelyPlaces() {
        // Clean up from previous sessions.
        likelyPlaces.removeAll()

        let placeFields: GMSPlaceField = [.name, .coordinate, .placeID]
        placesClient.findPlaceLikelihoodsFromCurrentLocation(withPlaceFields: placeFields) { placeLikelihoods, error in
            guard error == nil else {
                // TODO: Handle the error.
                print("Current Place error: \(error?.localizedDescription ?? "")")
                return
            }

            guard let placeLikelihoods = placeLikelihoods else {
                print("No places found.")
                return
            }

            // Get likely places and add to the list.
            for likelihood in placeLikelihoods {
                let place = likelihood.place
                self.likelyPlaces.append(place)
            }

            DispatchQueue.main.async { [weak self] in
                self?.updateSnapshot()
            }
        }
    }
}

// MARK: - CollectionView Delegate
extension DiscoverViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        let place = likelyPlaces[indexPath.item]

        guard
            let id = place.placeID,
            let name = place.name
        else {
            return
        }
        let detailVC = PlaceDetailViewController(placeID: id, name: name)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

// MARK: - TextField Delegate
extension DiscoverViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard
            let text = textField.text,
            !text.isEmpty
        else {
            return
        }
    }
}

// MARK: - CLLocationManager Delegate
extension DiscoverViewController: CLLocationManagerDelegate {
    // Handle incoming location events.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location

        let camera = GMSCameraPosition.camera(
            withLatitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            zoom: zoomLevel)

        if mapView.isHidden {
            mapView.isHidden = false
            mapView.camera = camera
        } else {
            mapView.animate(to: camera)
        }

        listLikelyPlaces()
    }

    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted, .denied:
            mapView.isHidden = false
            let message = String(localized: "Enable location service to give you better experience while using app.")
            showLocationAccessAlert(message: message)
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        @unknown default:
            fatalError("Unknown location manager authorization.")
        }
    }

    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationManager.stopUpdatingLocation()
        print("Error: \(error)")
    }
}
