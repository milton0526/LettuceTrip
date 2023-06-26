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
        // let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: place.coordinate))
        let region = MKCoordinateRegion(
            center: place.coordinate,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000)
        mapView.setRegion(region, animated: false)
        // mapView.showAnnotations([], animated: <#T##Bool#>)
    }
}
