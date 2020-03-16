//
//  ImageView.swift
//  Spring
//
//  Created by thuyentruong on 11/12/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import FlexLayout
import Kingfisher

class ImageView: UIImageView {

    let disposeBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    override init(image: UIImage?) {
        super.init(image: image)
        setupViews()
    }

    override init(image: UIImage?, highlightedImage: UIImage?) {
        super.init(image: image, highlightedImage: highlightedImage)
        setupViews()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
    }

    func loadPhotoMedia(_ media: Media) {
        guard let photoURL = URL(string: media.url) else {
            Global.log.error("invalid photo URL: \(media.url)")
            return
        }
        let imageResource = ImageResource(downloadURL: photoURL, cacheKey: media.id)

        kf.setImage(with: imageResource)
    }

    func loadURL(_ url: URL, width: CGFloat) -> Completable {
        return Completable.create { (event) -> Disposable in
            if ImageCache.default.isCached(forKey: url.path) {
                let imageResource = ImageResource(downloadURL: URL(string: url.path)!, cacheKey: url.path)
                self.kf.setImage(with: imageResource) {
                    (result) in
                    switch result {
                    case .success(_):
                        event(.completed)
                    case .failure(let error):
                        event(.error(error))
                    }
                }
            } else {
                _ = MediaService.makePhotoURL(key: url.path)
                    .observeOn(MainScheduler.instance)
                    .subscribe(onSuccess: { [weak self] (photoURL, modifier) in
                        guard let self = self else { return }

                        let imageResource = ImageResource(downloadURL: photoURL, cacheKey: url.path)
                        self.kf.setImage(with: imageResource, options: [.requestModifier(modifier)]) { (result) in
                            switch result {
                            case .success(_):
                                event(.completed)
                            case .failure(let error):
                                if error.isInvalidResponseStatusCode(406) {
                                    event(.error(ServerAPIError(code: .RequireUpdateVersion, message: "")))
                                } else {
                                    event(.error(error))
                                }
                            }
                        }
                    }, onError: { (error) in
                        event(.error(error))
                    })
            }
            return Disposables.create()
        }
    }

    func setupViews() {
        contentMode = .scaleAspectFit
        layer.masksToBounds = true
    }
}
