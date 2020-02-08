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
            self?.gotoRequestDataScreen()
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

        var lightBackItem: Button?

        if let navigationController = self.navigationController,
            navigationController.viewControllers.count > 1 {
            lightBackItem = makeLightBackItem()
        }

        let howItWorksTitle = Label()
        howItWorksTitle.apply(
            text: R.string.phrase.howitworksTitle().localizedUppercase,
            font: R.font.domaineSansTextLight(size: Size.ds(36)),
            colorTheme: .black)

        contentView.flex
            .padding(OurTheme.paddingInset)
            .direction(.column).define { (flex) in
                if let lightBackItem = lightBackItem {
                    flex.addItem(lightBackItem)
                    flex.addItem().height(45%)
                } else {
                    flex.addItem().height(50%)
                }

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
    func gotoRequestDataScreen() {
        let viewModel = RequestDataViewModel(missions: [.requestData, .getCategories])
        navigator.show(segue: .requestData(viewModel: viewModel), sender: self)
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
            font: R.font.atlasGroteskLight(size: Size.ds(14)),
            colorTheme: .black)

        let textLabel = Label()
        textLabel.numberOfLines = 0
        textLabel.apply(
            text: text,
            font: R.font.atlasGroteskLight(size: Size.ds(18)),
            colorTheme: .black, lineHeight: 1.2)

        let view = UIView()
        view.flex.direction(.row).define { (flex) in
            flex.addItem(partIndexLabel).width(Size.dw(18)).height(Size.dh(24))
            flex.addItem(textLabel)
        }
        return view
    }
}
