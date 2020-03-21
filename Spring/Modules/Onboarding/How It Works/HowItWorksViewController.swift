//
//  HowItWorksViewController.swift
//  Spring
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

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func bindViewModel() {
        super.bindViewModel()

        continueButton.rx.tap.bind { [weak self] in
            self?.gotoUploadDataScreen()
        }.disposed(by: disposeBag)
    }

    fileprivate func errorWhenSignUp(error: Error) {
        guard !AppError.errorByNetworkConnection(error),
            !handleErrorIfAsAFError(error),
            !showIfRequireUpdateVersion(with: error) else {
                return
        }

        Global.log.error(error)
        showErrorAlertWithSupport(message: R.string.error.system())
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
        howItWorksTitle.apply(
            text: R.string.phrase.howitworksTitle().localizedUppercase,
            font: R.font.domaineSansTextLight(size: 36),
            colorTheme: .black)

        contentView.flex
            .padding(OurTheme.paddingInset)
            .direction(.column).define { (flex) in
                flex.addItem(lightBackItem)
                flex.addItem().height(45%)

                flex.addItem(howItWorksTitle).marginTop(15)

                flex.addItem().marginRight(20).define { (flex) in
                    flex.addItem(howItWorkContent(part: 1, text: R.string.phrase.howitworksContent1())).marginTop(15)
                    flex.addItem(howItWorkContent(part: 2, text: R.string.phrase.howitworksContent2())).marginTop(10)
                    flex.addItem(howItWorkContent(part: 3, text: R.string.phrase.howitworksContent3())).marginTop(10)
                }

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
    fileprivate func gotoUploadDataScreen() {
        let viewModel = UploadDataViewModel()
        navigator.show(segue: .uploadData(viewModel: viewModel), sender: self)
    }
}

extension HowItWorksViewController {
    fileprivate func makeContinueButton() -> Button {
        let submitButton = SubmitButton(title: R.string.localizable.continueArrow())
        submitButton.applyTheme(colorTheme: .cognac)
        return submitButton
    }

    fileprivate func howItWorkContent(part: Int, text: String) -> UIView {
        let partIndexLabel = Label()
        partIndexLabel.apply(
            text: String(part),
            font: R.font.atlasGroteskLight(size: 14),
            colorTheme: .black)

        let textLabel = Label()
        textLabel.numberOfLines = 0
        textLabel.apply(
            text: text,
            font: R.font.atlasGroteskLight(size: 18),
            colorTheme: .black, lineHeight: 1.2)

        let view = UIView()
        view.flex.direction(.row).define { (flex) in
            flex.addItem(partIndexLabel).width(18).height(26)
            flex.addItem(textLabel)
        }
        return view
    }
}
