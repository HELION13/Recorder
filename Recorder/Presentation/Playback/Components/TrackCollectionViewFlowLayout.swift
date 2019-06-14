//
//  TrackCollectionViewFlowLayout.swift
//  Recorder
//
//  Created by Artur Feshchenko on 6/14/19.
//  Copyright © 2019 home. All rights reserved.
//

import UIKit

class TrackCollectionViewFlowLayout: UICollectionViewFlowLayout {
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }
        let mutableAttributes = NSArray(array: attributes, copyItems: true) as! Array<UICollectionViewLayoutAttributes>
        
        for attribute in mutableAttributes {
            let current = attribute
            var resultFrame = current.frame
            resultFrame.origin.y = collectionViewContentSize.height - resultFrame.height
            current.frame = resultFrame
        }
        
        return mutableAttributes
    }
}
