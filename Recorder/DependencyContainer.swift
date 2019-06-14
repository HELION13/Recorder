//
//  DependencyContainer.swift
//  Recorder
//
//  Created by Artur Feshchenko on 6/14/19.
//  Copyright © 2019 home. All rights reserved.
//

import Foundation

class DependencyContainer {
    func resolveRecorder() -> AudioRecorder {
        return DefaultRecorder()
    }
    
    func resolvePlayer(with url: URL) -> AudioPlayer {
        return DefaultPlayer(url: url)
    }
    
    func resolveRecordingViewModel(recorder: AudioRecorder) -> RecordingViewModel & RecordingScreenOutput {
        return BasicRecordingViewModel(recorder: recorder)
    }
    
    func reolvePlaybackViewModel(player: AudioPlayer, soundValues: [Float]) -> PlaybackViewModel {
        return BasicPlaybackViewModel(player: player, soundValues: soundValues)
    }
}
