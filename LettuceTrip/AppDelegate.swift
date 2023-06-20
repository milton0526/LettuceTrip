//
//  AppDelegate.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit
import GoogleMaps
import GooglePlaces
import FirebaseCore

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    struct MapKeyInfo: Decodable {
        let googleMapKey: String
    }

    private let mapKey: String? = {
        guard let url = Bundle.main.url(forResource: "GoogleMapKey", withExtension: "plist") else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let result = try PropertyListDecoder().decode(MapKeyInfo.self, from: data)
            return result.googleMapKey
        } catch {
            return nil
        }
    }()


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        if let mapKey = mapKey {
            GMSServices.provideAPIKey(mapKey)
            GMSPlacesClient.provideAPIKey(mapKey)
        }
        FirebaseApp.configure()
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

