//
//  DiscoverViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit
import MapKit
import Combine
import TinyConstraints

class DiscoverViewController: UIViewController {

    private enum AnnotationReuseID: String {
        case featureAnnotation
    }

    // Properties
    private lazy var searchResultController = SearchCityViewController()
    private let viewModel: DiscoverViewModelType
    private let fsManager: FirestoreManager
    private var cancelBags: Set<AnyCancellable> = []

    init(viewModel: DiscoverViewModelType, fsManager: FirestoreManager) {
        self.viewModel = viewModel
        self.fsManager = fsManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // View components
    private lazy var mapView: MKMapView = {
        let map = MKMapView()
        map.showsUserLocation = true
        map.delegate = self
        map.showsCompass = false
        map.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: AnnotationReuseID.featureAnnotation.rawValue)
        return map
    }()

    private lazy var compass = MKCompassButton(mapView: mapView)

    private lazy var searchTextField: RoundedTextField = {
        let textField = RoundedTextField()
        textField.placeholder = String(localized: "Search places...")
        textField.leftViewMode = .always
        textField.leftView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        textField.delegate = self
        textField.returnKeyType = .search
        return textField
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configMapView()
        setupUI()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        guard let childView = children.first?.view else { return }
        if touch?.view != childView {
            childView.isHidden = true
        }
    }

    private func bind() {
        viewModel.locationPublisher
            .receive(on: DispatchQueue.main)
            .compactMap(\.?.coordinate)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    self?.showAlertToUser(error: error)
                }
            }, receiveValue: { [weak self] location in
                let mapRegion = MKCoordinateRegion(center: location, latitudinalMeters: 1000, longitudinalMeters: 1000)
                self?.mapView.setRegion(mapRegion, animated: true)
                self?.searchResultController.region = mapRegion
            })
            .store(in: &cancelBags)
    }

    private func configMapView() {
        mapView.selectableMapFeatures = [.pointsOfInterest]

        let mapConfiguration = MKStandardMapConfiguration()
        mapConfiguration.pointOfInterestFilter = MKPointOfInterestFilter(including: MKPointOfInterestCategory.travelPointsOfInterest)
        mapView.preferredConfiguration = mapConfiguration
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

    private func displayLocationServicesDeniedAlert(_ error: LocationError) {
        let message = String(localized: "Enable location service to give you better experience while using app.")
        let alert = UIAlertController(
            title: error.errorDescription,
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
}

// MARK: - TextField Delegate
extension DiscoverViewController: UITextFieldDelegate {

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        textField.text = ""
        return true
    }

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

        children.first?.view.isHidden = false
        searchResultController.search(for: text)
        searchResultController.userSelectedCity = { [weak self] city in
            guard let self = self else { return }
            searchTextField.text = city.name
            children.first?.view.isHidden = true
            let cityRegion = MKCoordinateRegion(center: city.placemark.coordinate, latitudinalMeters: 6000, longitudinalMeters: 6000)
            let pointRegion = MKCoordinateRegion(center: city.placemark.coordinate, latitudinalMeters: 125, longitudinalMeters: 125)
            searchResultController.region = cityRegion

            if city.pointOfInterestCategory != nil {
                mapView.setRegion(pointRegion, animated: true)
            } else {
                mapView.setRegion(cityRegion, animated: true)
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

        let apiService = GPlaceAPIManager()
        let detailVC = PlaceDetailViewController(place: place, fsManager: fsManager, apiService: apiService)
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
