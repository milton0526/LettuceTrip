//
//  ChatRoomViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/23.
//

import UIKit
import Combine
import TinyConstraints

class ChatRoomViewController: UIViewController {

    let viewModel: ChatRoomViewModelType

    init(viewModel: ChatRoomViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    enum Section {
        case main
    }

    // UI Elements
    lazy var userView = ChatRoomMemberView()

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.register(UserMessageCell.self, forCellWithReuseIdentifier: UserMessageCell.identifier)
        collectionView.register(FriendMessageCell.self, forCellWithReuseIdentifier: FriendMessageCell.identifier)
        return collectionView
    }()

    lazy var inputTextField: RoundedTextField = {
        let textField = RoundedTextField()
        textField.backgroundColor = .secondarySystemBackground
        textField.placeholder = "Start typing..."
        return textField
    }()

    lazy var sendButton: UIButton = {
        let button = UIButton()
        button.setBackgroundImage(.init(systemName: "paperplane.fill"), for: .normal)
        button.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        return button
    }()

    // Properties
    private var dataSource: UICollectionViewDiffableDataSource<Section, Message>!
    private var cancelBags: Set<AnyCancellable> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        customNavBarStyle()
        setupUI()
        configBackButton()
        configureDataSource()
        bind()
        viewModel.fetchData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.hideHairline()
    }

    private func customNavBarStyle() {
        title = String(localized: "Chat room")
        navigationItem.largeTitleDisplayMode = .never

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.tintColor
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
    }

    @objc func sendMessage(_ sender: UIButton) {
        guard
            let text = inputTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            !text.isEmpty
        else {
            return
        }
        viewModel.sendMessage(text)
    }

    private func configBackButton() {
        let backButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissView))
        backButton.tintColor = .systemTeal
        navigationItem.rightBarButtonItem = backButton
    }

    @objc func dismissView(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    private func setupUI() {
        [userView, collectionView, inputTextField, sendButton].forEach { view.addSubview($0) }

        userView.edgesToSuperview(excluding: .bottom, usingSafeArea: true)
        userView.height(100)

        collectionView.topToBottom(of: userView)
        collectionView.horizontalToSuperview()
        collectionView.bottomToTop(of: inputTextField, offset: -8)

        sendButton.centerY(to: inputTextField)
        sendButton.trailingToSuperview(offset: 16)
        sendButton.size(.init(width: 30, height: 30))

        inputTextField.leadingToSuperview(offset: 16)
        inputTextField.trailingToLeading(of: sendButton, offset: -10)
        inputTextField.bottomToSuperview(offset: -16, usingSafeArea: true)
        inputTextField.height(50)
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(44))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(44))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 4
        section.contentInsets = .init(top: 0, leading: 0, bottom: 8, trailing: 0)

        return UICollectionViewCompositionalLayout(section: section)
    }

    private func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, message in
            guard
                let self = self,
                let userMSGCell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: UserMessageCell.identifier,
                    for: indexPath) as? UserMessageCell,
                let friendMSGCell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: FriendMessageCell.identifier,
                    for: indexPath) as? FriendMessageCell
            else {
                fatalError("Failed to dequeue cityCell")
            }

            guard let currentUser = viewModel.currentUser else {
                fatalError("No user login.")
            }

            if message.userID == currentUser {
                userMSGCell.config(with: message)
                return userMSGCell
            } else {
                let friend = viewModel.members.first { $0.id == message.userID }
                friendMSGCell.config(with: message, from: friend)
                return friendMSGCell
            }
        }
    }

    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Message>()
        snapshot.appendSections([.main])
        snapshot.appendItems(viewModel.chatMessages)
        dataSource.apply(snapshot, animatingDifferences: false)

        if !viewModel.chatMessages.isEmpty {
            let indexPath = IndexPath(item: viewModel.chatMessages.count - 1, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
        }
    }

    private func bind() {
        viewModel.outputPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .updateMembers(let members):
                    userView.members = members
                case .updateChatRoom:
                    inputTextField.text = ""
                    updateSnapshot()
                case .displayError(let error):
                    showAlertToUser(error: error)
                }
            }
            .store(in: &cancelBags)
    }
}
