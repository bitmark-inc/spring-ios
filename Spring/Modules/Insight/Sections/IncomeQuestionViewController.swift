//
//  IncomeQuestionViewController.swift
//  Spring
//
//  Created by Thuyen Truong on 1/21/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout
import SwiftRichString

class IncomeQuestionViewController: ViewController, BackNavigator {

    // MARK: - Properties
    lazy var scroll = UIScrollView()
    lazy var mainView = UIView()
    lazy var screenTitle = makeScreenTitle()
    lazy var attributedDescriptionTextView = makeAttributedDescriptionTextView()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scroll.contentSize = mainView.frame.size
    }

    override func setupViews() {
        super.setupViews()

        let blackBackItem = makeBlackBackItem()

        mainView.flex
            .padding(OurTheme.paddingInset)
            .define { (flex) in
                flex.addItem(blackBackItem)
                flex.addItem(screenTitle).margin(OurTheme.titlePaddingInset)
                flex.addItem(attributedDescriptionTextView)
        }

        scroll.addSubview(mainView)
        contentView.flex
            .direction(.column).define { (flex) in
                flex.addItem(scroll).height(100%)
        }
    }
}

// MARK: - Setup Views
extension IncomeQuestionViewController {
    fileprivate func makeScreenTitle() -> Label {
        let label = Label()
        label.apply(
            text: R.string.phrase.incomeQuestionTitle().localizedUppercase,
            font: R.font.domaineSansTextLight(size: 28),
            colorTheme: OurTheme.accountColorTheme, lineHeight: 1.056)
        label.numberOfLines = 0
        return label
    }

    fileprivate func makeAttributedDescriptionTextView() -> UITextView {
        let normal = Style {
            $0.font = R.font.atlasGroteskLight(size: 22)
            $0.color = themeService.attrs.tundoraTextColor
        }

        let textView = ReadingTextView()
        textView.apply(colorTheme: .tundora)
        textView.isScrollEnabled = false
        textView.attributedText = R.string.phrase.incomeQuestionDescription().set(style: StyleXML(base: normal))
        return textView
    }
}
