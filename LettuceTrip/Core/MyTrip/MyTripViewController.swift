//
//  MyTripViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit
import TinyConstraints

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

    private var upcomingTrips: [Trip] = []
    private var closedTrips: [Trip] = []
    private var currentSegment: Segment = .upcoming

    override func viewDidLoad() {
        super.viewDidLoad()
        customNavBar()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchUserTrips()
    }

    private func customNavBar() {
        let welcomeView = UILabel()
        welcomeView.text = String(localized: "My Trip")
        welcomeView.font = .systemFont(ofSize: 22, weight: .bold)
        welcomeView.textColor = .label

        let userImageView = UIImageView(frame: CGRect(origin: .zero, size: CGSize(width: 30, height: 30)))
        userImageView.image = UIImage(systemName: "ellipsis.circle")
        userImageView.contentMode = .scaleAspectFit
        userImageView.clipsToBounds = true
        userImageView.layer.cornerRadius = 20
        userImageView.layer.masksToBounds = true

        let leftBarItem = UIBarButtonItem(customView: welcomeView)
        let rightBarItem = UIBarButtonItem(customView: userImageView)
        navigationItem.leftBarButtonItem = leftBarItem
        navigationItem.rightBarButtonItem = rightBarItem
    }

    private func setupUI() {
        [selectionView, tableView, addTripButton].forEach { view.addSubview($0) }
        selectionView.edgesToSuperview(excluding: .bottom, usingSafeArea: true)

        tableView.topToBottom(of: selectionView)
        tableView.edgesToSuperview(excluding: .top)

        addTripButton.size(CGSize(width: 60, height: 60))
        addTripButton.trailingToSuperview(offset: 12)
        addTripButton.bottomToSuperview(offset: -16, usingSafeArea: true)
    }

    @objc func addTripButtonTapped(_ sender: UIButton) {
        let addNewTripVC = AddNewTripViewController()
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
        upcomingTrips.removeAll(keepingCapacity: true)
        closedTrips.removeAll(keepingCapacity: true)

        FireStoreManager.shared.fetchAllUserTrips { [weak self] result in
            switch result {
            case .success(let trips):
                self?.filterByDate(trips: trips)
            case .failure(let error):
                self?.showAlertToUser(error: error)
            }
        }
    }

    private func filterByDate(trips: [Trip]) {
        trips.forEach { trip in
            if trip.startDate < .distantPast {
                closedTrips.append(trip)
            } else {
                upcomingTrips.append(trip)
            }
        }

        closedTrips.sort { $0.startDate > $1.startDate }
        upcomingTrips.sort { $0.startDate > $1.startDate }

        DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
        }
    }
}

// MARK: - UITableView Delegate
extension MyTripViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        136
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Clicked")
    }
}

// MARK: - UITableView DataSource
extension MyTripViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        currentSegment == .upcoming
        ? upcomingTrips.count
        : closedTrips.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let tripCell = tableView.dequeueReusableCell(withIdentifier: TripCell.identifier, for: indexPath) as? TripCell else {
            fatalError("Failed to dequeue trip cell")
        }

        let trip = currentSegment == .upcoming
        ? upcomingTrips[indexPath.row]
        : closedTrips[indexPath.row]

        tripCell.config(with: trip)
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
