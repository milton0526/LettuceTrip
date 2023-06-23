//
//  DiscoverViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit
import MapKit
import TinyConstraints

class DiscoverViewController: UIViewController {

    lazy var mapView: MKMapView = {
        let map = MKMapView()
        map.showsUserLocation = true
        map.delegate = self
        map.showsCompass = false
        return map
    }()

    lazy var compass = MKCompassButton(mapView: mapView)

    lazy var searchTextField: RoundedTextField = {
        let textField = RoundedTextField()
        textField.placeholder = String(localized: "Search places...")
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

    lazy var locationService = LocationService()

    private var dataSource: UICollectionViewDiffableDataSource<Int, MKMapItem>!
    private var locationObservation: NSKeyValueObservation?
    private var currentLocation: CLLocation? {
        didSet {
            guard let currentLocation else { return }

            let mapRegion = MKCoordinateRegion(center: currentLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(mapRegion, animated: true)
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        locationService.requestLocation()
        configMapView()
        setupUI()
        configureDataSource()
        updateSnapshot()
    }

    private func configMapView() {
        mapView.selectableMapFeatures = [.pointsOfInterest]

        let mapConfiguration = MKStandardMapConfiguration()
        mapConfiguration.pointOfInterestFilter = MKPointOfInterestFilter(including: MKPointOfInterestCategory.travelPointsOfInterest)

        mapView.preferredConfiguration = mapConfiguration

        // Set a default location.
        currentLocation = locationService.currentLocation

        // Modify the location as updates come in.
        locationObservation = locationService.observe(\.currentLocation, options: [.new]) { _, change in
            guard let value = change.newValue,
                  let location = value
            else { return }

            self.currentLocation = location
        }
    }

    private func setupUI() {
        navigationController?.isNavigationBarHidden = true
        [mapView, searchTextField, compass, poiCollectionView].forEach { view.addSubview($0) }

        mapView.edgesToSuperview(excluding: .bottom)
        mapView.bottomToSuperview(usingSafeArea: true)

        searchTextField.height(50)
        searchTextField.edgesToSuperview(excluding: .bottom, insets: .top(24) + .left(16) + .right(16), usingSafeArea: true)

        compass.trailingToSuperview(offset: 16)
        compass.topToBottom(of: searchTextField, offset: 16)

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

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: poiCollectionView) { collectionView, indexPath, place in
            guard let cardCell = collectionView.dequeueReusableCell(
                withReuseIdentifier: POILocationCardCell.identifier,
                for: indexPath) as? POILocationCardCell
            else {
                fatalError("Failed to dequeue POILocationCardCell")
            }

//            cardCell.titleLabel.text = place.name
//            cardCell.subtitleLabel.text = place.description

            return cardCell
        }
    }

    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, MKMapItem>()

        snapshot.appendSections([0])
        snapshot.appendItems([MKMapItem()])
        dataSource.apply(snapshot)
    }
}

// MARK: - CollectionView Delegate
extension DiscoverViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

//        let place = likelyPlaces[indexPath.item]
//
//        guard
//            let id = place.placeID,
//            let name = place.name
//        else {
//            return
//        }
//        let detailVC = PlaceDetailViewController(placeID: id, name: name)
//        navigationController?.pushViewController(detailVC, animated: true)
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

// MARK: - MapView Delegate
extension DiscoverViewController: MKMapViewDelegate {
    // Tells the delegate when the region the map view is displaying changes.
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
    }

    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
    }
}
