//
//  PlaybackViewModel.swift
//  Recorder
//
//  Created by Artur Feshchenko on 6/13/19.
//  Copyright © 2019 home. All rights reserved.
//

import RxSwift
import RxCocoa
import RxDataSources

final class BasicPlaybackViewModel: PlaybackViewModel {
    let actionRelay = PublishRelay<PlaybackViewAction>()
    private let viewStateRelay = BehaviorRelay<PlaybackViewState>(value: .default)
    private let playbackStateRelay = BehaviorRelay<[PlaybackVisualSection]>(value: [.default])
    
    var viewStateDriver: Driver<PlaybackViewState> {
        return viewStateRelay
            .asDriver(onErrorJustReturn: .default)
            .startWith(.default)
    }
    
    var playbackStateDriver: Driver<[PlaybackVisualSection]> {
        return playbackStateRelay
            .asDriver(onErrorJustReturn: [PlaybackVisualSection.default])
            .startWith([.default])
    }
    
    private let player: AudioPlayer
    private let initialSection: PlaybackVisualSection
    
    private let disposeBag = DisposeBag()
    
    init(player: AudioPlayer, soundValues: [Float]) {
        self.player = player
        let units = soundValues.map { PlaybackVisualUnit(soundValue: $0, played: false) }
        initialSection = PlaybackVisualSection(items: units)
        
        actionRelay
            .bind(onNext: { [weak self] action in
                guard let self = self else { return }
                
                switch action {
                case .playTapped:
                    player.isPlaying ? self.handlePause() :
                        self.handlePlay()
                case .stopTapped:
                    break
                case .didLoad:
                    self.handleDidLoad()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func handleDidLoad() {
        self.playbackStateRelay.accept([self.initialSection])
        
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
            .subscribe(onNext: { [weak self] state in
                guard let self = self else { return }
                
                let durationString = String(format: "%d:%02d", Int(state.duration / 60.0), Int(state.duration))
                let viewState = PlaybackViewState(duration: durationString,
                                                  playButtonText: "Pause",
                                                  stopButtonEnabled: true)
                
                self.viewStateRelay.accept(viewState)
                
//                let index = Int(state.duration * (1.0 / Constants.checkInterval))
//                var section = self.playbackStateRelay.value[0]
//                guard index < section.items.count else { return }
//                
//                section.items[index].played = true
//                self.playbackStateRelay.accept([section])
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
}
