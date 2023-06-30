//
//  PlacePhotoHeaderView.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/20.
//

import UIKit
import TinyConstraints

class PlacePhotoHeaderView: UITableViewHeaderFooterView {

    lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: flowLayout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.allowsSelection = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.register(PlacePhotoCell.self, forCellWithReuseIdentifier: PlacePhotoCell.identifier)
        return collectionView
    }()

    lazy var pageControl: UIPageControl = {
        let pageControl = UIPageControl()
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = .white
        pageControl.pageIndicatorTintColor = .black
        pageControl.addTarget(self, action: #selector(changePage), for: .valueChanged)
        return pageControl
    }()

    var photos: [Photo] = [] {
        didSet {
            pageControl.numberOfPages = photos.count
            DispatchQueue.main.async { [weak self] in
                self?.collectionView.reloadData()
            }
        }
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        contentView.addSubview(collectionView)
        contentView.addSubview(pageControl)

        collectionView.edgesToSuperview()
        pageControl.trailingToSuperview(offset: -16)
        pageControl.bottomToSuperview(offset: -16)
    }

    @objc private func changePage(_ sender: UIPageControl) {
        let point = CGPoint(
            x: collectionView.bounds.width * CGFloat(sender.currentPage),
            y: 0
        )
        collectionView.setContentOffset(point, animated: true)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = scrollView.contentOffset.x / scrollView.bounds.width
        pageControl.currentPage = Int(page)
    }
}

// MARK: - UICollectionView Delegate
extension PlacePhotoHeaderView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        return CGSize(width: width, height: 300)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

// MARK: - UICollectionView DataSource
extension PlacePhotoHeaderView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        photos.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let photoCell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PlacePhotoCell.identifier,
            for: indexPath) as? PlacePhotoCell
        else {
            fatalError("Failed to dequeue PlacePhotoCell")
        }

        if let url = photos[indexPath.item].url {
            photoCell.imageView.setImage(with: url)
        }

        photoCell.titleLabel.text = "Foursquare"
        return photoCell
    }
}


// MARK: - UICollectionView Cell
private class PlacePhotoCell: UICollectionViewCell {

    lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: .init(named: "placeholder0"))
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .white
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)

        imageView.edgesToSuperview()
        titleLabel.leadingToSuperview(offset: 16)
        titleLabel.bottomToSuperview(offset: -16)
    }
}
