//
//  BrowseView.swift
//  Spring
//
//  Created by Thuyen Truong on 3/11/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class BrowseView: UIView {

    // MARK: - Properties
    fileprivate lazy var titleLabel = makeTitleLabel()
    fileprivate lazy var infoLabel = makeInfoLabel()
    lazy var selectButton = makeSelectButton()

    weak var containerLayoutDelegate: ContainerLayoutDelegate?
    let disposeBag = DisposeBag()

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        flex.direction(.column)
            .padding(20, 18, 18, 18)
            .define { (flex) in
                flex.addItem()
                    .justifyContent(.spaceBetween)
                    .direction(.row).define { (flex) in
                        flex.addItem(titleLabel)
                        flex.addItem(selectButton)
                }
                flex.addItem(infoLabel).marginTop(12)
            }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func setProperties(section: Section) {
        switch section {
        case .browsePosts:
            titleLabel.setText(R.string.phrase.browsePostsTitle().localizedUppercase)
            infoLabel.setText(R.string.phrase.browsePostsInfo())

        case .browsePhotosAndVideos:
            titleLabel.setText(R.string.phrase.browsePhotosVideosTitle().localizedUppercase)
            infoLabel.setText(R.string.phrase.browsePhotosVideosInfo())

        case .browseLikesAndReactions:
            titleLabel.setText(R.string.phrase.browseLikesReactionsTitle().localizedUppercase)
            infoLabel.setText(R.string.phrase.browseLikesReactionsInfo())

        default:
            break
        }
    }
}

extension BrowseView {
    fileprivate func makeTitleLabel() -> Label {
        let label = Label()
        label.apply(
            font: R.font.domaineSansTextLight(size: 22),
            colorTheme: ColorTheme.black)
        return label
    }

    fileprivate func makeInfoLabel() -> Label {
        let label = Label()
        label.numberOfLines = 0
        label.apply(
            font: R.font.atlasGroteskLight(size: 16),
            colorTheme: ColorTheme.black,
            lineHeight: 1.25)
        return label
    }

    fileprivate func makeQuestionButton() -> Button {
        let button = Button()
        button.contentEdgeInsets = UIEdgeInsets(top: 5, left: 0, bottom: 23, right: 28)
        button.setImage(R.image.questionIcon(), for: .normal)
        return button
    }

    fileprivate func makeSelectButton() -> Button {
        let button = Button()
        button.setImage(R.image.next_period()!, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 34, bottom: 10, right: 0)
        return button
    }
}
