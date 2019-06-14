//
//  PlaybackSoundValueCollectionViewCell.swift
//  Recorder
//
//  Created by Artur Feshchenko on 6/14/19.
//  Copyright © 2019 home. All rights reserved.
//

import UIKit

class PlaybackSoundValueCollectionViewCell: UICollectionViewCell {
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = .white
    }
    
    func updatePlayedState(_ played: Bool) {
        contentView.backgroundColor = played ? .orange : .white
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
