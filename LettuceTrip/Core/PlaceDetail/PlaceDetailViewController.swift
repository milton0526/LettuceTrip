//
//  PlaceDetailViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit
import MapKit
import TinyConstraints
import Combine
import GooglePlaces
import SafariServices

class PlaceDetailViewController: UIViewController {

    enum Section: Int {
        case photos
        case about

        var title: String? {
            switch self {
            case .photos:
                return nil
            case .about:
                return String(localized: "About")
            }
        }
    }

    let place: Place

    private var gmsPlace: GMSPlace? {
        didSet {
            guard let photos = gmsPlace?.photos else { return }
            fetchPhotos(photos: photos)
        }
    }

    private var placePhotos: [GPlacePhoto] = []
    private var cancellable = Set<AnyCancellable>()

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = .systemBackground
        tableView.allowsSelection = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(
            PlaceInfoHeaderView.self,
            forHeaderFooterViewReuseIdentifier: PlaceInfoHeaderView.identifier)
        tableView.register(PlacePhotoHeaderView.self, forHeaderFooterViewReuseIdentifier: PlacePhotoHeaderView.identifier)
        tableView.register(PlaceInfoCell.self, forCellReuseIdentifier: PlaceInfoCell.identifier)
        tableView.register(PlaceAboutCell.self, forCellReuseIdentifier: PlaceAboutCell.identifier)
        return tableView
    }()

    lazy var addToTripButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = .systemTeal
        config.baseForegroundColor = .white
        config.title = String(localized: "Add to trip")
        config.attributedTitle?.font = .systemFont(ofSize: 18, weight: .bold)
        config.titleAlignment = .center
        config.cornerStyle = .capsule

        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(addToTripButtonTapped), for: .touchUpInside)
        return button
    }()

    private let apiService = GPlaceAPI()

    init(place: Place) {
        self.place = place
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = false
        title = place.name
        view.backgroundColor = .systemBackground
        setupUI()
        fetchDetails()
    }

    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(addToTripButton)

        addToTripButton.height(50)
        addToTripButton.edgesToSuperview(excluding: .top, insets: .left(24) + .right(24) + .bottom(16), usingSafeArea: true)

        tableView.edgesToSuperview(excluding: .bottom, usingSafeArea: true)
        tableView.bottomToTop(of: addToTripButton)
    }

    private func fetchDetails() {
        JGHudIndicator.shared.showHud(type: .loading())
        apiService
            .findPlaceFromText(place.name, location: place.coordinate)
            .compactMap(\.candidates.first?.placeID)
            .flatMap(apiService.fetchPlace)
            .sink(receiveCompletion: { _ in
                print("Success get GMSPlace")
            }, receiveValue: { [weak self] place in
                self?.gmsPlace = place
            })
            .store(in: &cancellable)
    }

    private func fetchPhotos(photos: [GMSPlacePhotoMetadata]) {
        let photoIndices = photos.count > 3 ? 3 : photos.count

        var counter = 1

        for index in 0..<photoIndices {
            let attributions = String(describing: photos[0].attributions)
            apiService.fetchPhotos(metaData: photos[index])
                .receive(on: DispatchQueue.main)
                .sink { _ in
                    print("Success get GMSImage")
                } receiveValue: { [weak self] image in
                    let place = GPlacePhoto(attribution: attributions, image: image)
                    self?.placePhotos.append(place)
                    if counter == photoIndices {
                        self?.tableView.reloadData()
                        JGHudIndicator.shared.dismissHUD()
                    } else {
                        counter += 1
                    }
                }
                .store(in: &cancellable)
        }
    }

    @objc func addToTripButtonTapped(_ sender: UIButton) {
        // fetch firebase to check if user have trip list
        FireStoreService.shared.fetchAllUserTrips { [weak self] result in
            switch result {
            case .success(let trips):
                self?.showActionSheet(form: trips)
            case .failure(let error):
                self?.showAlertToUser(error: error)
            }
        }
    }

    private func showActionSheet(form trips: [Trip]) {

        let actionSheet = UIAlertController(
            title: String(localized: "Add this place into trip"),
            message: nil,
            preferredStyle: .actionSheet)

        trips
            .filter { $0.endDate > .now }
            .sorted { $0.startDate > $1.startDate }
            .forEach { trip in
                let updateAction = UIAlertAction(
                    title: trip.tripName,
                    style: .default) { [weak self] _ in
                        guard let self = self else { return }
                        FireStoreService.shared.updatePlace(self.place, to: trip) { error in
                            if error != nil {
                                JGHudIndicator.shared.showHud(type: .failure)
                            } else {
                                JGHudIndicator.shared.showHud(type: .success)
                            }
                        }
                }
                actionSheet.addAction(updateAction)
            }

        let createAction = UIAlertAction(title: "🆕 Create new trip", style: .default) { [weak self] _ in
            self?.showAddNewTripVC()
        }
        actionSheet.addAction(createAction)

        let cancel = UIAlertAction(title: String(localized: "Cancel"), style: .cancel)
        actionSheet.addAction(cancel)

        DispatchQueue.main.async { [weak self] in
            self?.present(actionSheet, animated: true)
        }
    }

    private func showAddNewTripVC() {
        let addNewTripVC = AddNewTripViewController(isCopy: false)
        let navVC = UINavigationController(rootViewController: addNewTripVC)
        let viewHeight = view.frame.height
        let detentsHeight = UISheetPresentationController.Detent.custom { _ in
            viewHeight * 0.7
        }
        if let bottomSheet = navVC.sheetPresentationController {
            bottomSheet.detents = [detentsHeight]
            bottomSheet.preferredCornerRadius = 20
            bottomSheet.prefersGrabberVisible = true
            self.present(navVC, animated: true)
        }
    }
}

