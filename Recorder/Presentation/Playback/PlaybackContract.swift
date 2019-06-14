//
//  PlaybackContract.swift
//  Recorder
//
//  Created by Artur Feshchenko on 6/14/19.
//  Copyright © 2019 home. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources

struct PlaybackViewState {
    let duration: String
    let playButtonText: String
    let stopButtonEnabled: Bool
    
    static let `default` = PlaybackViewState(duration: "0:00",
                                             playButtonText: "Play",
                                             stopButtonEnabled: false)
}

struct PlaybackVisualSection {
    var items: [PlaybackVisualUnit]
    
    static let `default` = PlaybackVisualSection(items: [])
}

extension PlaybackVisualSection: AnimatableSectionModelType {
    typealias Identity = String
    typealias Item = PlaybackVisualUnit
    
    var identity: String {
        let ids = items.map { $0.identity }
        
        return ids.joined(separator: "-")
    }
    
    init(original: PlaybackVisualSection, items: [Item]) {
        self = original
        self.items = items
    }
}

struct PlaybackVisualUnit: IdentifiableType, Equatable {
    typealias Identity = String
    
    var identity: Identity {
        return "\(uuid)_\(played)"
    }
    
    let uuid = UUID()
    let soundValue: Float
    var played: Bool = false
    
    static func == (lhs: PlaybackVisualUnit, rhs: PlaybackVisualUnit) -> Bool {
        return lhs.identity == rhs.identity
    }
}

enum PlaybackViewAction {
    case playTapped
    case stopTapped
    case didLoad
}

protocol PlaybackViewModel {
    var actionRelay: PublishRelay<PlaybackViewAction> { get }
    var viewStateDriver: Driver<PlaybackViewState> { get }
    var playbackStateDriver: Driver<[PlaybackVisualSection]> { get }
}
