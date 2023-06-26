//
//  ArrangePlaceViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/25.
//

import UIKit
import TinyConstraints

class ArrangePlaceViewController: UIViewController {

    var trip: Trip?
    var place: Place?
    var editMode = true

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

    lazy var moreDetailButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = String(localized: "More details")
        config.attributedTitle?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        config.baseForegroundColor = .white
        config.baseBackgroundColor = .tintColor
        config.cornerStyle = .capsule
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(showDetail), for: .touchUpInside)
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
        title = place?.name

        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(savePlace))
        navigationItem.rightBarButtonItem = saveButton
        setupUI()
    }

    @objc func savePlace(_ sender: UIBarButtonItem) {
        guard
            let trip = trip,
            var place = place
        else {
            return
        }

        let indexPath = IndexPath(row: 1, section: 0)

        guard let cell = tableView.cellForRow(at: indexPath) as? ArrangePlaceDetailCell else { return }
        let arrangement = cell.passData()
        place.isArrange = true
        place.arrangedTime = arrangement.arrangedTime
        place.duration = arrangement.duration
        place.memo = arrangement.memo

        // Update fireStore document
        FireStoreService.shared.updatePlace(place, to: trip, update: true) { [weak self] state in
            guard let self = self else { return }
            if state {
                self.navigationController?.popViewController(animated: true)
            } else {
                // Show error message to user.
            }
        }

    }

    private func setupUI() {
        if !editMode {
            stackView.addArrangedSubview(navigateButton)
        }

        stackView.addArrangedSubview(moreDetailButton)

        view.addSubview(tableView)
        view.addSubview(stackView)

        stackView.horizontalToSuperview(insets: .horizontal(16))
        stackView.bottomToSuperview(offset: -8, usingSafeArea: true)
        stackView.height(44)

        tableView.edgesToSuperview(excluding: .bottom, usingSafeArea: true)
        tableView.bottomToTop(of: stackView, offset: -8)
    }

    @objc func openAppleMap(_ sender: UIButton) {
    }

    @objc func showDetail(_ sender: UIButton) {
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

            if let place = place {
                mapCell.config(with: place)
            }

            return mapCell

        default:
            guard let detailCell = tableView.dequeueReusableCell(
                withIdentifier: ArrangePlaceDetailCell.identifier,
                for: indexPath) as? ArrangePlaceDetailCell
            else {
                fatalError("Failed to dequeue map cell.")
            }

            if let trip = trip {
                detailCell.config(with: trip)
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
