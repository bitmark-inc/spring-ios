//
//  VideoPlayerDelegate.swift
//  Spring
//
//  Created by Thuyen Truong on 3/19/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import AVKit
import AVFoundation
import MediaPlayer
import AudioToolbox

protocol VideoPlayerDelegate: class {
    var disposeBag: DisposeBag { get }
    func playVideo(key: String)
    func playVideo(sourcePath: String)
}

extension VideoPlayerDelegate where Self: UIViewController {
    func playVideo(key: String) {
        MediaService.makeVideoURL(key: key)
            .subscribe(onSuccess: { [weak self] (asset) in
                guard let self = self else { return }
                self.play(with: asset)

            }, onError: { [weak self] (error) in
                guard !AppError.errorByNetworkConnection(error) else { return }
                guard let self = self, !self.showIfRequireUpdateVersion(with: error) else { return }

                Global.log.error(error)
            })
            .disposed(by: disposeBag)
    }

    func playVideo(sourcePath: String) {
        guard let videoURL = URL(string: sourcePath) else { return }
        let asset = AVURLAsset(url: videoURL)
        play(with: asset)
    }

    fileprivate func play(with asset: AVURLAsset) {
        let playerItem = AVPlayerItem(asset: asset)

        let player = AVPlayer(playerItem: playerItem)
        let playerVC = AVPlayerViewController()

        playerVC.player = player
        self.present(playerVC, animated: true) {
            player.play()
        }
    }
}
