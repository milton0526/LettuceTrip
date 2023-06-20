//
//  RatingStarView.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit
import Cosmos

class RatingStarView: CosmosView {

    func customSetting() {
        settings.updateOnTouch = false
        settings.fillMode = .precise
        settings.filledColor = .systemTeal
        settings.emptyBorderColor = .systemTeal
        settings.filledBorderColor = .systemTeal
        settings.emptyBorderWidth = 1.5
        settings.starSize = 15
        settings.starMargin = 1.5
    }
}

