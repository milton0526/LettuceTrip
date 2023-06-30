//
//  LocationMapCell.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/25.
//

import UIKit
import MapKit
import TinyConstraints

class LocationMapCell: UITableViewCell {

    lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.isUserInteractionEnabled = false
        mapView.layer.cornerRadius = 20
        mapView.layer.masksToBounds = true
        return mapView
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(mapView)
        mapView.height(120)
        mapView.edgesToSuperview(insets: .uniform(16))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func config(with place: Place) {
        let annotation = MKPointAnnotation()
        annotation.coordinate = place.coordinate
        annotation.title = place.name
        let region = MKCoordinateRegion(
            center: place.coordinate,
            latitudinalMeters: 100,
            longitudinalMeters: 100)

        mapView.showAnnotations([annotation], animated: false)
        mapView.region = region
    }
}
