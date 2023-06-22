//
//  PlaceDetailViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit
import GooglePlaces
import TinyConstraints

class PlaceDetailViewController: UIViewController {

    enum Section: Int {
        case photos
        case about
        case location

        var title: String? {
            switch self {
            case .photos:
                return nil
            case .about:
                return String(localized: "About")
            case .location:
                return String(localized: "Location")
            }
        }
    }

    let placeID: String
    let name: String
    private var place: GMSPlace?
    private var googleService: GooglePlaceServiceType!

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = .systemBackground
        tableView.contentInsetAdjustmentBehavior = .never
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

    init(placeID: String, name: String) {
        self.placeID = placeID
        self.name = name
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = false
        title = name
        view.backgroundColor = .systemBackground
        googleService = GooglePlaceService()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        googleService.fetchPlaceDetail(by: placeID) { [weak self] result in
            switch result {
            case .success(let place):
                self?.place = place

                DispatchQueue.main.async { [weak self] in
                    self?.tableView.reloadData()
                }

            case .failure(let error):
                self?.showAlertToUser(error: error)
            }
        }
    }

    private func fetchPhotos() {
        if let firstPhoto = place?.photos?.first {
            googleService.fetchPlacePhoto(with: firstPhoto) { [weak self] result in
                switch result {
                case .success(let (image, attributions)):
                    break
                case .failure(let error):
                    self?.showAlertToUser(error: error)
                }
            }
        }
    }

    @objc func addToTripButtonTapped(_ sender: UIButton) {
        // fetch firebase to check if user have trip list
        FireStoreManager.shared.fetchAllUserTrips { [weak self] result in
            switch result {
            case .success(let trips):
                self?.showActionSheet(form: trips)
            case .failure(let error):
                self?.showAlertToUser(error: error)
            }
        }
    }

    private func showActionSheet(form trips: [Trip]) {
        let place = Place(placeID: placeID)

        let actionSheet = UIAlertController(
            title: String(localized: "Add this place into trip"),
            message: nil,
            preferredStyle: .actionSheet)

        if trips.isEmpty {
            let action = UIAlertAction(title: "Create new trip!", style: .default) { [weak self] _ in
                self?.showAddNewTripVC()
            }
            actionSheet.addAction(action)
        } else {
            trips
                .filter { $0.endDate > .distantPast }
                .sorted { $0.startDate > $1.startDate }
                .forEach { trip in
                    let action = UIAlertAction(
                        title: trip.tripName,
                        style: .default) { _ in
                            FireStoreManager.shared.addPlace(place, to: trip)
                    }
                    actionSheet.addAction(action)
                }
        }

        let cancel = UIAlertAction(title: String(localized: "Cancel"), style: .cancel)
        actionSheet.addAction(cancel)

        DispatchQueue.main.async { [weak self] in
            self?.present(actionSheet, animated: true)
        }
    }

    private func showAddNewTripVC() {
        let addNewTripVC = AddNewTripViewController()
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
        3
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let section = Section(rawValue: indexPath.section),
            let place = place
        else {
            return UITableViewCell()
        }

        switch section {
        case .photos:
            guard let infoCell = tableView.dequeueReusableCell(withIdentifier: PlaceInfoCell.identifier, for: indexPath) as? PlaceInfoCell else {
                fatalError("Failed to dequeue place info cell")
            }

            let info = PlaceInfoCellViewModel(
                id: placeID,
                name: place.name ?? "",
                address: place.formattedAddress ?? "",
                rating: place.rating,
                totalUserRating: place.userRatingsTotal)
            infoCell.config(with: info)
            return infoCell

        case .about:
            guard let aboutCell = tableView.dequeueReusableCell(withIdentifier: PlaceAboutCell.identifier, for: indexPath) as? PlaceAboutCell else {
                fatalError("Failed to dequeue place about cell")
            }

            let about = PlaceAboutCellViewModel(
                businessStatus: place.businessStatus.rawValue,
                openingHours: place.openingHours?.weekdayText ?? [],
                website: place.website)

            aboutCell.config(with: about)

            return aboutCell
        case .location:
            return UITableViewCell()
        }
    }
}


// #if canImport(SwiftUI) && DEBUG
// import SwiftUI
//
// struct ViewControllerRepresentable: UIViewControllerRepresentable {
//
//    func makeUIViewController(context: Context) -> some UIViewController {
//        return PlaceDetailViewController(placeID: "sfjhsk", name: "Brisbane")
//    }
//
//    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
//    }
// }
//
// struct ViewControllerPreview: PreviewProvider {
//    static var previews: some View {
//        ViewControllerRepresentable()
//    }
// }
// #endif
//
