//
//  AddNewTripViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/21.
//

import UIKit
import MapKit
import Combine
import TinyConstraints
import FirebaseFirestore

class AddNewTripViewController: UIViewController {

    lazy var tripNameLabel: UILabel = {
        LabelFactory.build(text: "Trip name", font: .subtitle)
    }()

    lazy var destinationLabel: UILabel = {
        LabelFactory.build(text: "Destination", font: .subtitle)
    }()

    lazy var startTimeLabel: UILabel = {
        LabelFactory.build(text: "Start time", font: .subtitle)
    }()

    lazy var durationLabel: UILabel = {
        LabelFactory.build(text: "Duration", font: .subtitle)
    }()

    lazy var tripNameTextField: RoundedTextField = {
        let textField = RoundedTextField()
        textField.backgroundColor = .secondarySystemBackground
        return textField
    }()

    lazy var destinationTextField: RoundedTextField = {
        let textField = RoundedTextField()
        textField.backgroundColor = .secondarySystemBackground
        textField.delegate = self
        return textField
    }()

    lazy var durationTextField: RoundedTextField = {
        let textField = RoundedTextField()
        textField.keyboardType = .numberPad
        textField.backgroundColor = .secondarySystemBackground
        return textField
    }()

    lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.minimumDate = .now
        datePicker.maximumDate = .distantFuture
        datePicker.locale = .current
        datePicker.preferredDatePickerStyle = .compact
        return datePicker
    }()

    // These property for copy trip use
    var selectedCity: MKMapItem?
    var places: [Place] = []
    var copyFromTrip: Trip?
    private let isCopy: Bool
    let fsManager: FirestoreManager
    private var cancelBags: Set<AnyCancellable> = []

    init(isCopy: Bool, fsManager: FirestoreManager) {
        self.isCopy = isCopy
        self.fsManager = fsManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = isCopy ? String(localized: "Copy this trip") : String(localized: "Create new trip")

        let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTrip))
        navigationItem.rightBarButtonItem = saveButton

        let subviews = [
            tripNameLabel, tripNameTextField, destinationLabel, destinationTextField, startTimeLabel, datePicker, durationLabel, durationTextField
        ]

        subviews.forEach { view.addSubview($0) }

        tripNameLabel.edgesToSuperview(excluding: .bottom, insets: .uniform(16), usingSafeArea: true)
        tripNameLabel.height(22)

        tripNameTextField.topToBottom(of: tripNameLabel, offset: 8)
        tripNameTextField.height(50)
        tripNameTextField.horizontalToSuperview(insets: .horizontal(16))

        destinationLabel.topToBottom(of: tripNameTextField, offset: 16)
        destinationLabel.height(22)
        destinationLabel.horizontalToSuperview(insets: .horizontal(16))

        destinationTextField.topToBottom(of: destinationLabel, offset: 8)
        destinationTextField.height(50)
        destinationTextField.horizontalToSuperview(insets: .horizontal(16))
        destinationTextField.isEnabled = !isCopy

        durationLabel.topToBottom(of: destinationTextField, offset: 16)
        durationLabel.height(22)
        durationLabel.horizontalToSuperview(insets: .horizontal(16))

        durationTextField.topToBottom(of: durationLabel, offset: 8)
        durationTextField.height(50)
        durationTextField.horizontalToSuperview(insets: .horizontal(16))
        durationTextField.isEnabled = !isCopy

        startTimeLabel.topToBottom(of: durationTextField, offset: 24)
        startTimeLabel.height(22)
        startTimeLabel.leadingToSuperview(offset: 16)
        startTimeLabel.bottomToSuperview(offset: -16, relation: .equalOrGreater, priority: .defaultLow, usingSafeArea: true)

        datePicker.centerY(to: startTimeLabel)
        datePicker.trailingToSuperview(offset: 16)
        datePicker.leading(to: startTimeLabel, offset: 16, relation: .equalOrGreater)
    }

    @objc func saveTrip(_ sender: UIBarButtonItem) {
        guard
            let tripName = tripNameTextField.text,
            let destination = destinationTextField.text,
            let durationField = durationTextField.text,
            !tripName.isEmpty,
            !destination.isEmpty,
            !durationField.isEmpty
        else {
            return
        }

        // Duration need to subtract by 1, because the first is not calculate
        let startDate = datePicker.date.resetHourAndMinute()
        guard
            let duration = Int(durationField),
            duration > 0,
            let startDate = startDate,
            var endDate = Calendar.current.date(byAdding: .day, value: duration, to: startDate),
            let selectedCity = selectedCity,
            let user = fsManager.user
        else {
            return
        }

        endDate.addTimeInterval(-60)
        let latitude = selectedCity.placemark.coordinate.latitude
        let longitude = selectedCity.placemark.coordinate.longitude
        let city = GeoPoint(latitude: latitude, longitude: longitude)

        let trip = Trip(
            tripName: tripName,
            startDate: startDate,
            endDate: endDate,
            duration: duration - 1,
            destination: selectedCity.name ?? "",
            geoLocation: city,
            members: [user],
            isPublic: false)

        // upload to firebase
        fsManager.createTrip(trip)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    break
                case .failure:
                    JGHudIndicator.shared.showHud(type: .failure)
                }
            } receiveValue: { [weak self] newTripID in
                guard let self = self else { return }
                if isCopy {
                    guard
                        let copyDate = copyFromTrip?.startDate,
                        let gap = Calendar.current.dateComponents([.day], from: copyDate, to: startDate).day
                    else {
                        return
                    }
                    copyPlaces(newTripID, gap: gap)
                } else {
                    JGHudIndicator.shared.showHud(type: .success)
                    dismiss(animated: true)
                }
            }
            .store(in: &cancelBags)
    }

    private func copyPlaces(_ id: String, gap: Int) {
        let calendar = Calendar.current
        var results: [Place] = []

        for var place in places {
            // swiftlint: disable force_unwrapping
            let newDate = calendar.date(byAdding: .day, value: gap, to: place.arrangedTime!)
            // swiftlint: enable force_unwrapping
            place.arrangedTime = newDate
            place.lastEditor = nil
            results.append(place)
        }

        fsManager.copyPlaces(at: id, places: results)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    JGHudIndicator.shared.showHud(type: .success)
                    self?.dismiss(animated: true)
                case .failure:
                    JGHudIndicator.shared.showHud(type: .failure)
                }
            } receiveValue: { _ in }
            .store(in: &cancelBags)
    }
}

// MARK: - UITextField Delegate
extension AddNewTripViewController: UITextFieldDelegate {

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == destinationTextField {
            let searchCityVC = SearchViewController()
            searchCityVC.userSelectedCity = { [weak self] city in
                guard let self = self else { return }
                selectedCity = city
                destinationTextField.text = city.name
                textField.resignFirstResponder()
            }
            navigationController?.pushViewController(searchCityVC, animated: true)
            return false
        }
        return true
    }
}
