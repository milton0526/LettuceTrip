//
//  ArrangePlaceViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/25.
//

import UIKit
import MapKit
import TinyConstraints
import Combine

class ArrangePlaceViewController: UIViewController {

    private let viewModel: ArrangePlaceViewModelType
    private var isEditMode = true
    private var cancelBags: Set<AnyCancellable> = []

    init(viewModel: ArrangePlaceViewModelType, isEditMode: Bool = true) {
        self.viewModel = viewModel
        self.isEditMode = isEditMode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.separatorStyle = .none
        tableView.register(LocationMapCell.self, forCellReuseIdentifier: LocationMapCell.identifier)
        tableView.register(
            UINib(nibName: "\(ArrangePlaceDetailCell.self)", bundle: nil),
            forCellReuseIdentifier: ArrangePlaceDetailCell.identifier)
        return tableView
    }()

    lazy var navigateButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = String(localized: "Navigate")
        config.attributedTitle?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .tintColor
        config.cornerStyle = .capsule
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(openAppleMap), for: .touchUpInside)
        return button
    }()

    lazy var saveButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = String(localized: "Save")
        config.attributedTitle?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .tintColor
        config.cornerStyle = .capsule
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(savePlace), for: .touchUpInside)
        return button
    }()

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 16
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        return stackView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = viewModel.place.name

        let detailButton = UIBarButtonItem(
            image: UIImage(systemName: "info.circle"),
            style: .plain,
            target: self,
            action: #selector(showDetail))
        navigationItem.rightBarButtonItem = detailButton
        setupUI()
        bind()
    }

    @objc func savePlace(_ sender: UIButton) {
        let indexPath = IndexPath(row: 1, section: 0)

        guard let cell = tableView.cellForRow(at: indexPath) as? ArrangePlaceDetailCell else { return }
        let arrangement = cell.passData()
        viewModel.savePlace(arrangement: arrangement)
    }

    private func setupUI() {
        if !isEditMode {
            stackView.addArrangedSubview(navigateButton)
        }

        stackView.addArrangedSubview(saveButton)

        view.addSubview(tableView)
        view.addSubview(stackView)

        stackView.horizontalToSuperview(insets: .horizontal(16))
        stackView.bottomToSuperview(offset: -8, usingSafeArea: true)
        stackView.height(44)

        tableView.edgesToSuperview(excluding: .bottom, usingSafeArea: true)
        tableView.bottomToTop(of: stackView, offset: -8)
    }

    @objc func openAppleMap(_ sender: UIButton) {
        let placeMark = MKPlacemark(coordinate: viewModel.place.coordinate)
        let mapItem = MKMapItem(placemark: placeMark)
        mapItem.name = viewModel.place.name
        mapItem.openInMaps()
    }

    @objc func showDetail(_ sender: UIBarButtonItem) {
        let apiService = GPlaceAPIManager()
        let fsManager = FirestoreManager()
        let detailVC = PlaceDetailViewController(
            isNewPlace: true,
            viewModel: PlaceDetailViewModel(place: viewModel.place, fsManager: fsManager, apiService: apiService))
        detailVC.addToTripButton.isEnabled = false
        detailVC.addToTripButton.alpha = 0.8
        navigationController?.pushViewController(detailVC, animated: true)
    }

    private func bind() {
        viewModel.popViewPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    self?.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    self?.showAlertToUser(error: error)
                }
            } receiveValue: { _ in }
            .store(in: &cancelBags)
    }
}

// MARK: TableView DataSource
extension ArrangePlaceViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        switch indexPath.row {
        case 0:
            guard let mapCell = tableView.dequeueReusableCell(withIdentifier: LocationMapCell.identifier, for: indexPath) as? LocationMapCell else {
                fatalError("Failed to dequeue map cell.")
            }

            mapCell.config(with: viewModel.place)
            return mapCell

        default:
            guard let detailCell = tableView.dequeueReusableCell(
                withIdentifier: ArrangePlaceDetailCell.identifier,
                for: indexPath) as? ArrangePlaceDetailCell
            else {
                fatalError("Failed to dequeue map cell.")
            }

            if isEditMode {
                detailCell.config(with: viewModel.trip, place: viewModel.place)
            } else {
                detailCell.config(with: viewModel.trip, place: viewModel.place, isArrange: true)
            }
            return detailCell
        }
    }
}

// MARK: - TableView Delegate
extension ArrangePlaceViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        180
    }
}
