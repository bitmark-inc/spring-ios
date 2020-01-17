//
//  HowFBTrackViewController.swift
//  Spring
//
//  Created by Thuyen Truong on 1/17/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class HowFBTrackViewController: ViewController, BackNavigator {

    // MARK: - Properties
    lazy var screenTitle = makeScreenTitle()
    lazy var howFbTrackYouContentView = makeHowFBTrackContentTextView()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    override func setupViews() {
        super.setupViews()

        let blackBackItem = makeBlackBackItem()

        contentView.flex
            .padding(OurTheme.paddingInset)
            .define { (flex) in
                flex.addItem().define { (flex) in
                    flex.addItem(blackBackItem)
                    flex.addItem(screenTitle).margin(Size.dh(21), 0, Size.dh(20), 0)
                    flex.addItem(howFbTrackYouContentView)
                }
            }
    }
}

// MARK: - Setup Views
extension HowFBTrackViewController {
    fileprivate func makeScreenTitle() -> Label {
        let label = Label()
        label.applyTitleTheme(
            text: R.string.phrase.howFBTrackTitle().localizedUppercase,
            colorTheme: OurTheme.insightColorTheme)
        label.font = R.font.domaineSansTextLight(size: Size.ds(22))!
        return label
    }

    fileprivate func makeHowFBTrackContentTextView() -> UITextView {
        let textView = ReadingTextView()
        textView.text = R.string.phrase.howFBTrackContent()
        textView.font = R.font.atlasGroteskLight(size: Size.ds(12))
        return textView
    }
}
