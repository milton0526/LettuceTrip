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

    private let viewModel: PlaceDetailViewModelType
    private var cancelBags: Set<AnyCancellable> = []
    private let input: PassthroughSubject<PlaceDetailVMInput, Never> = .init()

    init(viewModel: PlaceDetailViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isHidden = false
        title = viewModel.place.name
        view.backgroundColor = .systemBackground
        setupUI()
        bind()
        fetchDetails()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }

    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())

        output
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .updateView(let showIndicator):
                    if showIndicator {
                        JGHudIndicator.shared.showHud(type: .success)
                    } else {
                        tableView.reloadData()
                        JGHudIndicator.shared.dismissHUD()
                    }
                case .userTrips(let trips):
                    showActionSheet(form: trips)
                case .displayError(let error):
                    JGHudIndicator.shared.dismissHUD()
                    showAlertToUser(error: error)
                }
            }
            .store(in: &cancelBags)
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
        input.send(.fetchDetail)
    }

    @objc func addToTripButtonTapped(_ sender: UIButton) {
        input.send(.fetchUserTrips)
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
                        guard
                            let self = self,
                            let tripId = trip.id
                        else {
                            return
                        }

                        self.input.send(.updatePlace(tripId: tripId))
                }
                actionSheet.addAction(updateAction)
            }

        let createAction = UIAlertAction(title: String(localized: "Create new trip"), style: .default) { [weak self] _ in
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
        let fsManager = FirestoreManager()
        let addNewTripVC = AddNewTripViewController(isCopy: false, fsManager: fsManager)
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
            photoHeaderView.photos = viewModel.allPhotos
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
            let gmsPlace = viewModel.gmsPlace
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
