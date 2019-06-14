//
//  AudioPlayer.swift
//  Recorder
//
//  Created by Artur Feshchenko on 6/13/19.
//  Copyright © 2019 home. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift

protocol AudioPlayer {
    var isPlaying: Bool { get }
    var initializePlayer: Single<Void> { get }
    var play: Observable<PlaybackState> { get }
    func stop()
    func pause()
}

enum PlayerError: Error {
    case initializationError(String)
    case playbackError(String)
}

struct PlaybackState {
    let duration: TimeInterval
}

class DefaultPlayer: NSObject, AudioPlayer {
    private var player: AVAudioPlayer?
    private let url: URL
    private let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated)
    private let playbackSubject = PublishSubject<PlaybackState>()
    
    var isPlaying: Bool {
        return player?.isPlaying ?? false
    }
    
    private(set) var initializePlayer: Single<Void>
    
    var play: Observable<PlaybackState> {
        guard let player = player else {
            return Observable.empty()
        }
        
        let checkStateObserable = Observable<Int>.interval(Constants.checkInterval, scheduler: scheduler)
            .takeWhile { [weak self] _ in self?.isPlaying ?? false }
            .map { _ -> PlaybackState in
                return PlaybackState(duration: player.currentTime)
            }
        
        //TODO: Add interruption handling

        player.play()
        
        return Observable.merge([checkStateObserable, playbackSubject])
    }
    
    init(url: URL) {
        self.url = url
        initializePlayer = Single.never()
        
        super.init()
        
        initializePlayer = Single<Void>.create(subscribe: { [weak self] single in
            guard let self = self else {
                single(.error(PlayerError.initializationError("No self")))
                return Disposables.create()
            }
            
            let session = AVAudioSession.sharedInstance()
            
            do {
                try session.setCategory(.playAndRecord)
                try session.overrideOutputAudioPort(.speaker)
                try session.setActive(true)
                
                try self.player = AVAudioPlayer(contentsOf: self.url, fileTypeHint: AVFileType.m4a.rawValue)
                self.player?.delegate = self
                
                if !(self.player?.prepareToPlay() ?? false) {
                    throw RecorderError.initializationError("Player failed to prepare")
                }
            } catch {
                single(.error(PlayerError.initializationError(error.localizedDescription)))
            }
            
            return Disposables.create()
        })
    }
    
    func stop() {
        player?.stop()
    }
    
    func pause() {
        player?.pause()
    }
}

// MARK: - AVAudioPlayerDelegate
extension DefaultPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard flag else { return }
        
        playbackSubject.on(.completed)
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            playbackSubject.onError(PlayerError.playbackError(error.localizedDescription))
        } else {
            playbackSubject.onError(PlayerError.playbackError("Unknown encoding error"))
        }
    }
}
