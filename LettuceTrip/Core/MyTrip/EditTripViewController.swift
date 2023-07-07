//
//  EditTripViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/23.
//

import UIKit
import FirebaseFirestore
import TinyConstraints
import PhotosUI
import MapKit

class EditTripViewController: UIViewController {

    private var trip: Trip
    private let isEditMode: Bool

    init(trip: Trip, isEditMode: Bool = true) {
        self.trip = trip
        self.isEditMode = isEditMode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    enum Section {
        case main
    }

    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(data: trip.image))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 34
        imageView.layer.masksToBounds = true
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    lazy var scheduleView = ScheduleView()

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.register(ArrangePlaceCell.self, forCellReuseIdentifier: ArrangePlaceCell.identifier)
        return tableView
    }()

    private var listener: ListenerRegistration?
    private var dataSource: UITableViewDiffableDataSource<Section, Place>!
    private var places: [Place] = []
    private var sortedPlaces: [Place] = [] {
        didSet {
            estimateTravelTime()
        }
    }

    @MainActor private var estimatedTimes: [Int: String] = [:] {
        didSet {
            if estimatedTimes.count == sortedPlaces.count - 1 {
                updateSnapshot()
            }
        }
    }
    private lazy var currentSelectedDate = trip.startDate

    override func viewDidLoad() {
        super.viewDidLoad()
        title = trip.tripName
        view.backgroundColor = .systemBackground
        setupUI()
        scheduleView.schedules = convertDateToDisplay()
        scheduleView.delegate = self
        configureDataSource()
        setEditMode()
        scheduleView.collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .centeredVertically)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchPlaces()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listener?.remove()
        listener = nil
    }

    private func setupUI() {
        view.addSubview(imageView)
        view.addSubview(scheduleView)
        view.addSubview(tableView)

        imageView.edgesToSuperview(excluding: .bottom, insets: .top(8) + .horizontal(16), usingSafeArea: true)
        imageView.height(160)

        scheduleView.topToBottom(of: imageView)
        scheduleView.horizontalToSuperview(insets: .horizontal(16))
        scheduleView.height(80)

        tableView.topToBottom(of: scheduleView)
        tableView.edgesToSuperview(excluding: .top, usingSafeArea: true)
    }

    private func setEditMode() {
        if isEditMode {
            customNavBar()
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pickImage))
            imageView.addGestureRecognizer(tapGesture)
            tableView.dragDelegate = self
            tableView.dropDelegate = self
        } else {
            let copyButton = UIBarButtonItem(
                image: UIImage(systemName: "square.and.arrow.down"),
                style: .plain,
                target: self,
                action: #selector(copyItinerary))
            navigationItem.rightBarButtonItem = copyButton
        }
    }

    private func fetchPlaces() {
        guard let tripID = trip.id else { return }
        places.removeAll(keepingCapacity: true)

        listener = FireStoreService.shared.addListenerInTripPlaces(tripId: tripID, isArrange: true) { [weak self] result in
            guard let self = self else { return }
            JGHudIndicator.shared.showHud(type: .loading(text: "Calculate..."))

            switch result {
            case .success(let place):
                self.places = place
                self.filterPlace(by: self.currentSelectedDate)

                if !isEditMode {
                    listener?.remove()
                    listener = nil
                }
            case .failure(let error):
                self.showAlertToUser(error: error)
            }
        }
    }

    private func customNavBar() {
        let editListButton = UIBarButtonItem(
            image: UIImage(systemName: "list.bullet.clipboard"),
            style: .plain,
            target: self,
            action: #selector(openWishList))
        let shareButton = UIBarButtonItem(
            image: UIImage(systemName: "square.and.arrow.up"),
            style: .plain,
            target: self,
            action: #selector(shareTrip))
        navigationItem.rightBarButtonItems = [editListButton, shareButton]
    }

    @objc func openWishList(_ sender: UIBarButtonItem) {
        let wishVC = WishListViewController(trip: trip)
        navigationController?.pushViewController(wishVC, animated: true)
    }

    @objc func shareTrip(_ sender: UIBarButtonItem) {
        guard let tripID = trip.id else { return }

        let actionSheet = UIAlertController(
            title: String(localized: "Share this trip to..."),
            message: nil,
            preferredStyle: .actionSheet)

        let shareToCommunity = UIAlertAction(title: String(localized: "Community"), style: .default) { [weak self] _ in
            // share to home page
            guard let self = self else { return }
            var trip = self.trip
            trip.isPublic = true

            FireStoreService.shared.updateTrip(trip: trip) { error in
                if error == nil {
                    JGHudIndicator.shared.showHud(type: .success)
                } else {
                    JGHudIndicator.shared.showHud(type: .failure)
                }
            }
        }

        let shareLinkToFriend = UIAlertAction(title: String(localized: "Invite your friends"), style: .default) { [weak self] _ in
            if let shareURL = URL(string: "lettuceTrip.app.shareLink://invite/trip?\(tripID)") {
                let activityVC = UIActivityViewController(activityItems: [shareURL], applicationActivities: nil)
                self?.present(activityVC, animated: true)
            }
        }

        let cancel = UIAlertAction(title: String(localized: "Cancel"), style: .cancel)

        actionSheet.addAction(shareToCommunity)
        actionSheet.addAction(shareLinkToFriend)
        actionSheet.addAction(cancel)
        present(actionSheet, animated: true)
    }

    @objc func pickImage(_ gesture: UIGestureRecognizer) {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc func copyItinerary(_ sender: UIBarButtonItem) {
        let addTripVC = AddNewTripViewController(isCopy: true)
        let placeMark = MKPlacemark(coordinate: trip.coordinate)
        let mapItem = MKMapItem(placemark: placeMark)
        mapItem.name = trip.destination
        addTripVC.selectedCity = mapItem
        addTripVC.copyFromTrip = trip
        addTripVC.places = places
        addTripVC.destinationTextField.text = trip.destination
        addTripVC.destinationTextField.textColor = .systemGray
        addTripVC.durationTextField.text = String(trip.duration + 1)
        addTripVC.durationTextField.textColor = .systemGray

        let navVC = UINavigationController(rootViewController: addTripVC)
        let viewHeight = view.frame.height
        let detentsHeight = UISheetPresentationController.Detent.custom { _ in
            viewHeight * 0.7
        }
        if let bottomSheet = navVC.sheetPresentationController {
            bottomSheet.detents = [detentsHeight]
            bottomSheet.preferredCornerRadius = 20
            bottomSheet.prefersGrabberVisible = true
            present(navVC, animated: true)
        }
    }

    private func convertDateToDisplay() -> [Date] {
        let dayRange = 0...trip.duration
        let travelDays = dayRange.map { range -> Date in
            if let components = Calendar.current.date(byAdding: .day, value: range, to: trip.startDate)?.resetHourAndMinute() {
                return components
            } else {
                return Date()
            }
        }

        return travelDays
    }

    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [unowned self] tableView, indexPath, item in
            guard let arrangeCell = tableView.dequeueReusableCell(
                withIdentifier: ArrangePlaceCell.identifier,
                for: indexPath) as? ArrangePlaceCell
            else {
                fatalError("Failed to dequeue cityCell")
            }

            if indexPath.item < estimatedTimes.count {
                arrangeCell.config(with: item, travelTime: estimatedTimes[indexPath.item] ?? "")
            } else {
                arrangeCell.config(with: item)
            }
            return arrangeCell
        }
    }

    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Place>()
        snapshot.appendSections([.main])
        snapshot.appendItems(sortedPlaces)
        // use snapshot reload method to avoid weird animation
        dataSource.apply(snapshot, animatingDifferences: false) {
            JGHudIndicator.shared.dismissHUD()
        }
    }

    private func filterPlace(by date: Date) {
        let filterResults = places.filter { $0.arrangedTime?.resetHourAndMinute() == date.resetHourAndMinute() }
        // swiftlint: disable force_unwrapping
        let sortedResults = filterResults.sorted { $0.arrangedTime! < $1.arrangedTime! }
        sortedPlaces = sortedResults
        // swiftlint: enable force_unwrapping
    }

    // Estimated time
    private func estimateTravelTime() {
        guard !sortedPlaces.isEmpty else {
            updateSnapshot()
            return
        }

        estimatedTimes = [:]
        for i in 1..<sortedPlaces.count {
            let source = sortedPlaces[i - 1]
            let destination = sortedPlaces[i]
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: source.coordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination.coordinate))
            request.departureDate = source.endTime
            request.transportType = [.automobile, .transit]

            let directions = MKDirections(request: request)
            directions.calculateETA { response, error in
                if error != nil {
                    self.estimatedTimes.updateValue(String(localized: "Not available"), forKey: i - 1)
                    return
                }
                guard let response = response else { return }
                let minutes = response.expectedTravelTime / 60
                let formattedMins = (String(format: "%.0f", minutes))
                self.estimatedTimes.updateValue(formattedMins, forKey: i - 1)
            }
        }
    }
}