// MARK: - UITableView Delegate
extension PlaceDetailViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 300
        }
        return 44
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard
            let sectionType = Section(rawValue: section),
            let infoHeaderView = tableView.dequeueReusableHeaderFooterView(withIdentifier: PlaceInfoHeaderView.identifier) as? PlaceInfoHeaderView
        else {
            return nil
        }

        switch sectionType {
        case .photos:
            guard let photoHeaderView = tableView.dequeueReusableHeaderFooterView(
                withIdentifier: PlacePhotoHeaderView.identifier) as? PlacePhotoHeaderView
            else {
                print("Photo header view dequeue failed")
                return nil
            }
            photoHeaderView.photos = placePhotos
            return photoHeaderView
        default:
            if let title = sectionType.title {
                infoHeaderView.config(with: title)
            }

            return infoHeaderView
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UITableView DataSource
extension PlaceDetailViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let section = Section(rawValue: indexPath.section),
            let gmsPlace = gmsPlace
        else {
            return UITableViewCell()
        }

        switch section {
        case .photos:
            guard let infoCell = tableView.dequeueReusableCell(withIdentifier: PlaceInfoCell.identifier, for: indexPath) as? PlaceInfoCell else {
                fatalError("Failed to dequeue place info cell")
            }

            let info = PlaceInfoCellViewModel(
                name: gmsPlace.name ?? "No name",
                address: gmsPlace.formattedAddress ?? "No address",
                rating: gmsPlace.rating)
            infoCell.config(with: info)
            return infoCell

        case .about:
            guard let aboutCell = tableView.dequeueReusableCell(withIdentifier: PlaceAboutCell.identifier, for: indexPath) as? PlaceAboutCell else {
                fatalError("Failed to dequeue place about cell")
            }

            let about = PlaceAboutCellViewModel(
                openingHours: gmsPlace.openingHours?.weekdayText ?? [],
                website: gmsPlace.website?.absoluteString)

            aboutCell.config(with: about)
            aboutCell.handler = { [weak self] url in
                let safariVC = SFSafariViewController(url: url)
                self?.present(safariVC, animated: true)
            }

            return aboutCell
        }
    }
}
