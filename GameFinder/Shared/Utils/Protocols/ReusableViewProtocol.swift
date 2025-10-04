//
//  ReusableViewProtocol.swift
//  GameFinder
//
//  Created by Suji Jang on 9/29/25.
//

import UIKit

protocol ReusableViewProtocol {
    static var identifier: String { get }
}

extension UICollectionReusableView: ReusableViewProtocol {
    static var identifier: String {
        return String(describing: self)
    }
}
