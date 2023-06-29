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

    private enum AnnotationReuseID: String {
        case featureAnnotation
    }

    lazy var mapView: MKMapView = {
        let map = MKMapView()
        map.showsUserLocation = true
        map.delegate = self
        map.showsCompass = false
        map.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: AnnotationReuseID.featureAnnotation.rawValue)
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
    private var searchCompleter: MKLocalSearchCompleter?
    private var searchRegion = MKCoordinateRegion(MKMapRect.world)

    private var dataSource: UICollectionViewDiffableDataSource<Int, MKLocalSearchCompletion>!
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
        locationService.errorPresentationTarget = self
        locationService.requestLocation()
        configMapView()
        setupUI()
        configureDataSource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startProvidingCompletions()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopProvidingCompletions()
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
            guard
                let value = change.newValue,
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
        dataSource = UICollectionViewDiffableDataSource(collectionView: poiCollectionView) { collectionView, indexPath, item in
            guard let cardCell = collectionView.dequeueReusableCell(
                withReuseIdentifier: POILocationCardCell.identifier,
                for: indexPath) as? POILocationCardCell
            else {
                fatalError("Failed to dequeue POILocationCardCell")
            }

            cardCell.titleLabel.text = item.title
            cardCell.subtitleLabel.text = item.subtitle
            return cardCell
        }
    }

    private func updateSnapshot(_ result: [MKLocalSearchCompletion]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, MKLocalSearchCompletion>()
        snapshot.appendSections([0])
        snapshot.appendItems(result)
        dataSource.apply(snapshot)
    }

    private func setupPOIAnnotation(_ annotation: MKMapFeatureAnnotation) -> MKAnnotationView? {
        let markerAnnotationView = mapView.dequeueReusableAnnotationView(
            withIdentifier: AnnotationReuseID.featureAnnotation.rawValue,
            for: annotation)
        if let markerAnnotationView = markerAnnotationView as? MKMarkerAnnotationView {

            markerAnnotationView.animatesWhenAdded = true
            markerAnnotationView.canShowCallout = true

            let infoButton = UIButton(type: .detailDisclosure)
            markerAnnotationView.rightCalloutAccessoryView = infoButton

            if let tappedFeatureColor = annotation.iconStyle?.backgroundColor,
                let image = annotation.iconStyle?.image {

                markerAnnotationView.markerTintColor = tappedFeatureColor
                infoButton.tintColor = tappedFeatureColor

                let imageView = UIImageView(image: image.withTintColor(tappedFeatureColor, renderingMode: .alwaysOriginal))
                imageView.bounds = CGRect(origin: .zero, size: CGSize(width: 50, height: 50))
                markerAnnotationView.leftCalloutAccessoryView = imageView
            }
        }

        return markerAnnotationView
    }
}

// MARK: - CollectionView Delegate
extension DiscoverViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

// MARK: - TextField Delegate
extension DiscoverViewController: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard
            let text = textField.text,
            !text.isEmpty
        else {
            updateSnapshot([])
            return
        }

        searchCompleter?.queryFragment = text
    }
}

// MARK: - MapView Delegate

extension DiscoverViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? MKMapFeatureAnnotation else {
            return nil
        }
        return setupPOIAnnotation(annotation)
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard
            let annotation = view.annotation,
            let featureAnnotation = annotation as? MKMapFeatureAnnotation
        else {
            print("Failed to cast as MKMapFeatureAnnotation")
            return
        }

        guard
            let name = featureAnnotation.title,
            let image = featureAnnotation.iconStyle?.image,
            let icon = image.pngData()
        else {
            return
        }

        let location = featureAnnotation.coordinate

        let place = Place(
            name: name,
            location: .init(
                latitude: location.latitude,
                longitude: location.longitude),
            iconImage: icon,
            isArrange: false)

        let detailVC = PlaceDetailViewController(place: place)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension DiscoverViewController {

    private func startProvidingCompletions() {
        searchCompleter = MKLocalSearchCompleter()
        searchCompleter?.delegate = self
        searchCompleter?.region = searchRegion

        // Only include matches for travel-related points of interest, and exclude address-based results.
        searchCompleter?.resultTypes = .pointOfInterest
        searchCompleter?.pointOfInterestFilter = MKPointOfInterestFilter(including: MKPointOfInterestCategory.travelPointsOfInterest)
    }

    private func stopProvidingCompletions() {
        searchCompleter = nil
    }
}

extension DiscoverViewController: MKLocalSearchCompleterDelegate {

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // As the user types, new completion suggestions continuously return to this method.
        // Refresh the UI with the new results.
        let results = completer.results
        updateSnapshot(results)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // Handle any errors that `MKLocalSearchCompleter` returns.
        if let error = error as NSError? {
            print("MKLocalSearchCompleter encountered an error: \(error.localizedDescription). The query fragment is: \"\(completer.queryFragment)\"")
        }
    }
}
