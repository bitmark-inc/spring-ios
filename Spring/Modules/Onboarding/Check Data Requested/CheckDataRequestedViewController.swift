//
//  CheckDataRequestedViewController.swift
//  Spring
//
//  Created by thuyentruong on 11/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout
import RxSwift
import RxCocoa
import UserNotifications
import OneSignal

class CheckDataRequestedViewController: ViewController {

    // MARK: - Properties
    lazy var dataRequestedTitleLabel = makeDataRequestedTitleLabel()
    lazy var dataRequestedDescLabel = makeDataRequestedDescLabel()
    lazy var dataRequestedTimeDescLabel = makeDataRequestedTimeDescLabel()
    lazy var checkNowButton = makeCheckNowButton()
    lazy var viewInsightsButton = makeViewInsightsButton()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    // MARK: - bind ViewModel
    override func bindViewModel() {
        super.bindViewModel()
        
        guard let archiveCreatedAt = UserDefaults.standard.FBArchiveCreatedAt else {
            Global.log.error(AppError.emptyLocal)
            return
        }

        dataRequestedTimeDescLabel.setText(
            R.string.phrase.dataRequestedDescriptionTime(
                archiveCreatedAt.string(withFormat: Constant.TimeFormat.archive)))
        
        checkNowButton.rx.tap.bind { [weak self] in
            _ = connectedToInternet()
                .subscribe(onCompleted: { [weak self] in
                    self?.gotoDownloadFBArchiveScreen()
                })
        }.disposed(by: disposeBag)

        viewInsightsButton.rx.tap.bind { [weak self] in
            self?.gotoMainScreen()
        }.disposed(by: disposeBag)
    }

    // MARK: - setup Views
    override func setupViews() {
        super.setupViews()

        let thumbImage = ImageView(image: R.image.hedgehogs())
        thumbImage.contentMode = .scaleAspectFill

        view.addSubview(thumbImage)
        thumbImage.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.5)
        }

        super.setupViews()

        contentView.flex
            .padding(OurTheme.paddingInset)
            .direction(.column).define { (flex) in
                flex.addItem().height(45%)

                flex.addItem(dataRequestedTitleLabel).marginTop(Size.dh(45))
                flex.addItem(dataRequestedDescLabel).marginTop(Size.dh(15))
                flex.addItem(dataRequestedTimeDescLabel).marginTop(Size.dh(10))
                
                flex.addItem()
                    .define({ (flex) in
                        flex.addItem(checkNowButton)
                        flex.addItem(viewInsightsButton).marginTop(Size.dh(19))
                    })
                    .width(100%)
                    .position(.absolute)
                    .left(OurTheme.paddingInset.left)
                    .bottom(OurTheme.paddingBottom)
            }
    }
}

// MARK: - Navigator
extension CheckDataRequestedViewController {
    func gotoDownloadFBArchiveScreen() {
        let viewModel = RequestDataViewModel(missions: [.getCategories, .downloadData])
        navigator.show(segue: .requestData(viewModel: viewModel), sender: self)
    }

    func gotoMainScreen() {
        navigator.show(segue: .hometabs(isArchiveStatusBoxShowed: false),
                       sender: self, transition: .replace(type: .auto))
    }
}

extension CheckDataRequestedViewController {
    fileprivate func makeDataRequestedTitleLabel() -> Label {
        let label = Label()
        label.apply(
            text: R.string.phrase.dataRequestedScreenTitle().localizedUppercase,
            font: R.font.domaineSansTextLight(size: Size.ds(36)), colorTheme: .black)
        return label
    }
    
    fileprivate func makeDataRequestedDescLabel() -> Label {
        let label = Label()
        label.numberOfLines = 0
        label.apply(
            text: R.string.phrase.dataRequestedDescription(),
            font: R.font.atlasGroteskLight(size: Size.ds(18)),
            colorTheme: .black, lineHeight: 1.2)
        return label
    }
    
    fileprivate func makeCheckNowButton() -> SubmitButton {
        let submitButton = SubmitButton(title: R.string.localizable.check_now())
        submitButton.applyTheme(colorTheme: .cognac)
        return submitButton
    }

    fileprivate func makeViewInsightsButton() -> Button {
        let button = Button()
        button.apply(
            title: R.string.localizable.view_insights(),
            font: R.font.atlasGroteskLight(size: Size.ds(14)),
            colorTheme: .cognac)
        return button
    }

    fileprivate func makeDataRequestedTimeDescLabel() -> Label {
        let label = Label()
        label.numberOfLines = 0
        label.apply(
            text: R.string.phrase.dataRequestedCheckDescription(),
            font: R.font.atlasGroteskThinItalic(size: Size.ds(18)),
            colorTheme: .black, lineHeight: 1.2)
        return label
    }
}
