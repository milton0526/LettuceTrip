//
//  SettingModel.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/28.
//

import UIKit

struct SettingModel: Hashable {
    let title: String
    let image: UIImage?
}

extension SettingModel {
    static let profileSettings = [
        SettingModel(title: String(localized: "Appearance"), image: UIImage(systemName: "paintbrush")),
        SettingModel(title: String(localized: "Language"), image: UIImage(systemName: "globe")),
        SettingModel(title: String(localized: "Delete account"), image: UIImage(systemName: "person.crop.circle.badge.xmark")),
        SettingModel(title: String(localized: "Sign out"), image: UIImage(systemName: "rectangle.portrait.and.arrow.forward"))
    ]

    static let theme = [
        SettingModel(title: String(localized: "Light mode"), image: UIImage(systemName: "lightbulb")),
        SettingModel(title: String(localized: "Dark mode"), image: UIImage(systemName: "lightbulb.slash"))
    ]
}
