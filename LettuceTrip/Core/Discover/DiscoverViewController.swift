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

    lazy var locationService = LocationService()
    private var locationObservation: NSKeyValueObservation?
    private var currentLocation: CLLocation? {
        didSet {
            guard let currentLocation else { return }

            let mapRegion = MKCoordinateRegion(center: currentLocation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(mapRegion, animated: true)
        }
    }

    lazy var searchResultController = SearchCityViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        locationService.errorPresentationTarget = self
        locationService.requestLocation()
        configMapView()
        setupUI()
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

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }

    private func setupUI() {
        [mapView, searchTextField, compass].forEach { view.addSubview($0) }

        mapView.edgesToSuperview(excluding: .bottom)
        mapView.bottomToSuperview(usingSafeArea: true)

        searchTextField.height(50)
        searchTextField.edgesToSuperview(excluding: .bottom, insets: .top(24) + .left(16) + .right(16), usingSafeArea: true)

        compass.trailingToSuperview(offset: 16)
        compass.topToBottom(of: searchTextField, offset: 16)
        addSearchViewController()
    }

    private func addSearchViewController() {
        addChild(searchResultController)
        if let child = children.first {
            view.addSubview(child.view)
            child.didMove(toParent: self)
            child.view.topToBottom(of: searchTextField, offset: -8)
            child.view.leading(to: searchTextField)
            child.view.trailing(to: searchTextField)
            child.view.layer.cornerRadius = 10
            child.view.layer.masksToBounds = true
            child.view.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
            child.view.height(160)
            child.view.isHidden = true
        }
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

// MARK: - TextField Delegate
extension DiscoverViewController: UITextFieldDelegate {

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        textField.text = ""
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        guard
            let text = textField.text,
            !text.isEmpty
        else {
            // show no result indicator view
            return
        }

        children.first?.view.isHidden = false
        searchResultController.search(for: text)
        searchResultController.userSelectedCity = { [weak self] city in
            guard let self = self else { return }
            self.searchTextField.text = city.name
            self.children.first?.view.isHidden = true
            let cityRegion = MKCoordinateRegion(center: city.placemark.coordinate, latitudinalMeters: 8000, longitudinalMeters: 8000)
            let pointRegion = MKCoordinateRegion(center: city.placemark.coordinate, latitudinalMeters: 250, longitudinalMeters: 250)
            searchResultController.region = cityRegion

            if city.pointOfInterestCategory != nil {
                self.mapView.setRegion(pointRegion, animated: true)
            } else {
                self.mapView.setRegion(cityRegion, animated: true)
            }
        }
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
