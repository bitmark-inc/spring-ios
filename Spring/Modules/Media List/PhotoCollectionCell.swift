//
//  PhotoCollectionCell.swift
//  Spring
//
//  Created by Thuyen Truong on 3/15/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout

class PhotoCollectionCell: CollectionViewCell {

    fileprivate lazy var photoImage = makePhotoImageView()

    // MARK: - Init
    override init(frame: CGRect) {
      super.init(frame: frame)

        addSubview(photoImage)

        photoImage.snp.makeConstraints { (make) in
            make.width.height.equalToSuperview()
        }
    }

    func setData(media: Media) {
        photoImage.loadPhotoMedia(for: media.id, photoPath: media.source)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PhotoCollectionCell {
    fileprivate func makePhotoImageView() -> ImageView {
        let imageView = ImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }
}
