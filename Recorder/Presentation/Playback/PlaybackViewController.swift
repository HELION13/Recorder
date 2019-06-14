//
//  PlaybackViewController.swift
//  Recorder
//
//  Created by Artur Feshchenko on 6/13/19.
//  Copyright © 2019 home. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

final class PlaybackViewController: UIViewController {
    private var trackVolumeCollectionView: UICollectionView = {
        let layout = TrackCollectionViewFlowLayout()
        layout.minimumLineSpacing = 0.0
        layout.minimumInteritemSpacing = 1.0
        layout.itemSize = CGSize(width: 1.0, height: 50.0)
        layout.scrollDirection = .horizontal
        let collection = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collection.translatesAutoresizingMaskIntoConstraints = false
        collection.bounces = false
        collection.allowsSelection = false
        collection.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        collection.backgroundColor = .brown
        collection.register(PlaybackSoundValueCollectionViewCell.self, forCellWithReuseIdentifier: "soundValueCell")
        
        return collection
    }()
    
    private var durationLabel: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "0:00"
        label.backgroundColor = .black
        label.textColor = .orange
        label.numberOfLines = 0
        
        return label
    }()
        
    private var playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Play", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
    
    private var stopButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Stop", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        return button
    }()
        
    var viewModel: PlaybackViewModel?
        
    private let disposeBag = DisposeBag()
        
    override func loadView() {
        super.loadView()
        
        prepareLayout()
    }
    
    private func prepareLayout() {
        view.backgroundColor = .white
        title = "Playback"
        
        let controlsContainer = UIStackView(arrangedSubviews: [playButton, stopButton])
        controlsContainer.translatesAutoresizingMaskIntoConstraints = false
        controlsContainer.axis = .horizontal
        controlsContainer.alignment = .center
        controlsContainer.distribution = .equalCentering
        controlsContainer.spacing = 8.0
        
        let collectionContainer = UIView(frame: CGRect.zero)
        collectionContainer.translatesAutoresizingMaskIntoConstraints = false
        collectionContainer.addSubview(trackVolumeCollectionView)
        collectionContainer.addSubview(durationLabel)
        
        trackVolumeCollectionView.leadingAnchor.constraint(equalTo: collectionContainer.leadingAnchor).isActive = true
        trackVolumeCollectionView.trailingAnchor.constraint(equalTo: collectionContainer.trailingAnchor).isActive = true
        trackVolumeCollectionView.topAnchor.constraint(equalTo: collectionContainer.topAnchor).isActive = true
        trackVolumeCollectionView.bottomAnchor.constraint(equalTo: collectionContainer.bottomAnchor).isActive = true
        
        durationLabel.leadingAnchor.constraint(equalTo: collectionContainer.leadingAnchor).isActive = true
        durationLabel.bottomAnchor.constraint(equalTo: collectionContainer.bottomAnchor).isActive = true
        
        let container = UIStackView(arrangedSubviews: [collectionContainer, controlsContainer])
        container.translatesAutoresizingMaskIntoConstraints = false
        container.axis = .vertical
        container.alignment = .center
        container.distribution = .fill
        container.spacing = 8.0
        
        collectionContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        collectionContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        
        view.addSubview(container)
        container.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        container.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        container.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 18.0).isActive = true
        container.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 18.0).isActive = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let viewModel = viewModel else { return }
        
        playButton.rx.tap
            .map { PlaybackViewAction.playTapped }
            .bind(to: viewModel.actionRelay)
            .disposed(by: disposeBag)
        
        stopButton.rx.tap
            .map { PlaybackViewAction.stopTapped }
            .bind(to: viewModel.actionRelay)
            .disposed(by: disposeBag)
        
        viewModel.playbackStateDriver
            .drive(onNext: { [weak self] action in
                guard let self = self else { return }
                
                switch action {
                case .reloadAll:
                    self.trackVolumeCollectionView.reloadData()
                case .reload(at: let index):
                    let indexPath = IndexPath(row: index, section: 0)
                    let cell = self.trackVolumeCollectionView.cellForItem(at: indexPath) as? PlaybackSoundValueCollectionViewCell
                    cell?.updatePlayedState(true)
                    self.trackVolumeCollectionView.scrollToItem(at: indexPath, at: .right, animated: false)
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.viewStateDriver
            .drive(onNext: { [weak self] state in
                guard let self = self else { return }
                
                self.durationLabel.text = state.duration
                self.stopButton.isEnabled = state.stopButtonEnabled
                self.playButton.setTitle(state.playButtonText, for: .normal) 
            })
            .disposed(by: disposeBag)
        
        trackVolumeCollectionView.dataSource = self
        trackVolumeCollectionView.delegate = self
        
        viewModel.actionRelay.accept(.didLoad)
    }
}

// MARK: - Collection View Data Source
extension PlaybackViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.values.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "soundValueCell", for: indexPath) as! PlaybackSoundValueCollectionViewCell
        cell.updatePlayedState(viewModel?.values[indexPath.row].played ?? false)
        
        return cell
    }
}

// MARK: - Collection View Flow Layout Delegate
extension PlaybackViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let viewModel = viewModel else { return CGSize.zero }
        
        let item = viewModel.values[indexPath.row]
        
        return CGSize(width: 1.0, height: 50.0 * Double(item.soundValue))
    }
}
