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

    private let viewModel: MyTripViewModelType
    private var currentSegment: Segment = .upcoming
    private let placeHolder: UILabel = {
        LabelFactory.build(text: "Add new trip to start!", font: .title, textColor: .secondaryLabel)
    }()
    private var cancelBags: Set<AnyCancellable> = []

    init(viewModel: MyTripViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = String(localized: "My trips")
        navigationItem.backButtonDisplayMode = .minimal
        setupUI()
        bind()
        viewModel.fetchUserTrips()
    }

    private func setupUI() {
        [selectionView, tableView, addTripButton, placeHolder].forEach { view.addSubview($0) }
        selectionView.edgesToSuperview(excluding: .bottom, usingSafeArea: true)

        tableView.topToBottom(of: selectionView)
        tableView.edgesToSuperview(excluding: .top, usingSafeArea: true)

        addTripButton.size(CGSize(width: 60, height: 60))
        addTripButton.trailingToSuperview(offset: 12)
        addTripButton.bottomToSuperview(offset: -16, usingSafeArea: true)

        placeHolder.isHidden = true
        placeHolder.centerInSuperview()
    }

    @objc func addTripButtonTapped(_ sender: UIButton) {
        let fsManager = FirestoreManager()
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

    func bind() {
        viewModel.outputPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .reloadData:
                    self?.tableView.reloadData()
                case .displayError(let error):
                    self?.showAlertToUser(error: error)
                }
            }
            .store(in: &cancelBags)
    }
}

// MARK: - UITableView Delegate
extension MyTripViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        160
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let trip = viewModel.filterTrips[currentSegment]?[indexPath.row] else { return }
        let storageManager = StorageManager()
        let fsManager = FirestoreManager()
        let editVC = EditTripViewController(
            viewModel: EditTripViewModel(
                trip: trip,
                isEditMode: true,
                fsManager: fsManager,
                storageManager: storageManager))
        navigationController?.pushViewController(editVC, animated: true)
    }

    // Delete action
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ -> UIMenu? in
            let deleteAction = UIAction(title: String(localized: "Delete"), image: UIImage(systemName: "trash")) { [weak self] _ in
                guard
                    let self = self,
                    let trip = viewModel.filterTrips[currentSegment]?[indexPath.row],
                    let tripID = trip.id
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
                    style: .destructive) { _ in
                        self.viewModel.updateMember(tripId: tripID)
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
        guard let trips = viewModel.filterTrips[currentSegment] else { return 0 }
        placeHolder.isHidden = trips.isEmpty ? false : true
        return trips.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let tripCell = tableView.dequeueReusableCell(withIdentifier: TripCell.identifier, for: indexPath) as? TripCell else {
            fatalError("Failed to dequeue trip cell")
        }

        if let trip = viewModel.filterTrips[currentSegment]?[indexPath.row] {
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
