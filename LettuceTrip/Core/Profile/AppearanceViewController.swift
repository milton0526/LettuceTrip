//
//  AppearanceVC.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/6.
//

import UIKit

enum AppTheme: Int {
    static let key = "Theme"

    case light
    case dark
    case followSystem

    var mode: String {
        switch self {
        case .light:
            return "Light mode"
        case .dark:
            return "Dark mode"
        case .followSystem:
            return "Follow system"
        }
    }
}

class AppearanceViewController: BaseSettingViewController {

    private var themeModels = SettingModel.theme

    private var currentTheme: Int {
        if UserDefaults.standard.string(forKey: AppTheme.key) == AppTheme.followSystem.mode {
            return 2
        } else {
            return UITraitCollection.current.userInterfaceStyle == .light ? 0 : 1
        }
    }

    var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.edgesToSuperview(usingSafeArea: true)
    }

    override func cellRegistration(_ cell: UICollectionViewListCell, indexPath: IndexPath, item: SettingModel) {
        var config = cell.defaultContentConfiguration()
        config.text = item.title
        config.image = item.image?.withTintColor(.tintColor)
        config.imageProperties.maximumSize = .init(width: 35, height: 35)
        cell.contentConfiguration = config

        let options = UICellAccessory.CheckmarkOptions(isHidden: false, reservedLayoutWidth: .standard, tintColor: .tintColor)
        let accessory = UICellAccessory.checkmark(displayed: .always, options: options)

        if indexPath.item == currentTheme {
            cell.accessories = [accessory]
        } else {
            cell.accessories = []
        }
    }

    override func updateSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, SettingModel>()
        snapshot.appendSections([.main])
        snapshot.appendItems(themeModels)
        dataSource.applySnapshotUsingReloadData(snapshot)
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let selected = AppTheme(rawValue: indexPath.item) else { return }

        if indexPath.item != currentTheme {
            if selected.mode == AppTheme.followSystem.mode {
                keyWindow?.overrideUserInterfaceStyle = .unspecified
                UserDefaults.standard.removeObject(forKey: AppTheme.key)
            } else {
                keyWindow?.overrideUserInterfaceStyle = selected.mode == AppTheme.light.mode ? .light : .dark
            }

            UserDefaults.standard.setValue(selected.mode, forKey: AppTheme.key)
            updateSnapshot()
        }
    }
}
