//
//  EditTripViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/23.
//

import UIKit
import FirebaseFirestore
import TinyConstraints

class EditTripViewController: UIViewController {

    let trip: Trip

    init(trip: Trip) {
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    enum Section {
        case main
    }

    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: .init(named: "placeholder2"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 34
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy var scheduleView = ScheduleView()

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.delegate = self
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.register(ArrangePlaceCell.self, forCellWithReuseIdentifier: ArrangePlaceCell.identifier)
        return collectionView
    }()

    private var listener: ListenerRegistration?
    private var dataSource: UICollectionViewDiffableDataSource<Section, Place>!
    private var places: [Place] = []
    private var filterPlaces: [Place] = []
    private lazy var currentSelectedDate = trip.startDate

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        customNavBar()
        setupUI()
        scheduleView.schedules = convertDateToDisplay()
        scheduleView.delegate = self
        configureDataSource()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        scheduleView.collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .centeredVertically)
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
        view.addSubview(collectionView)

        imageView.edgesToSuperview(excluding: .bottom, insets: .top(8) + .horizontal(16), usingSafeArea: true)
        imageView.height(120)

        scheduleView.topToBottom(of: imageView)
        scheduleView.horizontalToSuperview(insets: .horizontal(16))
        scheduleView.height(80)

        collectionView.topToBottom(of: scheduleView)
        collectionView.edgesToSuperview(excluding: .top, usingSafeArea: true)
    }

    private func fetchPlaces() {
        guard let tripID = trip.id else { return }
        places.removeAll(keepingCapacity: true)

        listener = FireStoreService.shared.addListenerInTripPlaces(tripId: tripID, isArrange: true) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let place):
                self.places = place

                DispatchQueue.main.async {
                    self.updateSnapshot(by: self.currentSelectedDate)
                }
            case .failure(let error):
                self.showAlertToUser(error: error)
            }
        }
    }

    private func customNavBar() {
        title = trip.tripName

        let chatRoomButton = UIBarButtonItem(
            image: UIImage(systemName: "person.2"),
            style: .plain,
            target: self,
            action: #selector(openChatRoom))
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
        navigationItem.rightBarButtonItems = [chatRoomButton, editListButton, shareButton]
    }

    @objc func openChatRoom(_ sender: UIBarButtonItem) {
        // Check if room exist in FireStore
        let chatVC = ChatRoomViewController()
        chatVC.trip = trip
        let nav = UINavigationController(rootViewController: chatVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
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
                if let error = error {
                    self.showAlertToUser(error: error)
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

    private func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(68))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 12
        section.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)

        return UICollectionViewCompositionalLayout(section: section)
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            guard let arrangeCell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ArrangePlaceCell.identifier,
                for: indexPath) as? ArrangePlaceCell
            else {
                fatalError("Failed to dequeue cityCell")
            }

            arrangeCell.config(with: item)
            return arrangeCell
        }
    }

    private func updateSnapshot(by date: Date) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Place>()
        snapshot.appendSections([.main])

        let filterResults = places.filter { $0.arrangedTime?.resetHourAndMinute() == date.resetHourAndMinute() }
        // swiftlint: disable force_unwrapping
        filterPlaces = filterResults.sorted { $0.arrangedTime! < $1.arrangedTime! }
        // swiftlint: enable force_unwrapping
        snapshot.appendItems(filterPlaces)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - CollectionView Delegate
extension EditTripViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
}


// MARK: - CollectionView Drag Delegate
extension EditTripViewController: UICollectionViewDragDelegate {

    func collectionView(_ collectionView: UICollectionView, dragSessionWillBegin session: UIDragSession) {
    }

    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let placeItem = String(filterPlaces[indexPath.item].arrangedTime?.ISO8601Format() ?? "")
        let itemProvider = NSItemProvider(object: placeItem as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = placeItem
        return [dragItem]
    }
}


// MARK: - CollectionView Drop Delegate
extension EditTripViewController: UICollectionViewDropDelegate {

    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        if collectionView.hasActiveDrag {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }

        return UICollectionViewDropProposal(operation: .forbidden)
    }

    func collectionView(_ collectionView: UICollectionView, dropSessionDidEnd session: UIDropSession) {
    }

    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        var destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let items = dataSource.snapshot().numberOfItems(inSection: .main)
            destinationIndexPath = IndexPath(item: items - 1, section: 0)
        }

        if coordinator.proposal.operation == .move {
            moveItem(coordinator: coordinator, destinationIndexPath: destinationIndexPath, collectionView: collectionView)
        }
    }

    private func moveItem(coordinator: UICollectionViewDropCoordinator, destinationIndexPath: IndexPath, collectionView: UICollectionView) {
        if let dragItem = coordinator.items.first,
            let sourceIndexPath = dragItem.sourceIndexPath {

            collectionView.performBatchUpdates {
                for item in coordinator.items {
                    let placeTime = item.dragItem.localObject as? String
                    let formatter = ISO8601DateFormatter()

                    if let dateString = placeTime,
                        let date = formatter.date(from: dateString) {

                        var sourceItem = filterPlaces[sourceIndexPath.item]
                        var destinationItem = filterPlaces[destinationIndexPath.item]

                        sourceItem.arrangedTime = destinationItem.arrangedTime
                        destinationItem.arrangedTime = date

                        FireStoreService.shared.batchUpdate(at: trip, from: sourceItem, to: destinationItem) {
                            print("Ha Ha, that's some easy.")
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
        updateSnapshot(by: selectedDate)
    }
}
