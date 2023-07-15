//
//  SelectionViewDataSource.swift
//  DI_1_Delegate
//
//  Created by Milton Liu on 2023/5/24.
//

import UIKit

@objc protocol SelectionViewDataSource: AnyObject {
    func numberOfButtons(_ selectionView: SelectionView) -> Int

    func selectionView(_ selectionView: SelectionView, titleForButtonAt index: Int) -> String?

    @objc optional func colorForSelectedButton(_ selectionView: SelectionView) -> UIColor?

    @objc optional func fontForButtonTitle(_ selectionView: SelectionView) -> UIFont?
}
