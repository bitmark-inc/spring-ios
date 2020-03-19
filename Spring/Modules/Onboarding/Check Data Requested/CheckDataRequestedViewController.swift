//
//  CheckDataRequestedViewController.swift
//  Spring
//
//  Created by thuyentruong on 11/26/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout

class CheckDataRequestedViewController: ViewController {

    // MARK: - Properties
    lazy var dataRequestedTitleLabel = makeDataRequestedTitleLabel()
    lazy var dataRequestedTimeDescLabel = makeDataRequestedTimeDescLabel()
    lazy var checkNowButton = makeCheckNowButton()

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
            guard let self = self else { return }
            connectedToInternet()
                .subscribe(onCompleted: { [weak self] in
                    self?.gotoMainScreenWithDownloadMission()
                })
                .disposed(by: self.disposeBag)
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
            make.height.equalToSuperview().multipliedBy(OurTheme.halfImagePercent)
        }

        super.setupViews()

        contentView.flex
            .padding(OurTheme.paddingInset)
            .direction(.column).define { (flex) in
                let imageSpace = (OurTheme.halfImagePercent - 0.05) * 100
                flex.addItem().height(imageSpace%)

                flex.addItem(dataRequestedTitleLabel).marginTop(Size.dh(45))
                flex.addItem(makeDataRequestedDescLabel()).marginTop(Size.dh(15))
                flex.addItem(dataRequestedTimeDescLabel).marginTop(10)

                flex.addItem(checkNowButton)
                    .width(100%)
                    .position(.absolute)
                    .left(OurTheme.paddingInset.left)
                    .bottom(OurTheme.paddingBottomWithSecondaryButton)
            }
    }
}

// MARK: - Navigator
extension CheckDataRequestedViewController {
    func gotoMainScreenWithDownloadMission() {
        navigator.show(segue: .hometabs(missions: [.downloadData]),
                       sender: self, transition: .replace(type: .auto))
    }
}

extension CheckDataRequestedViewController {
    fileprivate func makeDataRequestedTitleLabel() -> Label {
        let label = Label()
        label.apply(
            text: R.string.phrase.dataRequestedScreenTitle().localizedUppercase,
            font: R.font.domaineSansTextLight(size: 36), colorTheme: .black)
        return label
    }
    
    fileprivate func makeDataRequestedDescLabel() -> Label {
        let label = Label()
        label.numberOfLines = 0
        label.apply(
            text: R.string.phrase.dataRequestedCheckDescription(),
            font: R.font.atlasGroteskLight(size: 18),
            colorTheme: .black, lineHeight: 1.2)
        return label
    }
    
    fileprivate func makeCheckNowButton() -> SubmitButton {
        let submitButton = SubmitButton(title: R.string.localizable.check_now())
        submitButton.applyTheme(colorTheme: .cognac)
        return submitButton
    }

    fileprivate func makeDataRequestedTimeDescLabel() -> Label {
        let label = Label()
        label.numberOfLines = 0
        label.apply(
            font: R.font.atlasGroteskThinItalic(size: 18),
            colorTheme: .black, lineHeight: 1.2)
        return label
    }
}
