//
//  EditTripViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/23.
//

import UIKit
import TinyConstraints
import MapKit
import Combine
import SDWebImage
import PhotosUI
import UnsplashPhotoPicker

class EditTripViewController: UIViewController {
    var viewModel: EditTripViewModel

    init(viewModel: EditTripViewModel) {
        self.viewModel = viewModel
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
        imageView.setContentMode()
        imageView.makeCornerRadius(34)
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

    var dataSource: UITableViewDiffableDataSource<Section, Place>!
    private var cancelBags: Set<AnyCancellable> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.trip.tripName
        navigationItem.backButtonDisplayMode = .minimal
        view.backgroundColor = .systemBackground
        setupUI()
        scheduleView.schedules = viewModel.convertDateToDisplay()
        scheduleView.delegate = self
        configureDataSource()
        setEditMode()
        scheduleView.collectionView.selectItem(at: IndexPath(item: 0, section: 0), animated: false, scrollPosition: .centeredVertically)
        bind()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.fetchPlaces()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.listenerSubscription?.cancel()
        viewModel.listenerSubscription = nil
    }

    private func setupUI() {
        [imageView, scheduleView, tableView, messageButton].forEach { view.addSubview($0) }

        if let url = URL(string: viewModel.trip.image ?? "") {
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
        messageButton.layer.shadowColor = UIColor.gray.cgColor
        messageButton.layer.shadowRadius = 5
        messageButton.layer.shadowOpacity = 1
        messageButton.layer.masksToBounds = false
        messageButton.layer.shadowOffset = .zero
        messageButton.trailingToSuperview(offset: 16)
        messageButton.bottomToSuperview(offset: -32, usingSafeArea: true)
    }

    private func setEditMode() {
        if viewModel.isEditMode {
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

    private func bind() {
        viewModel.outputPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .updateView:
                    updateSnapshot()
                case .showIndicator(let loading):
                    if loading {
                        JGHudIndicator.shared.showHud(type: .loading())
                    } else {
                        JGHudIndicator.shared.showHud(type: .success)
                    }
                case .dismissHud:
                    JGHudIndicator.shared.dismissHUD()
                case .displayError(let error):
                    showAlertToUser(error: error)
                }
            }
            .store(in: &cancelBags)
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
        let fsManager = FirestoreManager()
        let wishVC = WishListViewController(viewModel: WishListViewModel(trip: viewModel.trip, fsManager: fsManager))
        navigationController?.pushViewController(wishVC, animated: true)
    }

    @objc func openChatRoom(_ sender: UIButton) {
        let fsManager = FirestoreManager()
        let chatVC = ChatRoomViewController(viewModel: ChatRoomViewModel(trip: viewModel.trip, fsManager: fsManager))
        let nav = UINavigationController(rootViewController: chatVC)
        present(nav, animated: true)
    }

    @objc func shareTrip(_ sender: UIBarButtonItem) {
        guard let tripID = viewModel.trip.id else { return }

        let actionSheet = UIAlertController(
            title: String(localized: "Share this trip to..."),
            message: nil,
            preferredStyle: .actionSheet)

        let shareToCommunity = UIAlertAction(title: String(localized: "Community"), style: .default) { [weak self] _ in
            // share to home page
            guard let self = self else { return }
            viewModel.updateTrip()
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
        let unSplashSource = UIAlertAction(title: "Unsplash", style: .default) { [weak self] _ in
            guard let url = Bundle.main.url(forResource: "UnsplashKeys", withExtension: "plist") else {
                return
            }

            do {
                let data = try Data(contentsOf: url)
                let result = try PropertyListDecoder().decode(UnsplashKey.self, from: data)
                let config = UnsplashPhotoPickerConfiguration(accessKey: result.accessKey, secretKey: result.secretKey)
                let photoPicker = UnsplashPhotoPicker(configuration: config)
                photoPicker.photoPickerDelegate = self
                self?.present(photoPicker, animated: true)
            } catch {
                return
            }
        }

        let photoLibrary = UIAlertAction(
            title: String(localized: "Photo Library"),
            style: .default) { [weak self] _ in
                var config = PHPickerConfiguration()
                config.filter = .images
                let picker = PHPickerViewController(configuration: config)
                picker.delegate = self
                self?.present(picker, animated: true)
            }

        let cancel = UIAlertAction(title: String(localized: "Cancel"), style: .cancel)

        actionSheetVC.addAction(unSplashSource)
        actionSheetVC.addAction(photoLibrary)
        actionSheetVC.addAction(cancel)
        present(actionSheetVC, animated: true)
    }

    @objc func copyItinerary(_ sender: UIBarButtonItem) {
        let trip = viewModel.trip
        let fsManager = FirestoreManager()
        let addTripVC = AddNewTripViewController(isCopy: true, fsManager: fsManager)
        let placeMark = MKPlacemark(coordinate: trip.coordinate)
        let mapItem = MKMapItem(placemark: placeMark)
        mapItem.name = trip.destination
        addTripVC.selectedCity = mapItem
        addTripVC.copyFromTrip = trip
        addTripVC.places = viewModel.allPlaces
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

    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { [weak self] tableView, indexPath, item in
            guard let self = self else { return UITableViewCell() }
            guard let arrangeCell = tableView.dequeueReusableCell(
                withIdentifier: ArrangePlaceCell.identifier,
                for: indexPath) as? ArrangePlaceCell
            else {
                fatalError("Failed to dequeue cityCell")
            }

            if indexPath.item < viewModel.estimatedTimes.count {
                arrangeCell.config(with: item, isEditMode: viewModel.isEditMode, travelTime: viewModel.estimatedTimes[indexPath.item] ?? "")
            } else {
                arrangeCell.config(with: item, isEditMode: viewModel.isEditMode)
            }
            return arrangeCell
        }
    }

    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Place>()
        snapshot.appendSections([.main])
        snapshot.appendItems(viewModel.sortedPlaces)
        // use snapshot reload method to avoid weird animation
        dataSource.applySnapshotUsingReloadData(snapshot) {
            JGHudIndicator.shared.dismissHUD()
        }
    }
}
