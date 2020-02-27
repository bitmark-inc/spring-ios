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

class TrustIsCriticalViewController: ViewController, BackNavigator {

    // MARK: - Properties
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

    override func setupViews() {
        super.setupViews()

        var blackBackItem: Button?
        if buttonItemType == .back {
            blackBackItem = makeBlackBackItem()
        }

        let titleScreen = Label()
        titleScreen.apply(
            text: R.string.phrase.trustIsCriticalTitle().localizedUppercase,
            font: R.font.domaineSansTextLight(size: 34),
            colorTheme: .black)
        
        let contentLabel = Label()
        contentLabel.numberOfLines = 0
        contentLabel.apply(
            text: R.string.phrase.trustIsCriticalDescription(),
            font: R.font.atlasGroteskLight(size: 18),
            colorTheme: .black, lineHeight: 1.32)

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

        contentView.flex
            .padding(OurTheme.paddingInset)
            .direction(.column).define { (flex) in
                if let blackBackItem = blackBackItem {
                    flex.addItem(blackBackItem)
                }

                flex.addItem(titleScreen).marginTop(OurTheme.trustIsCriticalTop)
                flex.addItem(contentLabel).marginTop(27)
                flex.addItem(sincerelyLabel).marginTop(Size.dh(50))
                flex.addItem(seanSignature)
                flex.addItem(seanTitleLabel)
                
                flex.addItem(continueButton)
                    .width(100%)
                    .position(.absolute)
                    .left(OurTheme.paddingInset.left)
                    .bottom(OurTheme.paddingBottom)
            }
    }
}

// MARK: - Navigator
extension TrustIsCriticalViewController {
    func gotoHowItWorksScreen() {
        let viewModel = HowItWorksViewModel()
        navigator.show(segue: .howItWorks(viewModel: viewModel), sender: self)
    }
}

extension TrustIsCriticalViewController {
    fileprivate func makeContinueButton() -> Button {
        let submitButton = SubmitButton(title: R.string.localizable.continueArrow())
        submitButton.applyTheme(colorTheme: .cognac)
        return submitButton
    }
}
