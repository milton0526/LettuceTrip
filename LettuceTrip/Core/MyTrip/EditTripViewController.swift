//
//  EditTripViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/23.
//

import UIKit
import TinyConstraints

class EditTripViewController: UIViewController {

    enum Section {
        case unarranged
        case calendar
        case inOrder
    }

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.delegate = self
        collectionView.register(PopularCityCollectionViewCell.self, forCellWithReuseIdentifier: PopularCityCollectionViewCell.identifier)
        collectionView.register(ArrangePlaceCell.self, forCellWithReuseIdentifier: ArrangePlaceCell.identifier)
        collectionView.register(CalendarCell.self, forCellWithReuseIdentifier: CalendarCell.identifier)
        collectionView.register(
            PopularCityHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: PopularCityHeaderView.identifier)
        return collectionView
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Section, Int>!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        customNavBar()
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
        title = String(localized: "Planning")

        let chatRoomButton = UIBarButtonItem(image: UIImage(systemName: "person.2"), style: .plain, target: self, action: #selector(openChatRoom))
        navigationItem.rightBarButtonItem = chatRoomButton
    }

    @objc func openChatRoom(_ sender: UIButton) {
        let chatVC = ChatRoomViewController()
        let nav = UINavigationController(rootViewController: chatVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { [weak self] section, _ in
            guard let self = self else { fatalError("Failed to create layout") }

            let sectionType = self.dataSource.snapshot().sectionIdentifiers[section]
            switch sectionType {
            case .unarranged:
                return self.configUnarrangedSectionLayout()
            case .calendar:
                return self.configCalendarSectionLayout()
            case .inOrder:
                return self.configInOrderSectionLayout()
            }
        }
    }

    private func configUnarrangedSectionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(100),
            heightDimension: .absolute(125))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
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

    private func configInOrderSectionLayout() -> NSCollectionLayoutSection {
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

        return section
    }

    private func configCalendarSectionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .absolute(44),
            heightDimension: .absolute(60))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 12
        section.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
        section.orthogonalScrollingBehavior = .continuous

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

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, _ in
            guard let self = self else { return UICollectionViewCell() }
            let section = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]

            switch section {
            case .unarranged:
                guard let cityCell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: PopularCityCollectionViewCell.identifier,
                    for: indexPath) as? PopularCityCollectionViewCell
                else {
                    fatalError("Failed to dequeue cityCell")
                }

                return cityCell

            case .calendar:
                guard let calendarCell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CalendarCell.identifier,
                    for: indexPath) as? CalendarCell
                else {
                    fatalError("Failed to dequeue cityCell")
                }

                return calendarCell

            case .inOrder:
                guard let arrangeCell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: ArrangePlaceCell.identifier,
                    for: indexPath) as? ArrangePlaceCell
                else {
                    fatalError("Failed to dequeue cityCell")
                }

                return arrangeCell
            }
        }

        configSupplementaryView()
    }

    private func configSupplementaryView() {
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath -> UICollectionReusableView? in
            guard let self = self else { return nil }
            guard let headerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: PopularCityHeaderView.identifier,
                for: indexPath) as? PopularCityHeaderView
            else {
                return nil
            }

            headerView.titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
            let section = self.dataSource.snapshot().sectionIdentifiers[indexPath.section]

            switch section {
            case .unarranged:
                headerView.titleLabel.text = "Not arrange"
            case .calendar:
                headerView.titleLabel.text = "In order"
            case .inOrder:
                return nil
            }
            return headerView
        }
    }

    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Int>()

        snapshot.appendSections([.unarranged, .calendar, .inOrder])
        snapshot.appendItems(Array(1...20), toSection: .unarranged)
        snapshot.appendItems(Array(41...55), toSection: .calendar)
        snapshot.appendItems(Array(21...40), toSection: .inOrder)

        dataSource.apply(snapshot)
    }
}

// MARK: - CollectionView Delegate
extension EditTripViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
}
