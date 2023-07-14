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
import Combine
import UnsplashPhotoPicker
import SDWebImage

class EditTripViewController: UIViewController {

    private var trip: Trip
    private let isEditMode: Bool
    private let fsManager: FirestoreManager

    init(trip: Trip, isEditMode: Bool = true, fsManager: FirestoreManager) {
        self.trip = trip
        self.isEditMode = isEditMode
        self.fsManager = fsManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    enum Section {
        case main
    }

    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: .scene)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 34
        imageView.layer.masksToBounds = true
        imageView.isUserInteractionEnabled = true
        return imageView
    }()

    lazy var messageButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .tertiarySystemBackground
        button.setBackgroundImage(.init(systemName: "bubble.left.circle.fill"), for: .normal)
        button.addTarget(self, action: #selector(openChatRoom), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    lazy var scheduleView = ScheduleView()

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.register(ArrangePlaceCell.self, forCellReuseIdentifier: ArrangePlaceCell.identifier)
        return tableView
    }()

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
    private let storageManager = StorageManager()
    private lazy var currentSelectedDate = trip.startDate
    private var listenerSubscription: AnyCancellable?
    private var cancelBags: Set<AnyCancellable> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = trip.tripName
        navigationItem.backButtonDisplayMode = .minimal
        view.backgroundColor = .systemBackground
        setupUI()
        scheduleView.schedules = convertDateToDisplay()
        scheduleView.delegate = self
        configureDataSource()
        setEditMode()
        scheduleView.collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .centeredVertically)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchPlaces()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        listenerSubscription?.cancel()
        listenerSubscription = nil
    }

    private func setupUI() {
        [imageView, scheduleView, tableView, messageButton].forEach { view.addSubview($0) }

        if let url = URL(string: trip.image ?? "") {
            imageView.setTripImage(url: url)
        }

        imageView.edgesToSuperview(excluding: .bottom, insets: .top(8) + .horizontal(16), usingSafeArea: true)
        imageView.height(160)

        scheduleView.topToBottom(of: imageView)
        scheduleView.horizontalToSuperview(insets: .horizontal(16))
        scheduleView.height(80)

        tableView.topToBottom(of: scheduleView)
        tableView.edgesToSuperview(excluding: .top, usingSafeArea: true)

        messageButton.size(CGSize(width: 50, height: 50))
        messageButton.layer.cornerRadius = 25
        messageButton.layer.masksToBounds = true
        messageButton.layer.shadowColor = UIColor.gray.cgColor
        messageButton.layer.shadowRadius = 5
        messageButton.layer.shadowOpacity = 1
        messageButton.layer.masksToBounds = false
        messageButton.layer.shadowOffset = .zero
        messageButton.trailingToSuperview(offset: 16)
        messageButton.bottomToSuperview(offset: -32, usingSafeArea: true)
    }

    private func setEditMode() {
        if isEditMode {
            customNavBar()
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(pickImage))
            imageView.addGestureRecognizer(tapGesture)
            tableView.dragDelegate = self
            tableView.dropDelegate = self
            messageButton.isHidden = false
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

        listenerSubscription = fsManager.placeListener(at: tripID)
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.showAlertToUser(error: error)
                }
            } receiveValue: { [unowned self] snapshot in
                if places.isEmpty {
                    let firstResult = snapshot.documents.compactMap { try? $0.data(as: Place.self) }
                    places = firstResult
                    filterPlace(by: currentSelectedDate)
                    return
                }

                snapshot.documentChanges.forEach { diff in
                    guard let modifiedPlace = try? diff.document.data(as: Place.self) else { return }

                    switch diff.type {
                    case .added:
                        places.append(modifiedPlace)
                    case .modified:
                        if let index = places.firstIndex(where: { $0.id == modifiedPlace.id }) {
                            places[index].arrangedTime = modifiedPlace.arrangedTime
                        }
                    case .removed:
                        if let index = places.firstIndex(where: { $0.id == modifiedPlace.id }) {
                            places.remove(at: index)
                        }
                    }
                }
                filterPlace(by: currentSelectedDate)
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
        let wishVC = WishListViewController(trip: trip, fsManager: fsManager)
        navigationController?.pushViewController(wishVC, animated: true)
    }

    @objc func openChatRoom(_ sender: UIButton) {
        let chatVC = ChatRoomViewController(trip: trip, fsManager: fsManager)
        let nav = UINavigationController(rootViewController: chatVC)
//        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
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

            fsManager.updateTrip(tripID, field: .isPublic, data: true)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    switch completion {
                    case .finished:
                        JGHudIndicator.shared.showHud(type: .success)
                    case .failure:
                        JGHudIndicator.shared.showHud(type: .failure)
                    }
                } receiveValue: { _ in }
                .store(in: &cancelBags)
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
        let actionSheetVC = UIAlertController(
            title: String(localized: "Choose image from"),
            message: nil,
            preferredStyle: .actionSheet)
        let unSplashSource = UIAlertAction(title: "Unsplash", style: .default) { [unowned self] _ in
            guard let url = Bundle.main.url(forResource: "UnsplashKeys", withExtension: "plist") else {
                return
            }

            do {
                let data = try Data(contentsOf: url)
                let result = try PropertyListDecoder().decode(UnsplashKey.self, from: data)
                let config = UnsplashPhotoPickerConfiguration(accessKey: result.accessKey, secretKey: result.secretKey)
                let photoPicker = UnsplashPhotoPicker(configuration: config)
                photoPicker.photoPickerDelegate = self
                self.present(photoPicker, animated: true)
            } catch {
                return
            }
        }

        let photoLibrary = UIAlertAction(
            title: String(localized: "Photo Library"),
            style: .default) { [unowned self] _ in
                var config = PHPickerConfiguration()
                config.filter = .images
                let picker = PHPickerViewController(configuration: config)
                picker.delegate = self
                self.present(picker, animated: true)
            }

        let cancel = UIAlertAction(title: String(localized: "Cancel"), style: .cancel)

        actionSheetVC.addAction(unSplashSource)
        actionSheetVC.addAction(photoLibrary)
        actionSheetVC.addAction(cancel)
        present(actionSheetVC, animated: true)
    }

    @objc func copyItinerary(_ sender: UIBarButtonItem) {
        let addTripVC = AddNewTripViewController(isCopy: true, fsManager: fsManager)
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
        dataSource.applySnapshotUsingReloadData(snapshot) {
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

        JGHudIndicator.shared.showHud(type: .loading(text: String(localized: "Calculate...")))
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
            viewController = ArrangePlaceViewController(trip: trip, place: place, isEditMode: false, fsManager: fsManager)
        } else {
            let apiService = GPlaceAPIManager()
            viewController = PlaceDetailViewController(place: place, fsManager: fsManager, apiService: apiService)
        }
        navigationController?.pushViewController(viewController, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard isEditMode else { return nil }
        guard let place = dataSource.itemIdentifier(for: indexPath) else { return nil }
        let deleteAction = UIContextualAction(style: .destructive, title: String(localized: "Delete")) { [unowned self] _, _, completion in
            guard
                let tripId = trip.id,
                let placeId = place.id
            else {
                return
            }

            fsManager.deleteTrip(tripId, place: placeId)
                .receive(on: DispatchQueue.main)
                .sink { [unowned self] result in
                    switch result {
                    case .finished:
                        completion(true)
                    case .failure(let error):
                        self.showAlertToUser(error: error)
                    }
                } receiveValue: { _ in }
                .store(in: &cancelBags)
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

                        fsManager.batchUpdatePlaces(at: trip, from: sourceItem, to: destinationItem)
                            .receive(on: DispatchQueue.main)
                            .sink { [unowned self] result in
                                switch result {
                                case .finished:
                                    break
                                case .failure(let error):
                                    self.showAlertToUser(error: error)
                                }
                            } receiveValue: { _ in }
                            .store(in: &cancelBags)
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
        JGHudIndicator.shared.showHud(type: .loading(text: "Updating"))

        let itemProviders = results.map(\.itemProvider)
        if let itemProvider = itemProviders.first, itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                guard let self = self, let image = image as? UIImage else { return }
                self.updateTripImage(image: image)
            }
        }
    }

    private func updateTripImage(image: UIImage) {
        guard
            let tripId = trip.id,
            let imageData = image.jpegData(compressionQuality: 0.3)
        else {
            return
        }

        storageManager.uploadImage(imageData, at: .trips, with: tripId)
            .flatMap { _ in
                self.storageManager.downloadRef(at: .trips, with: tripId)
            }
            .flatMap { url in
                self.fsManager.updateTrip(tripId, field: .image, data: url.absoluteString)
            }
            .sink { [unowned self] completion in
                switch completion {
                case .finished:
                    imageView.image = image
                    JGHudIndicator.shared.dismissHUD()
                case .failure(let error):
                    self.showAlertToUser(error: error)
                }
            } receiveValue: { _ in }
            .store(in: &cancelBags)
    }
}

extension EditTripViewController: UnsplashPhotoPickerDelegate {

    func unsplashPhotoPicker(_ photoPicker: UnsplashPhotoPicker, didSelectPhotos photos: [UnsplashPhoto]) {
        guard let photo = photos.first?.urls[.regular] else { return }
        imageView.sd_setImage(with: photo) { [weak self] image, _, _, _ in
            guard let self = self, let image = image else { return }
            self.updateTripImage(image: image)
        }
    }

    func unsplashPhotoPickerDidCancel(_ photoPicker: UnsplashPhotoPicker) { }
}
