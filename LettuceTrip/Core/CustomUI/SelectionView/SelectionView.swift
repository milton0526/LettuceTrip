//
//  SelectionView.swift
//  DI_1_Delegate
//
//  Created by Milton Liu on 2023/5/24.
//

import UIKit

class SelectionView: UIView {

    weak var delegate: SelectionViewDelegate?
    weak var dataSource: SelectionViewDataSource? {
        didSet { reloadData() }
    }

    // Button
    private var numberOfButtons: Int = 2
    private var buttonTitles: [String] = ["Title1", "Title2"]
    private var buttons: [UIButton] = []
    private let buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    // Text
    private var textFont: UIFont = .systemFont(ofSize: 18)
    private var textColor: UIColor = .systemGray
    private var selectedColor: UIColor = .label

    // Indicator
    private let indicatorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    private var indicatorLeadingConstraint: NSLayoutConstraint!

    // init
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup views function
    private func setupButtons() {
        for index in 0..<numberOfButtons {
            let button = UIButton(type: .system)
            button.setTitle(buttonTitles[index], for: .normal)
            button.setTitleColor(textColor, for: .normal)
            button.titleLabel?.font = textFont
            button.addTarget(self, action: #selector(didClickButton), for: .touchUpInside)
            buttons.append(button)
        }
        buttons[0].setTitleColor(selectedColor, for: .normal)
    }

    @objc private func didClickButton(_ sender: UIButton) {
        guard let buttonIndex = buttons.firstIndex(of: sender) else { return }
        delegate?.didSelectedButton(self, at: buttonIndex)
        changeButtonColor(currentButton: sender)
        animateIndicator(currentButton: sender)
    }

    private func changeButtonColor(currentButton: UIButton) {
        buttons.forEach { button in
            if button == currentButton {
                button.setTitleColor(selectedColor, for: .normal)
            } else {
                button.setTitleColor(textColor, for: .normal)
            }
        }
    }

    private func animateIndicator(currentButton: UIButton) {
        indicatorLeadingConstraint.isActive = false
        indicatorLeadingConstraint = indicatorView.leadingAnchor.constraint(equalTo: currentButton.leadingAnchor)
        indicatorLeadingConstraint.isActive = true

        UIView.animate(withDuration: 0.3) {
            self.layoutIfNeeded()
        }
    }

    private func setupButtonStackView() {
        buttons.forEach { buttonStackView.addArrangedSubview($0) }

        addSubview(buttonStackView)
        NSLayoutConstraint.activate([
            buttonStackView.topAnchor.constraint(equalTo: self.topAnchor),
            buttonStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ])
    }

    private func setupIndicatorView() {
        let firstButton = buttons[0]
        indicatorView.backgroundColor = selectedColor
        addSubview(indicatorView)

        indicatorLeadingConstraint = indicatorView.leadingAnchor.constraint(equalTo: firstButton.leadingAnchor)

        NSLayoutConstraint.activate([
            indicatorView.topAnchor.constraint(equalTo: buttonStackView.bottomAnchor, constant: 5),
            indicatorView.widthAnchor.constraint(equalTo: firstButton.widthAnchor),
            indicatorView.heightAnchor.constraint(equalToConstant: 2),
            indicatorLeadingConstraint
        ])
    }

    private func configure() {
        setupButtons()
        setupButtonStackView()
        setupIndicatorView()

        // CustomSegmentedControl constrains to adapt to the height of their subviews
        topAnchor.constraint(equalTo: buttonStackView.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: indicatorView.bottomAnchor).isActive = true
    }

    private func cleanUpSubviews() {
        buttons.removeAll()
        buttonTitles.removeAll()
        buttonStackView.removeAllArrangedSubviews()
        subviews.forEach { $0.removeFromSuperview() }
    }

    // MARK: - DataSource reloading
    func reloadData() {
        guard let dataSource = dataSource else { return }
        cleanUpSubviews()

        numberOfButtons = dataSource.numberOfButtons(self)
        textFont = dataSource.fontForButtonTitle?(self) ?? .systemFont(ofSize: 18)
        selectedColor = dataSource.colorForSelectedButton?(self) ?? .label

        for index in 0..<numberOfButtons {
            guard let title = dataSource.selectionView(self, titleForButtonAt: index) else { break }
            buttonTitles.append(title)
        }

        configure()
    }
}
