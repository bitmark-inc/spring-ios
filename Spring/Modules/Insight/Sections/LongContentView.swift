//
//  LongContentView.swift
//  Spring
//
//  Created by Thuyen Truong on 1/16/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout
import SwiftRichString

class LongContentView: UIView {

    // MARK: - Properties
    fileprivate lazy var titleLabel = makeTitleLabel()
    fileprivate lazy var contentLabel = makeContentLabel()
    fileprivate lazy var readMoreButton = makeReadMoreButton()

    weak var containerLayoutDelegate: ContainerLayoutDelegate?
    let disposeBag = DisposeBag()

    // MARK: - Inits
    override init(frame: CGRect) {
        super.init(frame: frame)

        flex.direction(.column)
            .define { (flex) in
                flex.addItem(SectionSeparator())

                flex.addItem()
                    .padding(34, 18, 34, 16)
                    .define { (flex) in
                        flex.addItem(titleLabel)
                        flex.addItem().marginRight(32).define { (flex) in
                            flex.addItem(contentLabel).marginTop(7)
                            flex.addItem(readMoreButton).marginTop(34).alignSelf(.end)
                        }
                    }
            }


    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    func setProperties(container: InsightViewController) {
        weak var container = container

        readMoreButton.rx.tap.bind { [weak container] in
            container?.gotoHowFBTrackScreen()
        }.disposed(by: disposeBag)
    }
}

extension LongContentView {
    fileprivate func makeTitleLabel() -> Label {
        let label = Label()
        label.apply(
            text: R.string.phrase.howFBTrackTitle().localizedUppercase,
            font: R.font.domaineSansTextLight(size: Size.ds(22)),
            colorTheme: .black, lineHeight: 1.056)
        return label
    }

    fileprivate func makeContentLabel() -> Label {
        let label = Label()
        label.numberOfLines = 0
        label.apply(
            text: R.string.phrase.howFBTrackShortContent(),
            font: R.font.atlasGroteskLight(size: Size.ds(12)),
            colorTheme: ColorTheme.black, lineHeight: 1.27)
        return label
    }

    fileprivate func makeReadMoreButton() -> Button {
        let normal = Style {
            $0.font = R.font.atlasGroteskLightItalic(size: Size.ds(10))
            $0.color = ColorTheme.cornFlowerBlue.color
        }

        let linkStyle = normal.byAdding {
            $0.underline = (.single, ColorTheme.cornFlowerBlue.color)
        }

        let button = Button()
        button.setAttributedTitle(
            R.string.localizable.readMore().set(style: StyleXML(base: normal, ["a": linkStyle])),
            for: .normal)

        return button
    }
}
