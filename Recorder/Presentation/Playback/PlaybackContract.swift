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

struct PlaybackViewState {
    let duration: String
    let playButtonText: String
    let stopButtonEnabled: Bool
    
    static let `default` = PlaybackViewState(duration: "0:00",
                                             playButtonText: "Play",
                                             stopButtonEnabled: false)
}

struct PlaybackVisualUnit {
    let soundValue: Float
    var played: Bool = false
}

enum PlaybackViewAction {
    case playTapped
    case stopTapped
    case didLoad
}

enum PlaybackUpdateAction {
    case reloadAll
    case reload(at: Int)
}

protocol PlaybackViewModel {
    var actionRelay: PublishRelay<PlaybackViewAction> { get }
    var viewStateDriver: Driver<PlaybackViewState> { get }
    var playbackStateDriver: Driver<PlaybackUpdateAction> { get }
    
    var values: [PlaybackVisualUnit] { get }
}
