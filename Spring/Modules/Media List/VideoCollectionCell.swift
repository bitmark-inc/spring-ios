//
//  VideoCollectionCell.swift
//  Spring
//
//  Created by Thuyen Truong on 3/16/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout

class VideoCollectionCell: CollectionViewCell {

    fileprivate lazy var photoImage = makePhotoImageView()
    fileprivate lazy var playButton = makePlayButton()

    // MARK: - Init
    override init(frame: CGRect) {
      super.init(frame: frame)

        addSubview(photoImage)
        addSubview(playButton)

        photoImage.snp.makeConstraints { (make) in
            make.width.height.equalToSuperview()
        }

        playButton.snp.makeConstraints { (make) in
            make.trailing.equalTo(photoImage.snp.trailing).offset(10)
            make.bottom.equalTo(photoImage.snp.bottom).offset(11)
        }
    }

    func setData(media: Media) {
        photoImage.loadPhotoMedia(media)
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
        button.isEnabled = false
        return button
    }
}
