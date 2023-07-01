//
//  HomeViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit
import TinyConstraints

class HomeViewController: UIViewController {

    enum Section {
        case main
    }

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.delegate = self
        collectionView.register(
            ItineraryCollectionViewCell.self,
            forCellWithReuseIdentifier: ItineraryCollectionViewCell.identifier)
        collectionView.register(
            ItineraryHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ItineraryHeaderView.identifier)
        return collectionView
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Section, Trip>!
    private var shareTrips: [Trip] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureDataSource()
        fetchData()
    }

    private func setupUI() {
        navigationItem.title = String(localized: "Discover")
        view.addSubview(collectionView)
        collectionView.edgesToSuperview(usingSafeArea: true)
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(200))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 12
        section.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)

        return UICollectionViewCompositionalLayout(section: section)
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            guard let itineraryCell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ItineraryCollectionViewCell.identifier,
                for: indexPath) as? ItineraryCollectionViewCell
            else {
                fatalError("Failed to dequeue cityCell")
            }

            itineraryCell.config(with: item)
            return itineraryCell
        }
    }

    private func fetchData() {

        FireStoreService.shared.fetchShareTrips { [weak self] result in

            DispatchQueue.main.async {
                switch result {
                case .success(let trips):
                    self?.shareTrips = trips
                    self?.updateSnapshot()
                case .failure(let error):
                    self?.showAlertToUser(error: error)
                }
            }
        }
    }

    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Trip>()

        snapshot.appendSections([.main])
        snapshot.appendItems(shareTrips)
        dataSource.apply(snapshot)
    }
}

// MARK: - CollectionView Delegate
extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        // let trip = shareTrips[indexPath.item]
    }
}
