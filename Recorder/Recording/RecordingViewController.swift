//
//  RecordingViewController.swift
//  Recorder
//
//  Created by Artur Feshchenko on 6/12/19.
//  Copyright © 2019 home. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class RecordingViewController: UIViewController {
    private var recordingProgress: UIProgressView = {
        let progressView = UIProgressView(frame: CGRect.zero)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        
        return progressView
    }()
    
    private var durationLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        
        return label
    }()
    
    private var recordButton: UIButton = {
        let button = UIButton(type: .system)
        button.isEnabled = false
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    private var fileNameLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        
        return label
    }()
    
    private var saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    var viewModel: RecordingViewModel? = BasicRecordingViewModel(recorder: DefaultRecorder())
    
    private let disposeBag = DisposeBag()
    
    override func loadView() {
        super.loadView()
        
        prepareLayout()
    }
    
    private func prepareLayout() {
        let container = UIStackView(arrangedSubviews: [recordingProgress, durationLabel, recordButton, fileNameLabel, saveButton])
        container.translatesAutoresizingMaskIntoConstraints = false
        container.axis = .vertical
        container.alignment = .center
        container.distribution = .fill
        container.spacing = 8.0
        
        recordingProgress.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        recordingProgress.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        
        view.addSubview(container)
        container.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        container.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        container.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 18.0).isActive = true
        container.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 18.0).isActive = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let viewModel = viewModel else { return }
        
        recordButton.rx.tap
            .map { RecordingViewAction.recordButtonTapped }
            .bind(to: viewModel.actionRelay)
            .disposed(by: disposeBag)
        
        saveButton.rx.tap
            .map { RecordingViewAction.saveFileTapped }
            .bind(to: viewModel.actionRelay)
            .disposed(by: disposeBag)
        
        //add show record button
        
        viewModel.actionRelay.accept(.didLoad)
        
        viewModel.viewStateDriver
            .drive(onNext: { [weak self] state in
                guard let self = self else { return }
                
                self.durationLabel.text = state.duration
                self.recordingProgress.progress = state.progress
                self.recordButton.isEnabled = state.recordButtonEnabled
                self.recordButton.setTitle(state.recordButtonText, for: .normal)
                self.fileNameLabel.text = state.recordName
                self.fileNameLabel.isHidden = state.recordName == nil
                self.saveButton.isHidden = !state.saveRecordVisible
            })
            .disposed(by: disposeBag)
    }
}
