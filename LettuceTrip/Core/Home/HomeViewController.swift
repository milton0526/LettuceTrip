//
//  HomeViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit
import MapKit
import Combine
import TinyConstraints

class HomeViewController: UIViewController {

    enum Section {
        case main
    }

    // properties
    private let viewModel: HomeViewModelType
    private let eventSubject: PassthroughSubject<Void, Never> = .init()
    private var cancelBags: Set<AnyCancellable> = []
    private var dataSource: UICollectionViewDiffableDataSource<Section, Trip>!

    init(viewModel: HomeViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // View components
    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.delegate = self
        collectionView.register(
            ItineraryCell.self,
            forCellWithReuseIdentifier: ItineraryCell.identifier)
        collectionView.register(
            ItineraryHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ItineraryHeaderView.identifier)
        return collectionView
    }()

    private let refreshControl = UIRefreshControl()
    private lazy var placeHolder = makePlaceholder(text: String(localized: "Oops! No one share there trip!🥲"))

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureDataSource()
        configureRefreshControl()
        bind()
        eventSubject.send(())
    }

    private func setupUI() {
        navigationItem.title = String(localized: "Community")
        view.addSubview(collectionView)
        collectionView.edgesToSuperview(usingSafeArea: true)
    }

    private func configureRefreshControl() {
        refreshControl.tintColor = .tintColor
        refreshControl.attributedTitle = .init("Refreshing...")
        collectionView.refreshControl = refreshControl
        collectionView.refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(180))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 12
        section.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)

        return UICollectionViewCompositionalLayout(section: section)
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            guard let itineraryCell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ItineraryCell.identifier,
                for: indexPath) as? ItineraryCell
            else {
                fatalError("Failed to dequeue cityCell")
            }

            itineraryCell.delegate = self
            itineraryCell.config(with: item)
            return itineraryCell
        }
    }

    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Trip>()

        snapshot.appendSections([.main])
        snapshot.appendItems(viewModel.shareTrips)
        dataSource.apply(snapshot)
    }

    @objc func handleRefreshControl() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.eventSubject.send(())
        }
    }

    private func bind() {
        viewModel.transform(input: eventSubject.eraseToAnyPublisher())

        // Output
        viewModel.updateViewPublisher
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] completion in
                switch completion {
                case .finished: break
                case .failure(let error):
                    self?.showAlertToUser(error: error)
                }
            } receiveValue: { [weak self] _ in
                guard let self = self else { return }
                self.placeHolder.isHidden = self.viewModel.shareTrips.isEmpty ? false : true
                self.refreshControl.endRefreshing()
                self.updateSnapshot()
            }
            .store(in: &cancelBags)
    }
}

// MARK: - CollectionView Delegate
extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        let trip = viewModel.shareTrips[indexPath.item]
        // let editVC = EditTripViewController(trip: trip, isEditMode: false, fsManager: fsManager)
        // navigationController?.pushViewController(editVC, animated: true)
    }
}

// MARK: Itinerary cell Delegate
extension HomeViewController: ItineraryCellDelegate {

    func reportAction(_ cell: ItineraryCell) {
        let alertVC = UIAlertController(
            title: String(localized: "We received your report!"),
            message: String(localized: "Our team will check ASAP, Thanks!"),
            preferredStyle: .alert)
        let okAction = UIAlertAction(title: String(localized: "OK"), style: .default)
        alertVC.addAction(okAction)
        present(alertVC, animated: true)
    }
}
