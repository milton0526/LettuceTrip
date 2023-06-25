//
//  EditTripViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/23.
//

import UIKit
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

    struct Schedule {
        let day: Int
        let weekday: String
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

    private var dataSource: UICollectionViewDiffableDataSource<Section, Int>!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        customNavBar()
        setupUI()
        scheduleView.schedules = convertDateToDisplay()
        configureDataSource()
        updateSnapshot()
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
            action: #selector(openEditList))
        navigationItem.rightBarButtonItems = [chatRoomButton, editListButton]
    }

    @objc func openChatRoom(_ sender: UIBarButtonItem) {
        // Check if room exist in FireStore
        let chatVC = ChatRoomViewController()
        let nav = UINavigationController(rootViewController: chatVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    @objc func openEditList(_ sender: UIBarButtonItem) {
        let wishVC = WishListViewController(trip: trip)
        navigationController?.pushViewController(wishVC, animated: true)
    }

    private func convertDateToDisplay() -> [Schedule] {
        let dayRange = 0...trip.duration
        let travelDays = dayRange.map { range in
            // swiftlint: disable force_unwrapping
            Calendar.current.date(byAdding: .day, value: range, to: trip.startDate)!
            // swiftlint: enable force_unwrapping
        }

        let schedule = travelDays.map { date in
            let component = Calendar.current.dateComponents([.day, .weekday], from: date)

            if let day = component.day, let weekday = component.weekday {
                let weekDaySymbol = Calendar.current.shortWeekdaySymbols[weekday - 1]

                return Schedule(day: day, weekday: weekDaySymbol)
            } else {
                return Schedule(day: 0, weekday: "")
            }
        }

        return schedule
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

            return arrangeCell
        }
    }

    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Int>()
        snapshot.appendSections([.main])

        snapshot.appendItems(Array(1...20))
        dataSource.apply(snapshot)
    }
}

// MARK: - CollectionView Delegate
extension EditTripViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }
}
