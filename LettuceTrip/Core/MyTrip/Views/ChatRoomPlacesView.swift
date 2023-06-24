//
//  ChatRoomPlacesCollectionView.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/24.
//

import UIKit

class ChatRoomPlacesView: UIView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    var items: [Int] = [1, 2] {
        didSet {
            collectionView.reloadData()
        }
    }

    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .tintColor
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(CirclePlaceCell.self, forCellWithReuseIdentifier: CirclePlaceCell.identifier)
        return collectionView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .tintColor
        addSubview(collectionView)
        collectionView.edgesToSuperview(insets: .uniform(8))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Delegate method
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 80, height: 80)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    // MARK: - DataSource method
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let placeCell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CirclePlaceCell.identifier,
            for: indexPath) as? CirclePlaceCell
        else {
            fatalError("Failed to dequeue cityCell")
        }

        // let items = places[indexPath.item]
        return placeCell
    }
}
