//
//  PlaybackViewModel.swift
//  Recorder
//
//  Created by Artur Feshchenko on 6/13/19.
//  Copyright © 2019 home. All rights reserved.
//

import RxSwift
import RxCocoa

final class BasicPlaybackViewModel: PlaybackViewModel {
    let actionRelay = PublishRelay<PlaybackViewAction>()
    private let viewStateRelay = BehaviorRelay<PlaybackViewState>(value: .default)
    private let playbackStateRelay = BehaviorRelay<PlaybackUpdateAction>(value: .reloadAll)
    
    var viewStateDriver: Driver<PlaybackViewState> {
        return viewStateRelay
            .asDriver(onErrorJustReturn: .default)
            .startWith(.default)
    }
    
    var playbackStateDriver: Driver<PlaybackUpdateAction> {
        return playbackStateRelay
            .asDriver(onErrorJustReturn: .reloadAll)
            .startWith(.reloadAll)
    }
    
    var values: [PlaybackVisualUnit] = []
    
    private let player: AudioPlayer
    
    private let disposeBag = DisposeBag()
    
    init(player: AudioPlayer, soundValues: [Float]) {
        self.player = player
        values = soundValues.map { PlaybackVisualUnit(soundValue: $0, played: false) }
        
        actionRelay
            .bind(onNext: { [weak self] action in
                guard let self = self else { return }
                
                switch action {
                case .playTapped:
                    player.isPlaying ? self.handlePause() :
                        self.handlePlay()
                case .stopTapped:
                    self.handleStop()
                case .didLoad:
                    self.handleDidLoad()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func handleDidLoad() {
        self.playbackStateRelay.accept(.reloadAll)
        
        player.initializePlayer
            .map { _ -> PlaybackViewState in
                return PlaybackViewState.default
            }
            .subscribe(onSuccess: { [weak self] state in
                self?.viewStateRelay.accept(state)
            }, onError: { [weak self] error in
                debugPrint(error.localizedDescription)
                self?.viewStateRelay.accept(.default)
            })
            .disposed(by: disposeBag)
    }
    
    private func handlePlay() {
        player.play
            .do(onSubscribe: { [weak self] in
                guard let self = self else { return }
                
                self.values = self.values.map { PlaybackVisualUnit(soundValue: $0.soundValue, played: false) }
                self.playbackStateRelay.accept(.reloadAll)
            })
            .subscribe(onNext: { [weak self] state in
                guard let self = self else { return }
                
                let durationString = String(format: "%d:%02d", Int(state.duration / 60.0), Int(state.duration))
                let viewState = PlaybackViewState(duration: durationString,
                                                  playButtonText: "Pause",
                                                  stopButtonEnabled: true)
                
                self.viewStateRelay.accept(viewState)
                
                let index = Int(state.duration * (1.0 / Constants.checkInterval))
                guard index < self.values.count else { return }
                
                self.values[index].played = true
                self.playbackStateRelay.accept(.reload(at: index))
            }, onError: { [weak self] error in
                debugPrint(error.localizedDescription)
                self?.viewStateRelay.accept(.default)
            }, onCompleted: { [weak self] in
                guard let self = self else { return }
                
                self.viewStateRelay.accept(.default)
            })
            .disposed(by: disposeBag)
    }
    
    private func handlePause() {
        player.pause()
        let state = PlaybackViewState(duration: viewStateRelay.value.duration,
                                      playButtonText: "Play",
                                      stopButtonEnabled: viewStateRelay.value.stopButtonEnabled)
        
        viewStateRelay.accept(state)
    }
    
    private func handleStop() {
        player.stop()
        
        let state = PlaybackViewState(duration: viewStateRelay.value.duration,
                                      playButtonText: "Play",
                                      stopButtonEnabled: false)
        
        viewStateRelay.accept(state)
    }
}
