//
//  VideoCollectionCell.swift
//  Spring
//
//  Created by Thuyen Truong on 3/16/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout
import RxSwift

class VideoCollectionCell: CollectionViewCell {

    fileprivate lazy var photoImage = makePhotoImageView()
    fileprivate lazy var playButton = makePlayButton()
    fileprivate lazy var gradientLayerView = makeGradientLayerView()
    fileprivate lazy var tapGestureRecognizer = makeTapGestureRecognizer()

    weak var videoPlayerDelegate: VideoPlayerDelegate?
    let gradientViewHeight: CGFloat = 30
    let disposeBag = DisposeBag()

    // MARK: - Init
    override init(frame: CGRect) {
      super.init(frame: frame)

        addSubview(photoImage)
        addSubview(gradientLayerView)
        addSubview(playButton)

        addGestureRecognizer(tapGestureRecognizer)

        photoImage.snp.makeConstraints { (make) in
            make.width.height.equalToSuperview()
        }

        playButton.snp.makeConstraints { (make) in
            make.trailing.equalTo(photoImage.snp.trailing).offset(-10)
            make.bottom.equalTo(photoImage.snp.bottom).offset(-7)
        }

        gradientLayerView.snp.makeConstraints { (make) in
            make.height.equalTo(gradientViewHeight)
            make.width.leading.bottom.equalToSuperview()
        }
    }

    func setData(media: Media) {
        photoImage.loadPhotoMedia(for: media.id, photoPath: media.thumbnail)

        playButton.rx.tap.bind { [weak self] in
            self?.videoPlayerDelegate?.playVideo(sourcePath: media.source)
        }.disposed(by: disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension VideoCollectionCell {
    fileprivate func makePhotoImageView() -> ImageView {
        let imageView = ImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }

    fileprivate func makePlayButton() -> Button {
        let button = Button()
        button.setImage(R.image.smallPlayVideo()!, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 34, left: 34, bottom: 0, right: 0)
        return button
    }

    fileprivate func makeGradientLayerView() -> UIView {
        let gradient: CAGradientLayer = CAGradientLayer()
        gradient.colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.withAlphaComponent(0.5).cgColor,
            UIColor.black.withAlphaComponent(0.75).cgColor
        ]
        gradient.locations = [0.0 , 1.0]
        gradient.frame = CGRect(x: 0.0, y: 0.0, width: frame.size.width, height: gradientViewHeight)

        let view = UIView()
        view.layer.insertSublayer(gradient, at: 0)
        return view
    }

    fileprivate func makeTapGestureRecognizer() -> UITapGestureRecognizer {
        let tapGestureRecognizer = UITapGestureRecognizer()
        isUserInteractionEnabled = true
        tapGestureRecognizer.rx.event.bind { [weak self] (t) in
            self?.playButton.sendActions(for: .touchUpInside)
        }.disposed(by: disposeBag)
        return tapGestureRecognizer
    }
}
