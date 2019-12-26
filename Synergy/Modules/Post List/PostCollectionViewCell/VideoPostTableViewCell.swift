//
//  VideoPostTableViewCell.swift
//  Synergy
//
//  Created by thuyentruong on 12/5/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout
import RxSwift
import SwiftDate

class VideoPostTableViewCell: TableViewCell, PostDataTableViewCell {

    // MARK: - Properties
    fileprivate lazy var postInfoLabel = makePostInfoLabel()
    fileprivate lazy var captionLabel = makeCaptionLabel()
    fileprivate lazy var photoImageView = makePhotoImageView()
    weak var clickableTextDelegate: ClickableTextDelegate?

    // MARK: - Inits
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        themeService.rx
            .bind({ $0.postCellBackgroundColor }, to: rx.backgroundColor)

        contentView.flex.direction(.column).define { (flex) in
            flex.addItem().height(18).backgroundColor(.white)
            flex.addItem().backgroundColor(ColorTheme.silver.color).height(1)
            flex.addItem().padding(12, 17, 0, 12).define { (flex) in
                flex.addItem(postInfoLabel)
                flex.addItem(captionLabel).marginTop(12).basis(1)
            }
            flex.addItem(photoImageView).marginTop(20).height(400)
            flex.addItem().backgroundColor(ColorTheme.silver.color).height(1)
        }

        contentView.flex.layout(mode: .adjustHeight)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        photoImageView.flex.height(400)
        invalidateIntrinsicContentSize()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Data
    func bindData(post: Post) {
        makePostInfo(timestamp: post.timestamp, friends: post.tags.toArray(), locationName: post.location?.name)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] in
                self?.postInfoLabel.attributedText = $0
            })
            .disposed(by: disposeBag)

        captionLabel.attributedText = LinkAttributedString.make(
            string: post.post ?? (post.title ?? ""),
            lineHeight: 1.25,
            attributes: [.font: R.font.atlasGroteskLight(size: 16)!])

        if let media = post.mediaData.first, let thumbnail = media.thumbnail, let thumbnailURL = URL(string: thumbnail), thumbnailURL.pathExtension != "mp4" {
            photoImageView.loadURL(thumbnailURL)
                .subscribe(onCompleted: { [weak self] in
                    guard let self = self else { return }
                    self.photoImageView.flex.markDirty()
                    self.contentView.flex.layout(mode: .adjustHeight)
                }, onError: { (error) in
                    guard !AppError.errorByNetworkConnection(error) else { return }
                    Global.log.error(error)
                })
                .disposed(by: disposeBag)
        } else {
            photoImageView.image = R.image.defaultThumbnail()
            photoImageView.flex.height(300)
        }

        postInfoLabel.flex.markDirty()
        captionLabel.flex.markDirty()
        photoImageView.flex.markDirty()
        contentView.flex.layout(mode: .adjustHeight)
    }
}

extension VideoPostTableViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {

        clickableTextDelegate?.click(textView, url: URL)
        return false
    }
}

extension VideoPostTableViewCell {
    fileprivate func makePostInfoLabel() -> UITextView {
        let textView = UITextView()
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.linkTextAttributes = [
            .foregroundColor: themeService.attrs.blackTextColor
        ]
        return textView
    }

    fileprivate func makeCaptionLabel() -> UITextView {
        let textView = UITextView()
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.backgroundColor = .clear
        textView.delegate = self
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.dataDetectorTypes = .link
        return textView
    }

    fileprivate func makePhotoImageView() -> ImageView {
        return ImageView()
    }
}