// MARK: - CollectionView Delegate
extension EditTripViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let place = sortedPlaces[indexPath.item]
        let viewController: UIViewController

        if isEditMode {
            viewController = ArrangePlaceViewController(trip: trip, place: place, isEditMode: false)
        } else {
            viewController = PlaceDetailViewController(place: place)
        }
        navigationController?.pushViewController(viewController, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard isEditMode else { return nil }
        guard let place = dataSource.itemIdentifier(for: indexPath) else { return nil }
        let deleteAction = UIContextualAction(style: .destructive, title: String(localized: "Delete")) { [unowned self] _, _, completion in
            FireStoreService.shared.deletePlace(at: self.trip, place: place)
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}


// MARK: - CollectionView Drag Delegate
extension EditTripViewController: UITableViewDragDelegate {

    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let placeItem = String(sortedPlaces[indexPath.item].arrangedTime?.ISO8601Format() ?? "")
        let itemProvider = NSItemProvider(object: placeItem as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = placeItem
        return [dragItem]
    }
}


// MARK: - CollectionView Drop Delegate
extension EditTripViewController: UITableViewDropDelegate {

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        if tableView.hasActiveDrag {
            return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }

        return UITableViewDropProposal(operation: .forbidden)
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        var destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let items = dataSource.snapshot().numberOfItems(inSection: .main)
            destinationIndexPath = IndexPath(item: items - 1, section: 0)
        }

        if coordinator.proposal.operation == .move {
            moveItem(coordinator: coordinator, destinationIndexPath: destinationIndexPath, tableView: tableView)
        }
    }

    private func moveItem(coordinator: UITableViewDropCoordinator, destinationIndexPath: IndexPath, tableView: UITableView) {
        if let dragItem = coordinator.items.first,
            let sourceIndexPath = dragItem.sourceIndexPath {

            tableView.performBatchUpdates {
                for item in coordinator.items {
                    let placeTime = item.dragItem.localObject as? String
                    let formatter = ISO8601DateFormatter()

                    if let dateString = placeTime,
                        let date = formatter.date(from: dateString) {

                        var sourceItem = sortedPlaces[sourceIndexPath.item]
                        var destinationItem = sortedPlaces[destinationIndexPath.item]

                        sourceItem.arrangedTime = destinationItem.arrangedTime
                        destinationItem.arrangedTime = date

                        FireStoreService.shared.batchUpdateInOrder(at: trip, from: sourceItem, to: destinationItem) { _ in
                            // Maybe do nothing
                        }
                    }
                }
            }
        }
    }
}

// MARK: - ScheduleView Delegate
extension EditTripViewController: ScheduleViewDelegate {
    func didSelectedDate(_ view: ScheduleView, selectedDate: Date) {
        currentSelectedDate = selectedDate
        filterPlace(by: selectedDate)
    }
}

// MARK: - PHPickerController Delegate
extension EditTripViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        let itemProviders = results.map(\.itemProvider)
        if let itemProvider = itemProviders.first, itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                guard
                    let self = self,
                    let image = image as? UIImage,
                    let imageData = image.jpegData(compressionQuality: 0.1)
                else {
                    return
                }

                // Update imageView first
                DispatchQueue.main.async {
                    self.imageView.image = image
                    self.trip.image = imageData

                    FireStoreService.shared.updateTrip(trip: self.trip) { error in
                        if let error = error {
                            self.showAlertToUser(error: error)
                        }
                    }
                }
            }
        }
    }
}
