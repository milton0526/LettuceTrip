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
        collectionView.register(ArrangePlaceCell.self, forCellWithReuseIdentifier: ArrangePlaceCell.identifier)
        return collectionView
    }()

    private var listener: ListenerRegistration?
    private var dataSource: UICollectionViewDiffableDataSource<Section, Place>!
    private var places: [Place] = []
    private var filterPlaces: [Place] = []

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
                guard let place = place else { return }
                self.places.append(place)

                DispatchQueue.main.async {
                    self.updateSnapshot(by: self.trip.startDate)
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
        navigationItem.rightBarButtonItems = [chatRoomButton, editListButton]
    }

    @objc func openChatRoom(_ sender: UIBarButtonItem) {
        // Check if room exist in FireStore
        let chatVC = ChatRoomViewController()
        let nav = UINavigationController(rootViewController: chatVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    @objc func openWishList(_ sender: UIBarButtonItem) {
        let wishVC = WishListViewController(trip: trip)
        navigationController?.pushViewController(wishVC, animated: true)
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
        filterPlaces = filterResults.sorted { $0.arrangedTime! < $1.arrangedTime! }

        snapshot.appendItems(filterPlaces)
        dataSource.apply(snapshot)
    }
}

// MARK: - CollectionView Delegate
extension EditTripViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
}

// MARK: - ScheduleView Delegate
extension EditTripViewController: ScheduleViewDelegate {
    func didSelectedDate(_ view: ScheduleView, selectedDate: Date) {
        updateSnapshot(by: selectedDate)
    }
}
