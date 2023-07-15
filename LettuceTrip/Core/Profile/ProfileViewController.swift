//
//  ProfileViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit
import TinyConstraints
import PhotosUI
import Combine

class ProfileViewController: UIViewController, UICollectionViewDelegate {

    enum Section {
        case main
    }

    enum Item: Int {
        case appearance
        case deleteAccount
        case signOut
    }

    private let viewModel: ProfileViewModelType

    init(viewModel: ProfileViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.delegate = self
        return collectionView
    }()

    private lazy var profileHeaderView = ProfileHeaderView()
    private var dataSource: UICollectionViewDiffableDataSource<Section, SettingModel>!
    private var cancelBags: Set<AnyCancellable> = []
    private let input: PassthroughSubject<ProfileVMInput, Never> = .init()

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.authManager.delegate = self
        setupUI()
        configDataSource()
        updateSnapshot()
        bind()
        input.send(.fetchUserData)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.hideHairline()
    }

    private func setupUI() {
        view.addSubview(profileHeaderView)
        view.addSubview(collectionView)
        profileHeaderView.edgesToSuperview(excluding: .bottom, usingSafeArea: true)
        profileHeaderView.height(100)

        collectionView.topToBottom(of: profileHeaderView)
        collectionView.edgesToSuperview(excluding: .top, usingSafeArea: true)

        customNavBarStyle()
    }

    private func bind() {
        profileHeaderView.imageHandler = { [weak self] in
            var config = PHPickerConfiguration()
            config.filter = .images
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            self?.present(picker, animated: true)
        }

        let output = viewModel.transform(input: input.eraseToAnyPublisher())

        output
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self = self else { return }

                switch event {
                case .signOut:
                    showSignInVC()
                case .fetchUser(let user):
                    profileHeaderView.config(with: user)
                    JGHudIndicator.shared.dismissHUD()
                case .operationFailed(let error):
                    showAlertToUser(error: error)
                }
            }
            .store(in: &cancelBags)
    }

    private func customNavBarStyle() {
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = String(localized: "Settings")

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.tintColor
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        let config = UICollectionLayoutListConfiguration(appearance: .plain)
        return UICollectionViewCompositionalLayout.list(using: config)
    }

    private func cellRegistration(_ cell: UICollectionViewListCell, indexPath: IndexPath, item: SettingModel) {
        var config = cell.defaultContentConfiguration()
        config.text = item.title
        config.image = item.image?.withTintColor(.tintColor)
        config.imageProperties.maximumSize = .init(width: 35, height: 35)
        cell.contentConfiguration = config
    }

    private func configDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SettingModel>(handler: cellRegistration)

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            return cell
        }
    }

    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, SettingModel>()
        snapshot.appendSections([.main])
        snapshot.appendItems(SettingModel.profileSettings)
        dataSource.apply(snapshot)
    }

    private func showSignInVC() {
        let signInVC = SignInViewController(authManager: viewModel.authManager)
        signInVC.modalPresentationStyle = .fullScreen
        present(signInVC, animated: true)
    }

    private func confirmSignOut() {
        let alert = UIAlertController(title: String(localized: "Are you sure want to sign out?"), message: nil, preferredStyle: .alert)
        let sure = UIAlertAction(title: String(localized: "Sure"), style: .default) { [weak self] _ in
            self?.input.send(.signOut)
        }
        let cancel = UIAlertAction(title: String(localized: "Cancel"), style: .cancel)
        alert.addAction(sure)
        alert.addAction(cancel)
        present(alert, animated: true)
    }

    // MARK: CollectionView Delegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        guard let item = Item(rawValue: indexPath.item) else { return }

        switch item {
        case .appearance:
            let appearanceVC = AppearanceVC()
            navigationController?.pushViewController(appearanceVC, animated: true)
        case .deleteAccount:
            let alert = UIAlertController(
                title: String(localized: "Are you sure want to delete account?"),
                message: String(localized: "All associate data will be delete too."),
                preferredStyle: .alert)
            let cancel = UIAlertAction(title: String(localized: "Cancel"), style: .cancel)
            let confirm = UIAlertAction(title: String(localized: "Confirm"), style: .destructive) { [weak self] _ in
                self?.input.send(.deleteAccount)
            }

            alert.addAction(cancel)
            alert.addAction(confirm)

            present(alert, animated: true)
        case .signOut:
            confirmSignOut()
        }
    }
}

// MARK: - PHPickerController Delegate
extension ProfileViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        let itemProviders = results.map(\.itemProvider)
        if let itemProvider = itemProviders.first, itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                guard
                    let self = self,
                    let image = image as? UIImage,
                    let imageData = image.jpegData(compressionQuality: 0.3)
                else {
                    return
                }

                DispatchQueue.main.async {
                    JGHudIndicator.shared.showHud(type: .loading(text: "Updating"))
                }

                input.send(.updateImage(imageData))
            }
        }
    }
}

// MARK: AuthManagerDelegate
extension ProfileViewController: AuthManagerDelegate {
    func presentAnchor(_ manager: AuthManager) -> UIWindow {
        // swiftlint: disable force_unwrapping
        return view.window!
        // swiftlint: enable force_unwrapping
    }

    func authorizationSuccess(_ manager: AuthManager) {
        showSignInVC()
    }

    func authorizationFailed(_ manager: AuthManager, error: Error) {
        showAuthErrorAlert()
    }
}
