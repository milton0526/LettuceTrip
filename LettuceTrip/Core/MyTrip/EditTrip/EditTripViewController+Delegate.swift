//
//  EditTripViewController+Delegate.swift
//  LettuceTrip
//
//  Created by Milton Liu on 2023/7/23.
//

import UIKit
import PhotosUI
import UnsplashPhotoPicker

// MARK: - TableView Delegate
extension EditTripViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let place = viewModel.sortedPlaces[indexPath.item]
        let viewController: UIViewController
        let fsManager = FirestoreManager()

        if viewModel.isEditMode {
            viewController = ArrangePlaceViewController(
                viewModel: ArrangePlaceViewModel(trip: viewModel.trip, place: place, fsManager: fsManager), isEditMode: false)
        } else {
            let apiService = GPlaceAPIManager()
            let fsManager = FirestoreManager()
            viewController = PlaceDetailViewController(
                isNewPlace: viewModel.isEditMode,
                viewModel: PlaceDetailViewModel(place: place, fsManager: fsManager, apiService: apiService))
        }
        navigationController?.pushViewController(viewController, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard viewModel.isEditMode else { return nil }
        guard let place = dataSource.itemIdentifier(for: indexPath) else { return nil }
        let deleteAction = UIContextualAction(style: .destructive, title: String(localized: "Delete")) { [weak self] _, _, completion in
            guard
                let self = self,
                let placeId = place.id
            else {
                return
            }

            viewModel.deletePlace(placeId)
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}


// MARK: - TableView Drag Delegate
extension EditTripViewController: UITableViewDragDelegate {

    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let placeItem = String(viewModel.sortedPlaces[indexPath.item].arrangedTime?.ISO8601Format() ?? "")
        let itemProvider = NSItemProvider(object: placeItem as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = placeItem
        return [dragItem]
    }
}


// MARK: - TableView Drop Delegate
extension EditTripViewController: UITableViewDropDelegate {

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        if tableView.hasActiveDrag {
            return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }

        return UITableViewDropProposal(operation: .forbidden)
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        var destinationIndexPath: IndexPath
        if let indexPath = coordinator.destinationIndexPath {
            destinationIndexPath = indexPath
        } else {
            let items = dataSource.snapshot().numberOfItems(inSection: .main)
            destinationIndexPath = IndexPath(item: items - 1, section: 0)
        }

        if coordinator.proposal.operation == .move {
            moveItem(coordinator: coordinator, destinationIndexPath: destinationIndexPath, tableView: tableView)
        }
    }

    private func moveItem(coordinator: UITableViewDropCoordinator, destinationIndexPath: IndexPath, tableView: UITableView) {
        if let dragItem = coordinator.items.first,
            let sourceIndexPath = dragItem.sourceIndexPath {

            for item in coordinator.items {
                let placeTime = item.dragItem.localObject as? String
                viewModel.dragAndDropItem(placeTime: placeTime, fromIndex: sourceIndexPath.row, toIndex: destinationIndexPath.row)
            }
        }
    }
}

// MARK: - ScheduleView Delegate
extension EditTripViewController: ScheduleViewDelegate {
    func didSelectedDate(_ view: ScheduleView, selectedDate: Date) {
        viewModel.currentSelectedDate = selectedDate
        viewModel.filterPlace(by: selectedDate)
    }
}

// MARK: - PHPickerController Delegate
extension EditTripViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        JGHudIndicator.shared.showHud(type: .loading(text: "Updating"))

        let itemProviders = results.map(\.itemProvider)
        if let itemProvider = itemProviders.first, itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, _ in
                guard let self = self, let image = image as? UIImage else { return }
                self.updateTripImage(image: image)
            }
        }
    }

    private func updateTripImage(image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.3) else { return }

        imageView.image = image
        viewModel.updateTripImage(data: imageData)
    }
}

// MARK: - UnsplashPhotoPicker Delegate
extension EditTripViewController: UnsplashPhotoPickerDelegate {

    func unsplashPhotoPicker(_ photoPicker: UnsplashPhotoPicker, didSelectPhotos photos: [UnsplashPhoto]) {
        guard let photo = photos.first?.urls[.regular] else { return }
        imageView.sd_setImage(with: photo) { [weak self] image, _, _, _ in
            guard let self = self, let image = image else { return }
            self.updateTripImage(image: image)
        }
    }

    func unsplashPhotoPickerDidCancel(_ photoPicker: UnsplashPhotoPicker) { }
}
