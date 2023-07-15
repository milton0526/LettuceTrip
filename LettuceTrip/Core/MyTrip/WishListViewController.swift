//
//  WishListViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/25.
//

import UIKit
import Combine
import TinyConstraints
import FirebaseFirestore

class WishListViewController: UIViewController, UICollectionViewDelegate {

    enum Section {
        case main
    }

    let trip: Trip
    let fsManager: FirestoreManager

    init(trip: Trip, fsManager: FirestoreManager) {
        self.trip = trip
        self.fsManager = fsManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var dataSource: UICollectionViewDiffableDataSource<Section, Place>!
    private var listener: ListenerRegistration?
    private var places: [Place] = []
    private var cancelBags: Set<AnyCancellable> = []

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.delegate = self
        return collectionView
    }()

    private lazy var placeHolder = makePlaceholder(text: String(localized: "There's nothing here!"))

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Wish List")
        setupUI()
        configDataSource()
        fetchPlaces()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        collectionView.edgesToSuperview(usingSafeArea: true)
    }

    private func fetchPlaces() {
        guard let tripID = trip.id else { return }

        fsManager.placeListener(at: tripID, isArrange: false)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.showAlertToUser(error: error)
                }
            } receiveValue: { [weak self] snapshot in
                guard let self = self else { return }
                if places.isEmpty {
                    let firstResult = snapshot.documents.compactMap { try? $0.data(as: Place.self) }
                    places = firstResult
                    placeHolder.isHidden = places.isEmpty ? false : true
                    updateSnapshot()
                    return
                }

                snapshot.documentChanges.forEach { diff in
                    guard let modifiedPlace = try? diff.document.data(as: Place.self) else { return }

                    switch diff.type {
                    case .added:
                        self.places.append(modifiedPlace)
                    case .modified:
                        if let index = self.places.firstIndex(where: { $0.id == modifiedPlace.id }) {
                            self.places[index].arrangedTime = modifiedPlace.arrangedTime
                        }
                    case .removed:
                        if let index = self.places.firstIndex(where: { $0.id == modifiedPlace.id }) {
                            self.places.remove(at: index)
                        }
                    }
                }

                placeHolder.isHidden = places.isEmpty ? false : true
                updateSnapshot()
            }
            .store(in: &cancelBags)
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        var config = UICollectionLayoutListConfiguration(appearance: .plain)
        config.trailingSwipeActionsConfigurationProvider = { indexPath in
            let deleteAction = UIContextualAction(style: .destructive, title: String(localized: "Delete")) { [weak self] _, _, completion in
                guard
                    let self = self,
                    let tripId = trip.id
                else {
                    return
                }

                if let item = dataSource.itemIdentifier(for: indexPath)?.id {
                    fsManager.deleteTrip(tripId, place: item)
                        .receive(on: DispatchQueue.main)
                        .sink { result in
                            switch result {
                            case .finished:
                                completion(true)
                            case .failure(let error):
                                self.showAlertToUser(error: error)
                            }
                        } receiveValue: { _ in }
                        .store(in: &cancelBags)
                }
            }
            return .init(actions: [deleteAction])
        }

        return UICollectionViewCompositionalLayout.list(using: config)
    }

    private func cellRegistration(_ cell: UICollectionViewListCell, indexPath: IndexPath, item: Place) {
        var config = cell.defaultContentConfiguration()
        config.text = item.name
        config.image = UIImage(data: item.iconImage)?.withTintColor(.tintColor)
        config.imageProperties.maximumSize = .init(width: 35, height: 35)
        cell.contentConfiguration = config
    }

    private func configDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Place>(handler: cellRegistration)

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            return cell
        }
    }

    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Place>()
        snapshot.appendSections([.main])
        snapshot.appendItems(places)
        dataSource.apply(snapshot, animatingDifferences: false)
    }


    // MARK: CollectionView Delegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        let place = places[indexPath.item]

        let arrangeVC = ArrangePlaceViewController(trip: trip, place: place, fsManager: fsManager)
        navigationController?.pushViewController(arrangeVC, animated: true)
    }
}
