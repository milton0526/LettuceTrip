//
//  BaseListLayoutViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/6.
//

import UIKit

class BaseSettingViewController: UIViewController, UICollectionViewDelegate {

    enum Section {
        case main
    }

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.delegate = self
        return collectionView
    }()

    var dataSource: UICollectionViewDiffableDataSource<Section, SettingModel>!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        configDataSource()
        updateSnapshot()
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        let config = UICollectionLayoutListConfiguration(appearance: .plain)
        return UICollectionViewCompositionalLayout.list(using: config)
    }

    private func configDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, SettingModel>(handler: cellRegistration)

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            return cell
        }
    }

    // Override methods
    func cellRegistration(_ cell: UICollectionViewListCell, indexPath: IndexPath, item: SettingModel) { }

    func updateSnapshot() { }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) { }
}
