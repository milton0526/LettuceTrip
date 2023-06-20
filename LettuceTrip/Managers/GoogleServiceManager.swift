//
//  GoogleServiceManager.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import Foundation
import GooglePlaces

protocol GooglePlaceServiceType {
    func fetchPlaceDetail(by placeID: String, completion: @escaping (Result<GMSPlace, Error>) -> Void)
    func fetchPlacePhoto(with metaData: GMSPlacePhotoMetadata, completion: @escaping (Result<(UIImage, String?), Error>) -> Void)
}

class GooglePlaceService: GooglePlaceServiceType {

    private let placesClient = GMSPlacesClient.shared()

    func fetchPlaceDetail(by placeID: String, completion: @escaping (Result<GMSPlace, Error>) -> Void) {
        let fields: GMSPlaceField = [
            .name, .coordinate, .formattedAddress,
            .businessStatus, .photos, .rating,
            .openingHours, .website, .userRatingsTotal
        ]

        placesClient.fetchPlace(fromPlaceID: placeID, placeFields: fields, sessionToken: nil) { place, error in
            if let error = error {
                print("An error occur while fetch place detail: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            if let place = place {
                completion(.success(place))
            }
        }
    }

    func fetchPlacePhoto(with metaData: GMSPlacePhotoMetadata, completion: @escaping (Result<(UIImage, String?), Error>) -> Void) {

        placesClient.loadPlacePhoto(metaData) { image, error in
            if let error = error {
                print("An error occur while fetch place photos: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }

            if let image = image {
                let attribution = String(describing: metaData.attributions)
                completion(.success((image, attribution)))
            }
        }
    }
}

/* Mock data
 Optional(Name: Olive Garden Italian Restaurant
 Coordinate: (40.759333 -73.984667)
 Opening Hours: Weekdays: (
     "Monday: 11:00\U202fAM\U2009\U2013\U200910:00\U202fPM",
     "Tuesday: 11:00\U202fAM\U2009\U2013\U200910:00\U202fPM",
     "Wednesday: 11:00\U202fAM\U2009\U2013\U200910:00\U202fPM",
     "Thursday: 11:00\U202fAM\U2009\U2013\U200910:00\U202fPM",
     "Friday: 11:00\U202fAM\U2009\U2013\U200911:00\U202fPM",
     "Saturday: 11:00\U202fAM\U2009\U2013\U200911:00\U202fPM",
     "Sunday: 11:00\U202fAM\U2009\U2013\U200910:00\U202fPM"
 ), Periods: (
     "Open: Day 1, Time (11:00); Close: Day 1, Time (22:00)",
     "Open: Day 2, Time (11:00); Close: Day 2, Time (22:00)",
     "Open: Day 3, Time (11:00); Close: Day 3, Time (22:00)",
     "Open: Day 4, Time (11:00); Close: Day 4, Time (22:00)",
     "Open: Day 5, Time (11:00); Close: Day 5, Time (22:00)",
     "Open: Day 6, Time (11:00); Close: Day 6, Time (23:00)",
     "Open: Day 7, Time (11:00); Close: Day 7, Time (23:00)"
 )
 Formatted Address: 2 Times Sq, New York, NY 10036, USA
 Rating: 4.100000
 User Ratings Total: 5897
 Website: https://www.olivegarden.com/locations/ny/new-york/nyc-times-square/1451?cmpid=br:og_ag:ie_ch:loc_ca:OGGMB_sn:gmb_gt:new-york-ny-1451_pl:locurl_rd:1335
 Photos: (
     "attributions: Ale Ramirez, reference: AZose0lrSSK-kpUAOr1kkCbt7Ciehrd3icUY_h3HdEdMMYKctNg1UC2AoUSklfn2XuQo0r_i1uGoSxUreBTZxjiUTeGVaUyrMEHgqj6FrTA9fzAfxir9a0CWhrX_beG0pq8RyVHUmR-UpUOX5tlCUUDO4y1wM3r0OYfrfflDFtVs4a2JVLyC, photo index: 0, max height: 12000.00, max width: 9000.00, ",
     "attributions: Olive Garden Italian Restaurant, reference: AZose0n-WA-n2ujs4CQDgfysBVnBwrdoLo0dECrgV0Z6o0bNg9cJ-xyd_7aJHEU83k7xP0DjVxHSInrkE1SEkrRH85rSL97asg-0evb3uBNP3epqVuI30eDK1fIY_-HVi8kF1bdIs27fNVaQxkVlHGXL_E2KwoYdKXgrQIz2Jqep5qH0G27K, photo index: 1, max height: 1365.00, max width: 1365.00, ",
     "attributions: Alice Washington, reference: AZose0nkj1TXD5M85zocAR7uIvycq_kqBiSzhdSfHYeqLRT5kZqK1cPri5eyzY1OdUsOLQn2aQ344xst4m0IINQ9eXYXISFh5EV0lvrIqoepw-lHedVo9As6VtCyVIl8k-OV_5SPRyEj2A6jbEIPhlwesfDOV0_p9u0gCG1PnN2rFJW1590, photo index: 2, max height: 4000.00, max width: 1868.00, ",
     "attributions: Islam Erfan, reference: AZose0kAsmi6JDJtf7M2lxfaATLHVDdvpZhhKiPeLr5d04Rufq1akxn3VqlJjRZU2X6gffRl3-phYMHIR8QNzy4Ay7TL6PPDq9nAuetuyeSTFmoG_yhZ970CWOR_S-KGNykPf6X40DlRkRKVQeYaNSHvKryAg9gyId-HuPvl9weB6g_Hfwo-, photo index: 3, max height: 3072.00, max width: 4080.00, ",
     "attributions: Jaxley Pereira da Silva, reference: AZose0nKTbGIoFGIIhdubXq3WyWCOwDhsmRXSY1GKtZBADidL3NqgM1bzYFWHkaxPbMpo68221Sq08b5nSt5Aq4SzgWQLbckUKf5Tx7pwEHTXHsBoQPtVBWOvceETw6wtm7_mLheNHmTifHzPHoFTYAbzZuzxhDGm7ufvSVD6_zT7BL-68JP, photo index: 4, max height: 12000.00, max width: 9000.00, ",
     "attributions: Olive Garden Italian Restaurant, reference: AZose0lZcZjKA5PbSeLbhuJdDh50_7jCC0aEZnva8uLLZQlHIdBPrz0YHCy6Ag2uPynPed9540myWx-DYIL3f58HNEHJloycSHFxk-44VtL_JhGiHFLys2HmV7JnNK2wPv6mT8PR49PirDl_pXuD0nO0fyqkGeGTAgEaFGBXjiGfPFQnmxdj, photo index: 5, max height: 1362.00, max width: 1362.00, ",
     "attributions: Sarah M, reference: AZose0lre6Mhd8T2rzUQyO4eQH02C_xxCIYTfsPGlH834h_VhRbOrvaQPANPng_tA5LacXr3moUdLFMwfSlgwjuL9Ch4-OSdCbrhlynsTRoj5wD_TCHayqz1v_sabvEJ7NR-2C2jobHiY4ShtAeNflpCVvsgCa61-XskLwUwbHBN0JFSI-hV, photo index: 6, max height: 1440.00, max width: 1762.00, ",
     "attributions: Ale Ramirez, reference: AZose0njyiVokuLa1mgCGXbwrC_07TvX-8_QP3R0wTGiWGI_LOzjmZO8JSlAv_LGYFpQvj-ZsQeo5786FLRh-JzdmWlq_MueHAjBDbn6Tg4WU0xhx2mLpn3ZCI4tuPd6zEYVIXgQ_1Fwy_YIbABfD6tNftO_2iBy2Ytw4NxfIIbC4dnX0xX5, photo index: 7, max height: 12000.00, max width: 9000.00, ",
     "attributions: Dobromir Gaydazhiev, reference: AZose0mwpoahIEKbcKJ8eiSWGeUUCIQLqh0JlQUuRA51JG8-cyx1YOWvDk9ypqWuzkPyhLKkJquUJNhG0wRdzShUtCbFaiSIn_bGDfwZIFKdVSo7RO8wWcURLf72ekM6ampgc_gp83iEgGLVbKLVcocOJtsL2RiLy7L3bppRRMVWuLEaF6A, photo index: 8, max height: 4624.00, max width: 2600.00, ",
     "attributions: Fernando Granco, reference: AZose0lIy2S4PdMbJjajFZws9WaLwWTxnKnlSCR2_durB8yRsp-3CK8xx9HmYIAsWNoPBLB_J0EQo7yDV1lRHZ7uqhpXyX9oyWRbD4PUCDbhxwfDfL7PuBbCoKH_osADO7y43R-4Frt3FIuxW5J05ejMtowEyn5FMlE3OitbTYVY-_yWg7np, photo index: 9, max height: 3072.00, max width: 4080.00, "
 )
 Business Status: Operational)
 */
