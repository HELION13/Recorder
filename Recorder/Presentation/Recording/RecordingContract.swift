//
//  RecordingContract.swift
//  Recorder
//
//  Created by Artur Feshchenko on 6/14/19.
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
    let playRecordVisible: Bool
    
    static let `default` = RecordingViewState(progress: 0.0,
                                              duration: "0:00",
                                              recordName: nil,
                                              recordButtonText: "Record",
                                              recordButtonEnabled: false,
                                              saveRecordVisible: false,
                                              playRecordVisible: false)
    
    func togglingRecordButton(active: Bool) -> RecordingViewState {
        return RecordingViewState(progress: progress,
                                  duration: duration,
                                  recordName: recordName,
                                  recordButtonText: recordButtonText,
                                  recordButtonEnabled: active,
                                  saveRecordVisible: saveRecordVisible,
                                  playRecordVisible: playRecordVisible)
    }
}

struct RecordingScreenOutputValues {
    let fileUrl: URL
    let soundValues: [Float]
}

enum RecordingViewAction {
    case recordButtonTapped
    case playRecordTapped
    case saveFileTapped
    case didLoad
}

protocol RecordingViewModel {
    var actionRelay: PublishRelay<RecordingViewAction> { get }
    var viewStateDriver: Driver<RecordingViewState> { get }
}

protocol RecordingScreenOutput {
    var outputDriver: Driver<RecordingScreenOutputValues> { get }
}
