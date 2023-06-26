//
//  Date+Extension.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/26.
//

import Foundation

extension Date {

    func resetHourAndMinute() -> Date? {
        let calendar = Calendar.current

        var components = calendar.dateComponents([.year, .month, .weekday, .day, .hour, .minute], from: self)
        components.hour = 0
        components.minute = 0
        return calendar.date(from: components)
    }

    
}
