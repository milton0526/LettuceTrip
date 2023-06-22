//
//  SearchCityViewController.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/6/21.
//

import UIKit
import TinyConstraints
import MapKit

class SearchCityViewController: UIViewController {

    enum Section {
        case main
    }

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.delegate = self
        return collectionView
    }()

    private var dataSource: UICollectionViewDiffableDataSource<Section, MKMapItem>!

    var searchRegion = MKCoordinateRegion(MKMapRect.world)

    private var localSearch: MKLocalSearch? {
        willSet {
            // Clear the results and cancel the currently running local search before starting a new search.
            searchResult = []
            localSearch?.cancel()
        }
    }

    private var searchResult: [MKMapItem]? {
        didSet {
            if let searchResult {
                updateSnapshot(searchResult)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureDataSource()
    }

    private func setupUI() {
        title = String(localized: "Destination")
        view.backgroundColor = .systemBackground
        view.addSubview(collectionView)
        collectionView.edgesToSuperview(usingSafeArea: true)
        configSearchController()
    }

    private func configSearchController() {
        let searchControl = UISearchController()
        searchControl.searchBar.placeholder = String(localized: "Search city to travel...")
        searchControl.searchBar.delegate = self
        searchControl.hidesNavigationBarDuringPresentation = false
        navigationItem.searchController = searchControl
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func createLayout() -> UICollectionViewCompositionalLayout {
        let config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        return UICollectionViewCompositionalLayout.list(using: config)
    }

    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, MKMapItem>(handler: cellRegistration)

        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { collectionView, indexPath, item in
            let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            return cell
        }
    }

    private func cellRegistration(_ cell: UICollectionViewListCell, indexPath: IndexPath, item: MKMapItem) {
        var config = cell.defaultContentConfiguration()
        config.text = item.name
        config.secondaryText = item.placemark.formattedAddress

        let symbolIcon = item.pointOfInterestCategory?.symbolName ?? MKPointOfInterestCategory.defaultPointOfInterestSymbolName
        config.image = UIImage(systemName: symbolIcon)
        cell.contentConfiguration = config
    }

    func updateSnapshot(_ places: [MKMapItem]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, MKMapItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(places)

        dataSource.apply(snapshot)
    }

    private func search(for queryString: String?) {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = queryString
        search(using: searchRequest)
    }

    private func search(using searchRequest: MKLocalSearch.Request) {
        searchRequest.resultTypes = .address

        localSearch = MKLocalSearch(request: searchRequest)
        localSearch?.start { [unowned self] response, error in
            if let error = error {
                self.showAlertToUser(error: error)
                return
            }

            self.searchResult = response?.mapItems
        }
    }
}

// MARK: - UICollectionView Delegate
extension SearchCityViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension SearchCityViewController: UISearchBarDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)

        // This system calls this method when the user taps Search on the `UISearchBar` or on the keyboard.
        // Because the user didn't select a row with a suggested completion, run the search with the query text in
        // the search field.
        search(for: searchBar.text)
    }
}
