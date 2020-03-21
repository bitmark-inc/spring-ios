//
//  TrustIsCriticalViewController.swift
//  Spring
//
//  Created by Thuyen Truong on 12/11/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout
import SwiftRichString

class TrustIsCriticalViewController: ViewController, BackNavigator {

    // MARK: - Properties
    lazy var scroll = UIScrollView()
    lazy var scrollContentView = UIView()
    lazy var screenTitle = makeScreenTitle()
    lazy var trustContentView = makeTrustContentView()
    lazy var continueButton = makeContinueButton()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        continueButton.rx.tap.bind { [weak self] in
            self?.gotoHowItWorksScreen()
        }.disposed(by: disposeBag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scroll.contentSize = scrollContentView.frame.size
    }

    override func setupViews() {
        super.setupViews()

        var blackBackItem: Button?
        if buttonItemType == .back {
            blackBackItem = makeBlackBackItem()
        }

        scrollContentView.flex.define { (flex) in
            flex.addItem(trustContentView)
        }

        scroll.addSubview(scrollContentView)

        contentView.flex
            .padding(OurTheme.paddingInset)
            .direction(.column).define { (flex) in
                if let blackBackItem = blackBackItem {
                    flex.addItem(blackBackItem)
                }

                flex.addItem(screenTitle).margin(OurTheme.titlePaddingIgnoreBack)
                flex.addItem(scroll).grow(1).height(0)
                flex.addItem().height(100)

                flex.addItem(continueButton)
                    .width(100%)
                    .position(.absolute)
                    .left(OurTheme.paddingInset.left)
                    .bottom(OurTheme.paddingBottom)
            }
    }
}

// MARK: - UITextViewDelegate
extension TrustIsCriticalViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {

        navigator.show(segue: .safariController(URL), sender: self, transition: .alert)
        return false
    }
}

// MARK: - Navigator
extension TrustIsCriticalViewController {
    func gotoHowItWorksScreen() {
        navigator.show(segue: .howItWorks, sender: self)
    }
}

extension TrustIsCriticalViewController {
    fileprivate func makeScreenTitle() -> Label {
        let titleScreen = Label()
        titleScreen.apply(
            text: R.string.phrase.trustIsCriticalTitle().localizedUppercase,
            font: R.font.domaineSansTextLight(size: 34),
            colorTheme: .black)
        return titleScreen
    }

    fileprivate func makeTrustContentView() -> UIView {
        let contentLabel = Label()
        contentLabel.numberOfLines = 0
        contentLabel.apply(
            text: R.string.phrase.trustIsCriticalDescription(),
            font: R.font.atlasGroteskLight(size: 18),
            colorTheme: .black, lineHeight: 1.32)

        let subDescriptionLabel = ReadingTextView()
        subDescriptionLabel.attributedText = makeDescriptionText1()
        subDescriptionLabel.delegate = self
        subDescriptionLabel.linkTextAttributes = [
            .foregroundColor: UIColor.black
        ]

        let sincerelyLabel = Label()
        sincerelyLabel.apply(
            text: R.string.phrase.trustIsCriticalSincerely(),
            font: R.font.atlasGroteskLight(size: 18),
            colorTheme: .black)

        let seanSignature = ImageView(image: R.image.sean_sig())
        seanSignature.contentMode = .left

        let seanTitleLabel = Label()
        seanTitleLabel.numberOfLines = 0
        seanTitleLabel.apply(
            text: R.string.phrase.trustIsCriticalTitleSignature(),
            font: R.font.atlasGroteskLight(size: 18),
            colorTheme: .black, lineHeight: 1.32)

        let view = UIView()
        view.flex.alignSelf(.start).define { (flex) in
            flex.addItem(contentLabel)
            flex.addItem(subDescriptionLabel).marginTop(27)
            flex.addItem(sincerelyLabel).marginTop(Size.dh(50))
            flex.addItem(seanSignature)
            flex.addItem(seanTitleLabel)
        }

        return view
    }

    fileprivate func makeDescriptionText1() -> NSAttributedString {
        let normal = Style {
            $0.font = R.font.atlasGroteskLight(size: 18)
            $0.color = UIColor.black
        }

        let linkStyle = normal.byAdding {
            $0.linkURL = AppLink.faq.websiteURL
            $0.underline = (.single, UIColor.black)
        }

        return R.string.phrase.trustIsCriticalDescription1()
            .set(style: StyleXML(base: normal, ["a": linkStyle]))
    }

    fileprivate func makeContinueButton() -> Button {
        let submitButton = SubmitButton(title: R.string.localizable.continueArrow())
        submitButton.applyTheme(colorTheme: .cognac)
        return submitButton
    }
}
