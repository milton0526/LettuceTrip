//
//  ChatRoomViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/23.
//

import UIKit
import Combine
import FirebaseFirestore
import TinyConstraints

class ChatRoomViewController: UIViewController {

    var trip: Trip?

    enum Section {
        case main
    }

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

    private var dataSource: UICollectionViewDiffableDataSource<Section, Message>!

    private var chatMessages: [Message] = []
    private var messageListener: ListenerRegistration?

    private var cancelBags = Set<AnyCancellable>()
    private let manager = FirestoreManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        customNavBarStyle()
        setupUI()
        configBackButton()
        configureDataSource()
        fetchMessages()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        messageListener?.remove()
        messageListener = nil
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.hideHairline()
    }

    private func customNavBarStyle() {
        title = String(localized: "Group Chat")
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
        // send message to firebase and listen to update view
        guard
            let tripID = trip?.id,
            let text = inputTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
            !text.isEmpty
        else {
            return
        }

        FireStoreService.shared.sendMessage(with: text, in: tripID) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.inputTextField.resignFirstResponder()
                    self?.inputTextField.text = ""
                case .failure(let error):
                    self?.showAlertToUser(error: error)
                }
            }
        }
    }

    private func configBackButton() {
        let backButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(dismissView))
        backButton.tintColor = .systemTeal
        navigationItem.leftBarButtonItem = backButton
    }

    @objc func dismissView(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    private func setupUI() {
        [collectionView, inputTextField, sendButton].forEach { view.addSubview($0) }

        collectionView.topToSuperview(usingSafeArea: true)
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
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, message in
            guard
                let userMSGCell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: UserMessageCell.identifier,
                    for: indexPath) as? UserMessageCell,
                let friendMSGCell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: FriendMessageCell.identifier,
                    for: indexPath) as? FriendMessageCell
            else {
                fatalError("Failed to dequeue cityCell")
            }

            guard let currentUser = FireStoreService.shared.currentUser else {
                fatalError("No user login.")
            }

            if message.userID == currentUser {
                userMSGCell.config(with: message)
                return userMSGCell
            } else {
                friendMSGCell.config(with: message)
                return friendMSGCell
            }
        }
    }

    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Message>()
        snapshot.appendSections([.main])
        snapshot.appendItems(chatMessages)
        dataSource.apply(snapshot, animatingDifferences: false)

        if !chatMessages.isEmpty {
            let indexPath = IndexPath(item: chatMessages.count - 1, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .bottom, animated: true)
        }
    }

    private func fetchMessages() {
        guard let tripId = trip?.id else { return }
//
//        let (listener, result) = manager.chatRoomListener(tripId)
//        messageListener = listener
//        result
//            .sink { completion in
//                self.updateSnapshot()
//            } receiveValue: { messages in
//                self.chatMessages = messages
//            }
//            .store(in: &cancelBags)
    }

//    private func fetchMessages() {
//        guard let tripID = trip?.id else { return }
//
//        messageListener = FireStoreService.shared.addListenerToChatRoom(by: tripID) { [weak self] result in
//            guard let self = self else { return }
//
//            switch result {
//            case .success(let messages):
//                self.chatMessages = messages
//
//                DispatchQueue.main.async {
//                    self.updateSnapshot()
//                }
//
//            case .failure(let error):
//                self.showAlertToUser(error: error)
//            }
//        }
//    }
}
