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
        case popularCity
        case itinerary
    }

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.delegate = self
        collectionView.register(
            PopularCityCollectionViewCell.self,
            forCellWithReuseIdentifier: PopularCityCollectionViewCell.identifier)
        collectionView.register(
            ItineraryCollectionViewCell.self,
            forCellWithReuseIdentifier: ItineraryCollectionViewCell.identifier)
        collectionView.register(
            PopularCityHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: PopularCityHeaderView.identifier)
        return collectionView
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Section, Int>!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureDataSource()
        updateSnapshot()
    }

    private func setupUI() {
        view.addSubview(collectionView)
        collectionView.edgesToSuperview(usingSafeArea: true)
        customNavBar()
    }

    private func customNavBar() {
        let welcomeView = UILabel()
        welcomeView.text = String(localized: "Hi👋 Milton!")
        welcomeView.font = .systemFont(ofSize: 20, weight: .bold)
        welcomeView.textColor = .label

        let userImageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: 40, height: 40)))
        userImageView.image = UIImage(systemName: "person.circle")
        userImageView.contentMode = .scaleAspectFit
        userImageView.clipsToBounds = true
        userImageView.layer.cornerRadius = 20
        userImageView.layer.masksToBounds = true

        let leftBarItem = UIBarButtonItem(customView: welcomeView)
        let rightBarItem = UIBarButtonItem(customView: userImageView)
        navigationItem.leftBarButtonItem = leftBarItem
        navigationItem.rightBarButtonItem = rightBarItem
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] section, _ in
            guard let self = self else { fatalError("Failed to create layout") }

            let sectionType = self.dataSource.snapshot().sectionIdentifiers[section]
            switch sectionType {
            case .popularCity:
                return self.configPopularSectionLayout()
            case .itinerary:
                return self.configItineraryLayout()
            }
        }
    }

    private func configPopularSectionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(160),
            heightDimension: .absolute(220))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuousGroupLeadingBoundary
        section.interGroupSpacing = 12
        section.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(50))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .topLeading)
        section.boundarySupplementaryItems = [header]

        return section
    }

    private func configItineraryLayout() -> NSCollectionLayoutSection {
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

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(50))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .topLeading)
        header.pinToVisibleBounds = true
        section.boundarySupplementaryItems = [header]
        
        return section
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, _ in
            guard let self = self else { return UICollectionViewCell() }
            let section = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]

            switch section {
            case .popularCity:
                guard let cityCell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: PopularCityCollectionViewCell.identifier,
                    for: indexPath) as? PopularCityCollectionViewCell
                else {
                    fatalError("Failed to dequeue cityCell")
                }

                return cityCell
            case .itinerary:
                guard let itineraryCell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ItineraryCollectionViewCell.identifier,
                    for: indexPath) as? ItineraryCollectionViewCell
                else {
                    fatalError("Failed to dequeue cityCell")
                }

                return itineraryCell
            }
        }

        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath -> UICollectionReusableView? in
            guard let self = self else { return nil }

            guard let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: PopularCityHeaderView.identifier,
                for: indexPath) as? PopularCityHeaderView
            else {
                return nil
            }

            let section = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]

            switch section {
            case .popularCity:
                headerView.titleLabel.text = "Discover popular cities"
            case .itinerary:
                headerView.titleLabel.text = "Other's Itinerary"
            }
            return headerView
        }
    }

    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Int>()

        snapshot.appendSections([.popularCity, .itinerary])
        snapshot.appendItems(Array(1...20), toSection: .popularCity)
        snapshot.appendItems(Array(21...40), toSection: .itinerary)

        dataSource.apply(snapshot)
    }
}

// MARK: - CollectionView Delegate
extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
