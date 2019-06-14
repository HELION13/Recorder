//
//  AudioRecorder.swift
//  Recorder
//
//  Created by Artur Feshchenko on 6/13/19.
//  Copyright © 2019 home. All rights reserved.
//

import Foundation
import AVFoundation
import RxSwift

protocol AudioRecorder {
    var isRecording: Bool { get }
    var initializeRecorder: Single<Void> { get }
    var record: Observable<RecordingState> { get }
    var saveRecord: Single<URL> { get }
    func stop()
}

enum RecorderError: Error {
    case permissionError(String)
    case initializationError(String)
    case recordingError(String)
    case savingError(String)
}

struct RecordingState {
    let duration: TimeInterval
    let soundLevel: Float
}

class DefaultRecorder: NSObject, AudioRecorder {
    private var recorder: AVAudioRecorder?
    private let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated)
    private let recordingSubject = PublishSubject<RecordingState>()
    private let requestPermission: Single<Void>
    private let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                            AVSampleRateKey: 12000,
                            AVNumberOfChannelsKey: 1,
                            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
    
    var isRecording: Bool {
        return recorder?.isRecording ?? false
    }
    
    private(set) var initializeRecorder: Single<Void>
    private(set) var saveRecord: Single<URL>
    
    var record: Observable<RecordingState> {
        guard let recorder = recorder else {
            return Observable.empty()
        }
        
        let checkStateObserable = Observable<Int>.interval(Constants.checkInterval, scheduler: scheduler)
            .takeWhile { iteration in
                let timeRemaining = Double(iteration) < Constants.maxRecordingDuration * (1.0 / Constants.checkInterval)

                return timeRemaining && recorder.isRecording
            }
            .map { _ -> RecordingState in
                recorder.updateMeters()
                let clampedValue = min(max(-120.0, recorder.averagePower(forChannel: 0)), 0.0)
                let normalizedValue = Float((clampedValue + 120.0) / 120.0)
                
                let state = RecordingState(duration: recorder.currentTime, soundLevel: normalizedValue)
                
                return state
            }
        
        //TODO: Add interruption handling
        
        recorder.record(forDuration: Constants.maxRecordingDuration)
        
        return Observable.merge(recordingSubject, checkStateObserable)
    }
    
    override init() {
        requestPermission = Single<Void>.create { observer in
            switch AVAudioSession.sharedInstance().recordPermission {
            case .undetermined:
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    if granted {
                        observer(.success(()))
                    } else {
                        observer(.error(RecorderError.permissionError("Record permission denied")))
                    }
                }
            case .denied:
                observer(.error(RecorderError.permissionError("Record permission denied")))
            case .granted:
                observer(.success(()))
            @unknown default:
                observer(.error(RecorderError.permissionError("Permission error unknown")))
            }
            
            return Disposables.create()
        }
        
        initializeRecorder = Single.never()
        saveRecord = Single.never()
        
        super.init()
        
        initializeRecorder = requestPermission.map { [weak self] _ in
            guard let self = self else { return }
            
            let session = AVAudioSession.sharedInstance()
            
            do {
                try session.setCategory(.playAndRecord)
                try session.overrideOutputAudioPort(.speaker)
                try session.setActive(true)
                
                try self.recorder = AVAudioRecorder(url: Constants.tempDirectory, settings: self.settings)
                self.recorder?.delegate = self
                self.recorder?.isMeteringEnabled = true
                
                if !(self.recorder?.prepareToRecord() ?? false) {
                    throw RecorderError.initializationError("Recorder failed to prepare")
                }
            } catch {
                throw RecorderError.initializationError(error.localizedDescription)
            }
        }
        
        saveRecord = Single<URL>.create { single in
            let fileManager = FileManager.default
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MMM-dd_hh:mm:ss"
            var targetUrl = URL(fileURLWithPath: "")
            
            do {
                let url = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                targetUrl = url.appendingPathComponent("Record_\(formatter.string(from: Date()))").appendingPathExtension("m4a")
                try fileManager.copyItem(at: Constants.tempDirectory, to: targetUrl)
            } catch {
                single(.error(RecorderError.savingError(error.localizedDescription)))
            }
            
            single(.success(targetUrl))
            
            return Disposables.create()
        }
    }
    
    func stop() {
        recorder?.stop()
    }
}

// MARK: - AVAudioRecorderDelegate
extension DefaultRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        guard flag else { return }
        
        recordingSubject.on(.completed)
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            recordingSubject.onError(RecorderError.recordingError(error.localizedDescription))
        } else {
            recordingSubject.onError(RecorderError.recordingError("Unknown encoding error"))
        }
    }
}
