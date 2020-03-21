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
    lazy var selectButton = makeSelectButton()
    fileprivate lazy var tapGestureRecognizer = makeTapGestureRecognizer()

    weak var containerLayoutDelegate: ContainerLayoutDelegate?
    let disposeBag = DisposeBag()

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        addGestureRecognizer(tapGestureRecognizer)

        flex.direction(.column)
            .padding(20, 18, 18, 18)
            .define { (flex) in
                flex.addItem()
                    .justifyContent(.spaceBetween)
                    .direction(.row).define { (flex) in
                        flex.addItem(titleLabel)
                        flex.addItem(selectButton)
                }
            }

    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func setProperties(section: Section) {
        switch section {
        case .browsePosts:
            titleLabel.setText(R.string.phrase.browsePostsTitle().localizedUppercase)

        case .browsePhotosAndVideos:
            titleLabel.setText(R.string.phrase.browsePhotosVideosTitle().localizedUppercase)

        case .browseLikesAndReactions:
            titleLabel.setText(R.string.phrase.browseLikesReactionsTitle().localizedUppercase)

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

    fileprivate func makeSelectButton() -> Button {
        let button = Button()
        button.setImage(R.image.next_period()!, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 34, bottom: 10, right: 0)
        return button
    }

    fileprivate func makeTapGestureRecognizer() -> UITapGestureRecognizer {
        let tapGestureRecognizer = UITapGestureRecognizer()
        isUserInteractionEnabled = true
        tapGestureRecognizer.rx.event.bind { [weak self] (t) in
            self?.selectButton.sendActions(for: .touchUpInside)
        }.disposed(by: disposeBag)
        return tapGestureRecognizer
    }
}
