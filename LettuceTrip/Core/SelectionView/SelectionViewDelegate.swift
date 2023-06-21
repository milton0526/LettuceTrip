//
//  SelectionViewDelegate.swift
//  DI_1_Delegate
//
//  Created by Milton Liu on 2023/5/24.
//

import UIKit

protocol SelectionViewDelegate: AnyObject {
    func didSelectedButton(_ selectionView: SelectionView, at index: Int)
}
