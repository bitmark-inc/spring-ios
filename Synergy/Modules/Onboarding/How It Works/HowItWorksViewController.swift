//
//  HowItWorksViewController.swift
//  Synergy
//
//  Created by thuyentruong on 11/19/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class HowItWorksViewController: ViewController, BackNavigator {

    // MARK: - Properties
    lazy var continueButton = makeContinueButton()

    override func bindViewModel() {
        super.bindViewModel()

        continueButton.rx.tap.bind { [weak self] in
            self?.gotoTrustIsCriticalScreen()
        }.disposed(by: disposeBag)
    }

    override func setupViews() {
        let thumbImage = ImageView(image: R.image.howItWorksThumb())
        let blackView = UIView()
        blackView.backgroundColor = .black

        blackView.addSubview(thumbImage)
        thumbImage.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.height.equalToSuperview().offset(-40)
            $0.bottom.equalToSuperview().offset(-10)
        }

        view.addSubview(blackView)
        blackView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.5)
        }

        super.setupViews()

        let lightBackItem = makeLightBackItem()

        let howItWorksTitle = Label()
        howItWorksTitle.applyBlack(
            text: R.string.phrase.howitworksTitle().localizedUppercase,
            font: R.font.domaineSansTextLight(size: Size.ds(36)))

        contentView.flex
            .padding(OurTheme.paddingInset)
            .direction(.column).define { (flex) in
                flex.addItem(lightBackItem)
                flex.addItem().height(45%)

                flex.addItem(howItWorksTitle).marginTop(Size.dh(15))

                flex.addItem(howItWorkContent(part: 1, text: R.string.phrase.howitworksContent1())).marginTop(Size.dh(15))
                flex.addItem(howItWorkContent(part: 2, text: R.string.phrase.howitworksContent2())).marginTop(Size.dh(10))
                flex.addItem(howItWorkContent(part: 3, text: R.string.phrase.howitworksContent3())).marginTop(Size.dh(10))

                flex.addItem(continueButton)
                    .width(100%)
                    .position(.absolute)
                    .left(OurTheme.paddingInset.left)
                    .bottom(OurTheme.paddingBottom)
            }
    }
}

// MARK: - Navigator
extension HowItWorksViewController {
    func gotoTrustIsCriticalScreen() {
        let viewModel = TrustIsCriticalViewModel()
        navigator.show(segue: .trustIsCritical(viewModel: viewModel), sender: self)
    }
}

extension HowItWorksViewController {
    fileprivate func makeContinueButton() -> Button {
        return SubmitButton(title: R.string.localizable.continue())
    }

    fileprivate func howItWorkContent(part: Int, text: String) -> UIView {
        let partIndexLabel = Label()
        partIndexLabel.applyBlack(
            text: String(part),
            font: R.font.atlasGroteskLight(size: Size.ds(14)))

        let textLabel = Label()
        textLabel.numberOfLines = 0
        textLabel.applyBlack(
            text: text,
            font: R.font.atlasGroteskLight(size: Size.ds(18)),
            lineHeight: 1.2)

        let view = UIView()
        view.flex.direction(.row).define { (flex) in
            flex.addItem(partIndexLabel).width(Size.dw(18)).height(Size.dh(24))
            flex.addItem(textLabel)
        }
        return view
    }
}
