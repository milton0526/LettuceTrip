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

    private var settings = SettingModel.profileSettings

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.delegate = self
        return collectionView
    }()

    lazy var profileHeaderView = ProfileHeaderView()
    private let authManager = AuthManager()

    private var dataSource: UICollectionViewDiffableDataSource<Section, SettingModel>!

    private var cancelBags: Set<AnyCancellable> = []
    private let fsManager = FirestoreManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(profileHeaderView)
        view.addSubview(collectionView)
        profileHeaderView.edgesToSuperview(excluding: .bottom, usingSafeArea: true)
        profileHeaderView.height(100)

        collectionView.topToBottom(of: profileHeaderView)
        collectionView.edgesToSuperview(excluding: .top, usingSafeArea: true)

        bind()
        customNavBarStyle()
        configDataSource()
        updateSnapshot()
        fetchData()

        authManager.viewController = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.hideHairline()
    }

    private func bind() {
        profileHeaderView.imageHandler = { [unowned self] in
            var config = PHPickerConfiguration()
            config.filter = .images
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            self.present(picker, animated: true)
        }
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
        snapshot.appendItems(settings)
        dataSource.apply(snapshot)
    }

    private func fetchData() {
        guard let userId = fsManager.user else { return }

        FireStoreService.shared.getUserData(userId: userId) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let user):
                DispatchQueue.main.async {
                    self.profileHeaderView.nameLabel.text = user.name
                    self.profileHeaderView.emailLabel.text = user.email
                    if let image = user.image {
                        self.profileHeaderView.imageView.image = UIImage(data: image)
                    }
                }
            case .failure(let error):
                self.showAlertToUser(error: error)
            }
        }
    }

    private func confirmSignOut() {
        let alert = UIAlertController(title: String(localized: "Are you sure want to sign out?"), message: nil, preferredStyle: .alert)
        let sure = UIAlertAction(title: String(localized: "Sure"), style: .default) { [weak self] _ in
            self?.authManager.signOut { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.showAlertToUser(error: error)
                    } else {
                        let signInVC = SignInViewController()
                        signInVC.modalPresentationStyle = .fullScreen
                        self?.present(signInVC, animated: true)
                    }
                }
            }
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
                self?.authManager.deleteAccount()
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
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                guard
                    let self = self,
                    let image = image as? UIImage,
                    let imageData = image.jpegData(compressionQuality: 0.1)
                else {
                    return
                }

                DispatchQueue.main.async {
                    self.profileHeaderView.imageView.image = image
                }

                self.fsManager.updateUser(image: imageData)
                    .receive(on: DispatchQueue.main)
                    .sink { completion in
                        switch completion {
                        case .finished: break
                        case .failure(let error):
                            self.showAlertToUser(error: error)
                        }
                    } receiveValue: { _ in }
                    .store(in: &self.cancelBags)
            }
        }
    }
}
