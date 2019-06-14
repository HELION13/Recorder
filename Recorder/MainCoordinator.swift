//
//  MainCoordinator.swift
//  Recorder
//
//  Created by Artur Feshchenko on 6/14/19.
//  Copyright © 2019 home. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

class MainCoordinator {
    private let router: Router
    private let container: DependencyContainer
    
    private let disposeBag = DisposeBag()
    
    init(router: Router, container: DependencyContainer) {
        self.router = router
        self.container = container
    }
    
    func start() {
        let controller = RecordingViewController()
        let recorder = container.resolveRecorder()
        let viewModel = container.resolveRecordingViewModel(recorder: recorder)
        controller.viewModel = viewModel
        
        viewModel.outputDriver
            .drive(onNext: { [weak self] output in
                self?.showPlayback(with: output.fileUrl, soundValues: output.soundValues)
            })
            .disposed(by: disposeBag)
        
        router.set(controllers: [controller], animated: false)
    }
    
    func showPlayback(with fileUrl: URL, soundValues: [Float]) {
        let controller = PlaybackViewController()
        let viewModel = BasicPlaybackViewModel(player: DefaultPlayer(url: fileUrl), soundValues: soundValues)
        controller.viewModel = viewModel
        
        router.show(controller: controller, animated: true)
    }
}
