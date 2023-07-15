//
//  ScheduleView.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/25.
//

import UIKit

protocol ScheduleViewDelegate: AnyObject {
    func didSelectedDate(_ view: ScheduleView, selectedDate: Date)
}

class ScheduleView: UIView, UICollectionViewDelegate, UICollectionViewDataSource {

    var schedules: [Date] = [] {
        didSet {
            collectionView.reloadData()
        }
    }

    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(CalendarCell.self, forCellWithReuseIdentifier: CalendarCell.identifier)
        return collectionView
    }()

    weak var delegate: ScheduleViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .systemBackground
        addSubview(collectionView)
        collectionView.edgesToSuperview(insets: .uniform(8))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Delegate method
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedDate = schedules[indexPath.item]
        delegate?.didSelectedDate(self, selectedDate: selectedDate)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 44, height: 60)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    // MARK: - DataSource method
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        schedules.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let calendarCell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CalendarCell.identifier,
            for: indexPath) as? CalendarCell
        else {
            fatalError("Failed to dequeue cityCell")
        }

        let schedule = schedules[indexPath.item].displayDate()
        calendarCell.dayLabel.text = String(describing: schedule.day)
        calendarCell.weekLabel.text = schedule.weekday

        if indexPath.item == 0 {
            calendarCell.isSelected = true
        } else {
            calendarCell.isSelected = false
        }

        return calendarCell
    }
}
