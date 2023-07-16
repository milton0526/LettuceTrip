//
//  WishListViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/25.
//

import UIKit
import Combine
import TinyConstraints

class WishListViewController: UIViewController, UICollectionViewDelegate {

    enum Section {
        case main
    }

    let viewModel: WishListViewModelType

    init(viewModel: WishListViewModelType) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var dataSource: UICollectionViewDiffableDataSource<Section, Place>!
    private var cancelBags: Set<AnyCancellable> = []
    private let input: PassthroughSubject<WishListVMInput, Never> = .init()

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.delegate = self
        return collectionView
    }()

    private let placeHolder: UILabel = {
        LabelFactory.build(text: "There's nothing here!", font: .title, textColor: .secondaryLabel)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Wish List")
        setupUI()
        configDataSource()
        bind()
        input.send(.fetchPlace)
    }

    private func bind() {
        let output = viewModel.transform(input: input.eraseToAnyPublisher())

        output
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .success:
                    placeHolder.isHidden = viewModel.places.isEmpty ? false : true
                    updateSnapshot()
                case .anyError(let error):
                    showAlertToUser(error: error)
                }
            }
            .store(in: &cancelBags)
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        view.addSubview(placeHolder)
        placeHolder.isHidden = true
        placeHolder.centerInSuperview()
        collectionView.edgesToSuperview(usingSafeArea: true)
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        var config = UICollectionLayoutListConfiguration(appearance: .plain)
        config.trailingSwipeActionsConfigurationProvider = { indexPath in
            let deleteAction = UIContextualAction(style: .destructive, title: String(localized: "Delete")) { [weak self] _, _, completion in
                guard let self = self else { return }
                if let item = dataSource.itemIdentifier(for: indexPath)?.id {
                    input.send(.deletePlace(item: item))
                    completion(true)
                }
            }
            return .init(actions: [deleteAction])
        }

        return UICollectionViewCompositionalLayout.list(using: config)
    }

    private func cellRegistration(_ cell: UICollectionViewListCell, indexPath: IndexPath, item: Place) {
        var config = cell.defaultContentConfiguration()
        config.text = item.name
        config.image = UIImage(data: item.iconImage)?.withTintColor(.tintColor)
        config.imageProperties.maximumSize = .init(width: 35, height: 35)
        cell.contentConfiguration = config
    }

    private func configDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Place>(handler: cellRegistration)

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            return cell
        }
    }

    private func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Place>()
        snapshot.appendSections([.main])
        snapshot.appendItems(viewModel.places)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    // MARK: CollectionView Delegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        let place = viewModel.places[indexPath.item]
        let fsManager = FirestoreManager()
        let arrangeVC = ArrangePlaceViewController(
            viewModel: ArrangePlaceViewModel(trip: viewModel.trip, place: place, fsManager: fsManager))
        navigationController?.pushViewController(arrangeVC, animated: true)
    }
}
