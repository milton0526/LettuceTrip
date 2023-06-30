//
//  AddNewTripViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/21.
//

import UIKit
import MapKit
import TinyConstraints
import FirebaseFirestore

class AddNewTripViewController: UIViewController {

    lazy var tripNameLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "Trip name")
        label.subtitleStyle()
        return label
    }()

    lazy var destinationLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "Destination")
        label.subtitleStyle()
        return label
    }()

    lazy var startTimeLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "Start time")
        label.subtitleStyle()
        return label
    }()

    lazy var durationLabel: UILabel = {
        let label = UILabel()
        label.text = String(localized: "Duration")
        label.subtitleStyle()
        return label
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

    private var selectedCity: MKMapItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = String(localized: "Create trip")

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

        durationLabel.topToBottom(of: destinationTextField, offset: 16)
        durationLabel.height(22)
        durationLabel.horizontalToSuperview(insets: .horizontal(16))

        durationTextField.topToBottom(of: durationLabel, offset: 8)
        durationTextField.height(50)
        durationTextField.horizontalToSuperview(insets: .horizontal(16))

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
            let endDate = Calendar.current.date(byAdding: .day, value: duration - 1, to: startDate),
            let selectedCity = selectedCity,
            let user = FireStoreService.shared.currentUser,
            let imageData = UIImage(named: "placeholder")?.jpegData(compressionQuality: 0.1)
        else {
            return
        }

        let latitude = selectedCity.placemark.coordinate.latitude
        let longitude = selectedCity.placemark.coordinate.longitude
        let city = GeoPoint(latitude: latitude, longitude: longitude)

        let trip = Trip(
            tripName: tripName,
            image: imageData,
            startDate: startDate,
            endDate: endDate,
            duration: duration - 1,
            destination: city,
            members: [user],
            isPublic: false)

        // upload to firebase
        FireStoreService.shared.addDocument(at: .trips, data: trip) { [weak self] result in

            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.dismiss(animated: true)
                case .failure(let error):
                    self?.showAlertToUser(error: error)
                }
            }
        }
    }
}

// MARK: - UITextField Delegate
extension AddNewTripViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == destinationTextField {
            let searchCityVC = SearchCityViewController()
            searchCityVC.userSelectedCity = { [weak self] city in
                self?.selectedCity = city
                self?.destinationTextField.text = city.name
                textField.resignFirstResponder()
            }
            navigationController?.pushViewController(searchCityVC, animated: true)
            return false
        }
        return true
    }
}
