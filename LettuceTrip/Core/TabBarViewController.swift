//
//  TabBarViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/13.
//

import UIKit

class TabBarViewController: UITabBarController {

    private let fsManager: FirestoreManager
    private let authManager: AuthManager

    private let icons: [Icon] = [.home, .discover, .trip, .profile]

    init(fsManager: FirestoreManager, authManager: AuthManager) {
        self.fsManager = fsManager
        self.authManager = authManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupViewControllers()
    }


    private func setupViewControllers() {
        let homeVC = HomeViewController(viewModel: HomeViewModel(fsManager: fsManager))
        let discoverVC = DiscoverViewController(fsManager: fsManager)
        let tripVC = MyTripViewController()
        let profileVC = ProfileViewController()

        let viewControllers = [homeVC, discoverVC, tripVC, profileVC]
        var navigationVCs: [UINavigationController] = []

        for (index, viewController) in viewControllers.enumerated() {
            viewController.view.backgroundColor = .systemBackground
            let navVC = UINavigationController(rootViewController: viewController)
            navVC.navigationItem.backButtonDisplayMode = .minimal
            navVC.navigationItem.largeTitleDisplayMode = .never

            navVC.tabBarItem = UITabBarItem(
                title: nil,
                image: icons[index].iconImage,
                selectedImage: icons[index].selectedImage)

            navigationVCs.append(navVC)
        }

        setViewControllers(navigationVCs, animated: true)
    }
}

extension TabBarViewController {

    enum Icon: Int {
        case home
        case discover
        case trip
        case profile

        var iconImage: UIImage? {
            switch self {
            case .home:
                return UIImage(systemName: "house")
            case .discover:
                return UIImage(systemName: "map")
            case .trip:
                return UIImage(systemName: "suitcase")
            case .profile:
                return UIImage(systemName: "person")
            }
        }

        var selectedImage: UIImage? {
            switch self {
            case .home:
                return UIImage(systemName: "house.fill")
            case .discover:
                return UIImage(systemName: "map.fill")
            case .trip:
                return UIImage(systemName: "suitcase.fill")
            case .profile:
                return UIImage(systemName: "person.fill")
            }
        }
    }
}
