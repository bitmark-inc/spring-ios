//
//  GetYourDataInstructionViewController.swift
//  Spring
//
//  Created by Thuyen Truong on 2/28/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class GetYourDataInstructionViewController: ViewController, BackNavigator {

    // MARK: - Properties
    lazy var screenTitle = makeScreenTitle()
    lazy var descriptionView = makeDescriptionView()
    lazy var scrollView = makeScrollDescriptionView()
    lazy var continueButton = makeContinueButton()

    override func bindViewModel() {
        super.bindViewModel()

        continueButton.rx.tap.bind { [weak self] in
            self?.moveToFBDownloadPage()
        }.disposed(by: disposeBag)
    }

    override func setupViews() {
        super.setupViews()

        let blackBackItem = makeBlackBackItem()
                                                                                                 
        contentView.flex
            .padding(OurTheme.paddingInset)
            .define { (flex) in
                flex.addItem(blackBackItem)
                flex.addItem(screenTitle).padding(OurTheme.accountPaddingScreenTitleInset)
                flex.addItem(scrollView).height(1).grow(1)

                flex.addItem(continueButton)
                    .width(100%)
                    .position(.absolute)
                    .left(OurTheme.paddingInset.left)
                    .bottom(OurTheme.paddingBottom)
            }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = CGSize(width: UIScreen.main.bounds.width - 36, height: descriptionView.frame.size.height)
    }

    fileprivate func moveToFBDownloadPage() {
        guard let FBDownloadURL = URL(string: "https://m.facebook.com/dyi") else { return }
        navigator.show(segue: .safariController(FBDownloadURL), sender: self, transition: .alert)
    }
}

extension GetYourDataInstructionViewController {
    fileprivate func makeScreenTitle() -> Label {
        let label = Label()
        label.applyTitleTheme(
            text: R.string.phrase.instructionGetYourDataTitle().localizedUppercase,
            colorTheme: OurTheme.usageColorTheme)
        return label
    }

    fileprivate func makeScrollDescriptionView() -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false

        scrollView.flex.define { (flex) in
            flex.addItem(descriptionView).width(100%)

        }
        return scrollView
    }

    fileprivate func makeDescriptionView() -> UIView {
        let instructionImageView = UIImageView(image: R.image.getYourDataInstruction())
        instructionImageView.contentMode = .scaleToFill

        let view = UIView()
        view.flex.define { (flex) in
            flex.addItem(instructionImageView).grow(1)
            flex.addItem().height(160)
        }

        return view
    }

    fileprivate func makeContinueButton() -> Button {
        let submitButton = SubmitButton(title: R.string.localizable.downloadArrow())
        submitButton.applyTheme(colorTheme: .mercury)
        return submitButton
    }
}
