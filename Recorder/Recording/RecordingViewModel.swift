//
//  RecordingViewModel.swift
//  Recorder
//
//  Created by Artur Feshchenko on 6/12/19.
//  Copyright © 2019 home. All rights reserved.
//

import RxSwift
import RxCocoa

struct RecordingViewState {
    let progress: Float
    let duration: String
    let recordName: String?
    let recordButtonText: String
    let recordButtonEnabled: Bool
    let saveRecordVisible: Bool
    
    static let `default` = RecordingViewState(progress: 0.0,
                                              duration: "0:00",
                                              recordName: nil,
                                              recordButtonText: "Record",
                                              recordButtonEnabled: false,
                                              saveRecordVisible: false)
    
    func togglingRecordButton(active: Bool) -> RecordingViewState {
        return RecordingViewState(progress: progress,
                                  duration: duration,
                                  recordName: recordName,
                                  recordButtonText: recordButtonText,
                                  recordButtonEnabled: active,
                                  saveRecordVisible: saveRecordVisible)
    }
}

enum RecordingViewAction {
    case recordButtonTapped
    case showRecordTapped
    case saveFileTapped
    case didLoad
}

protocol RecordingViewModel {
    var actionRelay: PublishRelay<RecordingViewAction> { get }
    var viewStateDriver: Driver<RecordingViewState> { get }
}

class BasicRecordingViewModel: RecordingViewModel {
    let actionRelay = PublishRelay<RecordingViewAction>()
    
    private let viewStateRelay = BehaviorRelay<RecordingViewState>(value: .default)
    var viewStateDriver: Driver<RecordingViewState> {
        return viewStateRelay
            .asDriver(onErrorJustReturn: .default)
            .startWith(.default)
    }
    
    private let recorder: AudioRecorder
    
    private let disposeBag = DisposeBag()
    
    init(recorder: AudioRecorder) {
        self.recorder = recorder
        
        actionRelay.bind(onNext: { [weak self] action in
            guard let self = self else { return }

            switch action {
            case .recordButtonTapped:
                self.recorder.isRecording ? self.recorder.stopRecording() : self.handleRecord()
            case .showRecordTapped:
                break
            case .saveFileTapped:
                self.handleFileSave()
            case .didLoad:
                self.handleDidLoad()
            }
        }).disposed(by: disposeBag)
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
        recorder.startRecording.subscribe(onNext: { [weak self] state in
            let durationString = String(format: "%d:%02d", Int(state.duration / 60.0), Int(state.duration))
            let progressValue = Float(state.duration) /  Float(Constants.maxRecordingDuration)
            let viewState = RecordingViewState(progress: progressValue,
                                               duration: durationString,
                                               recordName: nil,
                                               recordButtonText: "Stop",
                                               recordButtonEnabled: true,
                                               saveRecordVisible: false)
            debugPrint("Loudness: \(state.loudness)")
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
                                               saveRecordVisible: true)
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
                                                   saveRecordVisible: false)
                
                self.viewStateRelay.accept(viewState)
            }, onError: { error in
                debugPrint(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
}
