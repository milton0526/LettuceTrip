//
//  SceneDelegate.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit
import FirebaseAuth
import Combine

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private let fsManager = FirestoreManager()
    private var subscription: AnyCancellable?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)

        var viewController: UIViewController

        if fsManager.user == nil {
            let authManager = AuthManager(fsManager: fsManager)
            let signInVC = SignInViewController(authManager: authManager)
            viewController = signInVC
        } else {
            let tabBarVC = TabBarViewController(fsManager: fsManager)
            viewController = tabBarVC
        }

        if let appTheme = UserDefaults.standard.string(forKey: AppTheme.key) {
            if appTheme == AppTheme.followSystem.mode {
                window?.overrideUserInterfaceStyle = .unspecified
            } else {
                window?.overrideUserInterfaceStyle = appTheme == AppTheme.light.mode ? .light : .dark
            }
        }

        window?.tintColor = .systemTeal
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let firstURL = URLContexts.first?.url else { return }

        let urlComponents = URLComponents(string: firstURL.absoluteString)
        guard
            let query = urlComponents?.query,
            let userID = fsManager.user
        else {
            // show alert to let user sign in
            return
        }

        if let topVC = window?.topViewController {
            let alert = UIAlertController(
                title: String(localized: "Some one invite your to edit this trip"),
                message: nil,
                preferredStyle: .alert)

            let accept = UIAlertAction(title: "Accept", style: .default) { [weak self] _ in
                guard let self = self else { return }
                subscription = fsManager.updateMember(userId: userID, atTrip: query)
                    .sink(receiveCompletion: { _ in
                    }, receiveValue: { _ in })
            }

            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            alert.addAction(accept)
            alert.addAction(cancel)
            topVC.present(alert, animated: true)
        }
    }
}

extension UIWindow {
    var topViewController: UIViewController? {
        if var topVC = rootViewController {
            while let viewController = topVC.presentedViewController {
                topVC = viewController
            }
            return topVC
        } else {
            return nil
        }
    }
}
