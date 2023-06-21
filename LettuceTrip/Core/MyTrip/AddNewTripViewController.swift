//
//  AddNewTripViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/21.
//

import UIKit
import TinyConstraints

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
        return textField
    }()

    lazy var durationTextField: RoundedTextField = {
        let textField = RoundedTextField()
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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = String(localized: "Create trip")

        let saveButton = UIBarButtonItem(
            title: String(localized: "Save"),
            style: .plain,
            target: self,
            action: #selector(saveTrip))
        navigationItem.rightBarButtonItem = saveButton

        [tripNameLabel, tripNameTextField, destinationLabel, destinationTextField, startTimeLabel, datePicker, durationLabel, durationTextField].forEach {
            view.addSubview($0)
        }

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

        datePicker.centerY(to: startTimeLabel)
        datePicker.trailingToSuperview(offset: 16)
    }

    @objc func saveTrip(_ sender: UIBarButtonItem) {
        // Save to firebase

        dismiss(animated: true)
    }
}
