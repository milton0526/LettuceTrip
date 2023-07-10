//
//  MyTripViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit
import Combine
import TinyConstraints
import FirebaseFirestore

class MyTripViewController: UIViewController {

    enum Segment: CaseIterable {
        case upcoming
        case closed

        var title: String {
            switch self {
            case .upcoming:
                return String(localized: "Upcoming")
            case .closed:
                return String(localized: "Closed")
            }
        }
    }

    lazy var selectionView: SelectionView = {
        let selectionView = SelectionView()
        selectionView.delegate = self
        selectionView.dataSource = self
        return selectionView
    }()

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.register(TripCell.self, forCellReuseIdentifier: TripCell.identifier)
        return tableView
    }()

    lazy var addTripButton: UIButton = {
        let button = UIButton()
        button.setBackgroundImage(.init(systemName: "plus.circle.fill"), for: .normal)
        button.addTarget(self, action: #selector(addTripButtonTapped), for: .touchUpInside)
        return button
    }()

    private var listener: ListenerRegistration?
    private var allTrips: [Trip] = []
    private var filterTrips: [Segment: [Trip]] = [:]
    private var currentSegment: Segment = .upcoming
    private lazy var placeHolder = makePlaceholder(text: String(localized: "Add new trip to start!"))
    private var cancelBags: Set<AnyCancellable> = []
    private let fsManager = FirestoreManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = String(localized: "My trips")
        navigationItem.backButtonDisplayMode = .minimal
        setupUI()
        fetchUserTrips()
    }

    private func setupUI() {
        [selectionView, tableView, addTripButton].forEach { view.addSubview($0) }
        selectionView.edgesToSuperview(excluding: .bottom, usingSafeArea: true)

        tableView.topToBottom(of: selectionView)
        tableView.edgesToSuperview(excluding: .top, usingSafeArea: true)

        addTripButton.size(CGSize(width: 60, height: 60))
        addTripButton.trailingToSuperview(offset: 12)
        addTripButton.bottomToSuperview(offset: -16, usingSafeArea: true)
    }

    @objc func addTripButtonTapped(_ sender: UIButton) {
        let addNewTripVC = AddNewTripViewController(isCopy: false, fsManager: fsManager)
        let navVC = UINavigationController(rootViewController: addNewTripVC)
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

    private func fetchUserTrips() {
        fsManager.tripListener()
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.showAlertToUser(error: error)
                }
            } receiveValue: { [unowned self] snapshot in
                if allTrips.isEmpty {
                    let firstResult = snapshot.documents.compactMap { try? $0.data(as: Trip.self) }
                    allTrips = firstResult
                    filterByDate()
                    return
                }

                snapshot.documentChanges.forEach { diff in
                    guard let modifiedTrip = try? diff.document.data(as: Trip.self) else { return }

                    switch diff.type {
                    case .added:
                        allTrips.append(modifiedTrip)
                    case .modified:
                        if let index = allTrips.firstIndex(where: { $0.id == modifiedTrip.id }) {
                            allTrips[index].image = modifiedTrip.image
                        }
                    case .removed:
                        if let index = allTrips.firstIndex(where: { $0.id == modifiedTrip.id }) {
                            allTrips.remove(at: index)
                        }
                    }
                }
                filterByDate()
            }
            .store(in: &cancelBags)
    }

    private func filterByDate() {
        filterTrips.removeAll(keepingCapacity: true)
        allTrips.forEach { trip in
            if trip.endDate > .now {
                filterTrips[.upcoming, default: []].append(trip)
            } else {
                filterTrips[.closed, default: []].append(trip)
            }
        }

        filterTrips[.upcoming]?.sort { $0.startDate > $1.startDate }
        filterTrips[.closed]?.sort { $0.startDate < $1.startDate }

        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
}

// MARK: - UITableView Delegate
extension MyTripViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        160
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let trip = filterTrips[currentSegment]?[indexPath.row] else { return }
        let editVC = EditTripViewController(trip: trip, fsManager: fsManager)
        navigationController?.pushViewController(editVC, animated: true)
    }

    // Delete action
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ -> UIMenu? in
            let deleteAction = UIAction(title: String(localized: "Delete"), image: UIImage(systemName: "trash")) { [unowned self] _ in
                guard
                    let trip = filterTrips[currentSegment]?[indexPath.row],
                    let tripID = trip.id,
                    let userId = fsManager.user
                else {
                    return
                }

                let alertVC = UIAlertController(
                    title: String(localized: "Are you sure want to delete?"),
                    message: String(localized: "This action can not be undo!"),
                    preferredStyle: .alert)
                let cancel = UIAlertAction(title: String(localized: "Cancel"), style: .cancel)
                let delete = UIAlertAction(
                    title: String(localized: "Delete"),
                    style: .destructive) { [unowned self] _ in
                        self.fsManager.updateMember(userId: userId, atTrip: tripID, isRemove: true)
                            .receive(on: DispatchQueue.main)
                            .sink { completion in
                                switch completion {
                                case .finished: break
                                case .failure(let error):
                                    self.showAlertToUser(error: error)
                                }
                            } receiveValue: { _ in }
                            .store(in: &cancelBags)
                }

                alertVC.addAction(cancel)
                alertVC.addAction(delete)
                present(alertVC, animated: true)
            }

            return UIMenu(children: [deleteAction])
        }
    }
}

// MARK: - UITableView DataSource
extension MyTripViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let trips = filterTrips[currentSegment] else { return 0 }
        placeHolder.isHidden = trips.isEmpty ? false : true
        return trips.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let tripCell = tableView.dequeueReusableCell(withIdentifier: TripCell.identifier, for: indexPath) as? TripCell else {
            fatalError("Failed to dequeue trip cell")
        }

        if let trip = filterTrips[currentSegment]?[indexPath.row] {
            tripCell.config(with: trip)
        }
        return tripCell
    }
}

// MARK: - SelectionView Delegate
extension MyTripViewController: SelectionViewDelegate {
    func didSelectedButton(_ selectionView: SelectionView, at index: Int) {
        // change collection view dataSource then update snapshot
        currentSegment = index == 0 ? .upcoming : .closed
        tableView.reloadData()
    }
}

// MARK: - SelectionView DataSource
extension MyTripViewController: SelectionViewDataSource {
    func numberOfButtons(_ selectionView: SelectionView) -> Int {
        return 2
    }

    func selectionView(_ selectionView: SelectionView, titleForButtonAt index: Int) -> String? {
        return Segment.allCases[index].title
    }

    func colorForSelectedButton(_ selectionView: SelectionView) -> UIColor? {
        return .systemTeal
    }

    func fontForButtonTitle(_ selectionView: SelectionView) -> UIFont? {
        return .systemFont(ofSize: 16, weight: .bold)
    }
}
