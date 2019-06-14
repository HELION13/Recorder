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
import RxDataSources

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
    private var dataSource: RxCollectionViewSectionedAnimatedDataSource<PlaybackVisualSection>!
        
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
        
        let animationConfiguration = AnimationConfiguration(insertAnimation: .bottom,
                                                            reloadAnimation: .fade,
                                                            deleteAnimation: .bottom)
        
        dataSource = RxCollectionViewSectionedAnimatedDataSource<PlaybackVisualSection>(animationConfiguration: animationConfiguration,
                                                                     configureCell: configureCell)
        
        playButton.rx.tap
            .map { PlaybackViewAction.playTapped }
            .bind(to: viewModel.actionRelay)
            .disposed(by: disposeBag)
        
        stopButton.rx.tap
            .map { PlaybackViewAction.stopTapped }
            .bind(to: viewModel.actionRelay)
            .disposed(by: disposeBag)
        
        viewModel.playbackStateDriver
            .drive(trackVolumeCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        viewModel.viewStateDriver
            .drive(onNext: { [weak self] state in
                guard let self = self else { return }
                
                self.durationLabel.text = state.duration
                self.stopButton.isEnabled = state.stopButtonEnabled
                self.playButton.setTitle(state.playButtonText, for: .normal) 
            })
            .disposed(by: disposeBag)
        
        trackVolumeCollectionView.delegate = self
        
        viewModel.actionRelay.accept(.didLoad)
    }
    
    private func configureCell(dataSource: CollectionViewSectionedDataSource<PlaybackVisualSection>,
                               collectionView: UICollectionView,
                               indexPath: IndexPath,
                               item: PlaybackVisualUnit) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "soundValueCell", for: indexPath) as! PlaybackSoundValueCollectionViewCell
        cell.updatePlayedState(item.played)
        
        return cell
    }
}

// MARK: - Collection View Flow Layout Delegate
extension PlaybackViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let section = dataSource.sectionModels[0]
        let item = section.items[indexPath.row]
        
        return CGSize(width: 1.0, height: 50.0 * Double(item.soundValue))
    }
}
