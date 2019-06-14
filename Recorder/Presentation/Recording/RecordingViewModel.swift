//
//  RecordingViewModel.swift
//  Recorder
//
//  Created by Artur Feshchenko on 6/12/19.
//  Copyright © 2019 home. All rights reserved.
//

import RxSwift
import RxCocoa

final class BasicRecordingViewModel: RecordingViewModel {
    let actionRelay = PublishRelay<RecordingViewAction>()
    
    private let outputRelay = PublishRelay<RecordingScreenOutputValues>()
    private let viewStateRelay = BehaviorRelay<RecordingViewState>(value: .default)
    var viewStateDriver: Driver<RecordingViewState> {
        return viewStateRelay
            .asDriver(onErrorJustReturn: .default)
            .startWith(.default)
    }
    
    private let recorder: AudioRecorder
    private var soundValues: [Float] = []
    
    private let disposeBag = DisposeBag()
    
    init(recorder: AudioRecorder) {
        self.recorder = recorder
        
        actionRelay
            .bind(onNext: { [weak self] action in
                guard let self = self else { return }

                switch action {
                case .recordButtonTapped:
                    self.recorder.isRecording ? self.recorder.stop() : self.handleRecord()
                case .playRecordTapped:
                    self.handlePlayRecord()
                case .saveFileTapped:
                    self.handleFileSave()
                case .didLoad:
                    self.handleDidLoad()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func handlePlayRecord() {
        outputRelay.accept(RecordingScreenOutputValues(fileUrl: Constants.tempDirectory, soundValues: soundValues))
    }
    
    private func handleDidLoad() {
        recorder.initializeRecorder
            .map { _ -> RecordingViewState in
                return RecordingViewState.default.togglingRecordButton(active: true)
            }
            .subscribe(onSuccess: { [weak self] state in
                self?.viewStateRelay.accept(state)
            }, onError: { [weak self] error in
                debugPrint(error.localizedDescription)
                self?.viewStateRelay.accept(RecordingViewState.default)
            })
            .disposed(by: disposeBag)
    }
    
    private func handleRecord() {
        recorder.record
            .do(onSubscribed: { [weak self] in
                self?.soundValues = []
            })
            .subscribe(onNext: { [weak self] state in
                let durationString = String(format: "%d:%02d", Int(state.duration / 60.0), Int(state.duration))
                let progressValue = Float(state.duration) /  Float(Constants.maxRecordingDuration)
                
                let viewState = RecordingViewState(progress: progressValue,
                                                   duration: durationString,
                                                   recordName: nil,
                                                   recordButtonText: "Stop",
                                                   recordButtonEnabled: true,
                                                   saveRecordVisible: false,
                                                   playRecordVisible: false)
                
                debugPrint("Loudness: \(state.soundLevel)")
                self?.soundValues.append(state.soundLevel)
                self?.viewStateRelay.accept(viewState)
            }, onError: { [weak self] error in
                debugPrint(error.localizedDescription)
                self?.viewStateRelay.accept(RecordingViewState.default.togglingRecordButton(active: true))
            }, onCompleted: { [weak self] in
                guard let self = self else { return }
                
                let viewState = RecordingViewState(progress: self.viewStateRelay.value.progress,
                                                   duration: self.viewStateRelay.value.duration,
                                                   recordName: nil,
                                                   recordButtonText: "Record",
                                                   recordButtonEnabled: true,
                                                   saveRecordVisible: true,
                                                   playRecordVisible: true)
                
                self.viewStateRelay.accept(viewState)
            })
            .disposed(by: disposeBag)
    }
    
    private func handleFileSave() {
        recorder.saveRecord
            .subscribe(onSuccess: { [weak self] url in
                guard let self = self else { return }
                
                let viewState = RecordingViewState(progress: self.viewStateRelay.value.progress,
                                                   duration: self.viewStateRelay.value.duration,
                                                   recordName: url.lastPathComponent,
                                                   recordButtonText: "Record",
                                                   recordButtonEnabled: true,
                                                   saveRecordVisible: false,
                                                   playRecordVisible: self.viewStateRelay.value.playRecordVisible)
                
                self.viewStateRelay.accept(viewState)
            }, onError: { error in
                debugPrint(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - Recording Screen Output
extension BasicRecordingViewModel: RecordingScreenOutput {
    var outputDriver: Driver<RecordingScreenOutputValues> {
        return outputRelay.asDriver(onErrorRecover: { _ in fatalError("It doesn't work like that") })
    }
}
