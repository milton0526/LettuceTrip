//
//  ArrangePlaceDetailCell.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/25.
//

import UIKit

class ArrangePlaceDetailCell: UITableViewCell {

    @IBOutlet weak var fromDatePicker: UIDatePicker!
    @IBOutlet weak var toDatePicker: UIDatePicker!
    @IBOutlet weak var memoTextView: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func config(with trip: Trip) {
        [fromDatePicker, toDatePicker].forEach { picker in
            picker?.minimumDate = trip.startDate
            picker?.maximumDate = trip.endDate
            picker?.date = trip.startDate
        }
    }

    func passData() -> PlaceArrangement {
        let arrangeTime = fromDatePicker.date
        let duration = toDatePicker.date.timeIntervalSince(arrangeTime)
        let memo = memoTextView.text ?? ""
        let placeArrangement = PlaceArrangement(arrangedTime: arrangeTime, duration: duration, memo: memo)
        return placeArrangement
    }

    @IBAction func fromDatePickerChanged(_ sender: UIDatePicker) {
        toDatePicker.minimumDate = sender.date
    }
}