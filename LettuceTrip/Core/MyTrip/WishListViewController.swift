//
//  WishListViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/25.
//

import UIKit
import TinyConstraints
import FirebaseFirestore

class WishListViewController: UIViewController, UICollectionViewDelegate {

    enum Section {
        case main
    }

    let trip: Trip

    init(trip: Trip) {
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var dataSource: UICollectionViewDiffableDataSource<Section, Place>!
    private var listener: ListenerRegistration?
    private var places: [Place] = []

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.delegate = self
        return collectionView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Wish List")
        setupUI()
        configDataSource()
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
        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        collectionView.edgesToSuperview(usingSafeArea: true)

        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.backward"),
            style: .plain,
            target: self,
            action: #selector(popView))
        navigationItem.hidesBackButton = true
        navigationItem.leftBarButtonItem = backButton
    }

    @objc func popView(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }

    private func fetchPlaces() {
        guard let tripID = trip.id else { return }
        places.removeAll(keepingCapacity: true)

        listener = FireStoreService.shared.addListenerInTripPlaces(tripId: tripID) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let place):
                guard let place = place else { return }
                self.places.append(place)

                DispatchQueue.main.async {
                    self.updateSnapshot()
                }
            case .failure(let error):
                self.showAlertToUser(error: error)
            }
        }
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        let config = UICollectionLayoutListConfiguration(appearance: .plain)
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
        dataSource.apply(snapshot)
    }


    // MARK: CollectionView Delegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        let place = places[indexPath.item]

        let arrangeVC = ArrangePlaceViewController()
        arrangeVC.trip = trip
        arrangeVC.place = place
        navigationController?.pushViewController(arrangeVC, animated: true)
    }
}
