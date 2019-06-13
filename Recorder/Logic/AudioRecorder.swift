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
    var startRecording: Observable<RecordingState> { get }
    var saveRecord: Single<URL> { get }
    func stopRecording()
}

enum RecorderError: Error {
    case permissionError(String)
    case initializationError(String)
    case recordingError(String)
    case savingError(String)
}

struct RecordingState {
    let duration: TimeInterval
    let loudness: Float
}

class DefaultRecorder: NSObject, AudioRecorder {
    private var recorder: AVAudioRecorder?
    private let scheduler = SerialDispatchQueueScheduler(qos: .userInitiated)
    
    var isRecording: Bool {
        return recorder?.isRecording ?? false
    }
    
    private let requestPermission: Single<Void>
    private(set) var initializeRecorder: Single<Void>
    private(set) var saveRecord: Single<URL>
    
    var startRecording: Observable<RecordingState> {
        guard let recorder = recorder else {
            return Observable.empty()
        }
        
        let checkStateObserable = Observable<Int>.interval(Constants.checkInterval, scheduler: scheduler)
            .takeWhile { [weak self] iteration in
                guard let self = self else { return false }
                
                let timeRemaining = Double(iteration) < Constants.maxRecordingDuration * (1.0 / Constants.checkInterval)
                
                return timeRemaining && self.isRecording
            }
            .map { _ -> RecordingState in
                recorder.updateMeters()
                let clampedValue = min(max(-160.0, recorder.averagePower(forChannel: 0)), 0.0)
                let normalizedValue = Float((clampedValue + 160.0) / 160.0)
                
                let state = RecordingState(duration: recorder.currentTime, loudness: normalizedValue)
                
                return state
            }
        
        //TODO: Add interruption handling
        
        recorder.record(forDuration: Constants.maxRecordingDuration)
        
        return Observable.merge(recordingSubject, checkStateObserable)
    }
    
    private let recordingSubject = PublishSubject<RecordingState>()
    private let settings = [AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                            AVSampleRateKey: 12000,
                            AVNumberOfChannelsKey: 1,
                            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue]
    
    private var tempDirectory: URL = {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls.first!
        return documentDirectory.appendingPathComponent("tempRecording.m4a")
    }()
    
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
                
                try self.recorder = AVAudioRecorder(url: self.tempDirectory, settings: self.settings)
                self.recorder?.delegate = self
                self.recorder?.isMeteringEnabled = true
                
                if !(self.recorder?.prepareToRecord() ?? false) {
                    throw RecorderError.initializationError("Recorder failed to prepare")
                }
            } catch {
                throw RecorderError.initializationError(error.localizedDescription)
            }
        }
        
        saveRecord = Single<URL>.create { [weak self] single in
            guard let self = self else {
                single(.error(RecorderError.savingError("No self")))
                
                return Disposables.create()
            }
            
            let fileManager = FileManager.default
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MMM-dd_hh:mm:ss"
            var targetUrl = URL(fileURLWithPath: "")
            
            do {
                let url = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                targetUrl = url.appendingPathComponent("Record_\(formatter.string(from: Date()))").appendingPathExtension("m4a")
                try fileManager.copyItem(at: self.tempDirectory, to: targetUrl)
            } catch {
                single(.error(RecorderError.savingError(error.localizedDescription)))
            }
            
            single(.success(targetUrl))
            
            return Disposables.create()
        }
    }
    
    func stopRecording() {
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
