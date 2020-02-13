//
//  SignOutViewController.swift
//  Spring
//
//  Created by Thuyen Truong on 12/13/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout
import SwiftEntryKit

class SignOutViewController: ConfirmRecoveryKeyViewController, BackNavigator {

    // MARK: - Properties
    lazy var screenTitle = makeScreenTitle()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? SignOutViewModel else { return }
        viewModel.signOutAccountResultSubject
            .subscribe(onNext: { [weak self] (event) in
                guard let self = self else { return }
                switch event {
                case .error(let error):
                    self.errorWhenSignOutAccount(error: error)
                case .completed:
                    Global.log.info("[done] signOut Account")
                    self.showSignOutSuccessNotify(attributes: Global.infoEKAttributes)
                default:
                    break
                }
            }).disposed(by: disposeBag)

        submitButton.rx.tap.bind {
            viewModel.signOutAccount()
        }.disposed(by: disposeBag)
    }

    private func showSignOutSuccessNotify(attributes: EKAttributes) {
        var attributes = attributes
        attributes.lifecycleEvents.didDisappear = { [weak self] in
            self?.gotoOnboardingScreen()
        }

        let title = EKProperty.LabelContent(
            text: R.string.phrase.signOutSuccessTitle().localizedUppercase,
            style: EKProperty.LabelStyle(font: R.font.atlasGroteskLight(size: 22)!, color: EKColor(.black)))

        let description = EKProperty.LabelContent(
            text: R.string.phrase.signOutSuccessDescription(),
            style: EKProperty.LabelStyle(font: R.font.atlasGroteskLight(size: 18)!, color: EKColor(ColorTheme.tundora.color)))

        let simpleMessage = EKSimpleMessage(title: title, description: description)
        let notificationMessage = EKNotificationMessage(simpleMessage: simpleMessage)

        let contentView = EKNotificationMessageView(with: notificationMessage)
        SwiftEntryKit.display(entry: contentView, using: attributes)
    }

    // MARK: - Error Handlers
    func errorWhenSignOutAccount(error: Error) {
        if let error = error as? AccountError, error == .invalidRecoveryKey {
            errorRecoveryKeyView.isHidden = false
            recoveryKeyTextView.textColor = ColorTheme.internationalKleinBlue.color
            return
        }

        Global.log.error(error)
        showErrorAlertWithSupport(message: R.string.error.accountSignOutError())
    }

    override func setupViews() {
        super.setupViews()

        let blackBackItem = makeBlackBackItem()

        var paddingScreenTitleInset = OurTheme.accountPaddingScreenTitleInset
        paddingScreenTitleInset.bottom = 10

        submitButton.setTitle(R.string.phrase.accountSignOutSubmitTitle(), for: .normal)

        contentView.flex
            .padding(OurTheme.paddingInset)
            .direction(.column)
            .define { (flex) in
                flex.addItem().define { (flex) in
                    flex.addItem(blackBackItem)
                    flex.addItem(screenTitle).margin(paddingScreenTitleInset)
                    flex.addItem(recoveryKeyView)
                }

                flex.addItem()
                    .width(100%)
                    .position(.absolute)
                    .left(OurTheme.paddingInset.left)
                    .bottom(OurTheme.paddingBottom)
                    .define { (flex) in
                        flex.addItem(errorRecoveryKeyView)
                        flex.addItem(submitButton).marginTop(24)
                    }
            }
    }
}

// MARK: - Navigator
extension SignOutViewController {
    fileprivate func gotoOnboardingScreen() {
        let viewModel = SignInWallViewModel()
        navigator.show(segue: .signInWall(viewModel: viewModel), sender: self, transition: .replace(type: .none))
    }
}

extension SignOutViewController {
    fileprivate func makeScreenTitle() -> Label {
        let label = Label()
        label.applyTitleTheme(
            text: R.string.phrase.accountSignOutTitle().localizedUppercase,
            colorTheme: OurTheme.accountColorTheme)
        return label
    }
}
