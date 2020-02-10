//
//  DeleteAccountViewController.swift
//  Spring
//
//  Created by Thuyen Truong on 2/10/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout

class DeleteAccountViewController: ViewController, BackNavigator {

    // MARK: - Properties
    lazy var screenTitle = makeScreenTitle()
    lazy var descriptionTextView = makeDescriptionTextView()
    lazy var deleteButton = makeDeleteButton()
    fileprivate var lockTextViewClick: Bool = false // for unknown reason, textview delegate function call more than 1 times

    lazy var thisViewModel = {
        return self.viewModel as! DeleteAccountViewModel
    }()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? DeleteAccountViewModel else { return }

        viewModel.deleteAccountResultSubject
            .subscribe(onNext: { [weak self] (event) in
                loadingState.onNext(.hide)
                guard let self = self else { return }
                switch event {
                case .error(let error):
                    self.errorWhenDeleteAccount(error: error)
                case .completed:
                    Global.log.info("[done] delete Account")
                    self.gotoOnboardingScreen()
                default:
                    break
                }
            }).disposed(by: disposeBag)

        deleteButton.rx.tap.bind { [weak self] in
            self?.makeDeleteAccountConfirmationAlert().show()
        }.disposed(by: disposeBag)
    }

    // MARK: - Error Handlers
    func errorWhenDeleteAccount(error: Error) {
        Global.log.error(error)
        showErrorAlertWithSupport(message: R.string.error.system())
    }

    override func setupViews() {
        super.setupViews()

        let blackBackItem = makeBlackBackItem()

        contentView.flex
            .padding(OurTheme.paddingInset)
            .direction(.column)
            .define { (flex) in
                flex.addItem(blackBackItem)
                flex.addItem(screenTitle).padding(OurTheme.accountPaddingScreenTitleInset)
                flex.addItem(descriptionTextView)

                flex.addItem(deleteButton)
                    .width(100%)
                    .position(.absolute)
                    .left(OurTheme.paddingInset.left)
                    .bottom(OurTheme.paddingBottom)
            }
    }
}

// MARK: - UITextViewDelegate
extension DeleteAccountViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard !lockTextViewClick else { return false }
        lockTextViewClick = true

        guard URL.scheme != nil, let host = URL.host else {
            lockTextViewClick = false
            return false
        }

        switch host {
        case AppLink.exportData.rawValue:
            //TODO: do export data
            break
        default:
            lockTextViewClick = false
            return false
        }
        return true
    }
}

// MARK: - Navigator
extension DeleteAccountViewController {
    fileprivate func gotoOnboardingScreen() {
        let viewModel = SignInWallViewModel()
        navigator.show(segue: .signInWall(viewModel: viewModel), sender: self, transition: .replace(type: .none))
    }
}

// MARK: - Setup views
extension DeleteAccountViewController {
    fileprivate func makeScreenTitle() -> Label {
        let label = Label()
        label.applyTitleTheme(
            text: R.string.phrase.accountDeleteAccountTitle().localizedUppercase,
            colorTheme: OurTheme.accountColorTheme)
        return label
    }

    fileprivate func makeDescriptionTextView() -> UITextView {
        let linkToExportDataText = R.string.phrase.accountDeleteAccountExportData()
        let description = R.string.phrase.accountDeleteAccountDescription(linkToExportDataText)

        let attributedDescription = LinkAttributedString.make(
            string: description,
            lineHeight: 1.32,
            attributes: [
                .font: R.font.atlasGroteskThin(size: Size.ds(22))!,
                .foregroundColor: themeService.attrs.tundoraTextColor
            ],
            links: [
                (text: linkToExportDataText, url: AppLink.exportData.path)
            ],
            linkAttributes: [
              .underlineColor: themeService.attrs.tundoraTextColor,
              .underlineStyle: NSUnderlineStyle.single.rawValue,
              .foregroundColor: themeService.attrs.tundoraTextColor
            ])

        let textView = ReadingTextView()
        textView.apply(colorTheme: .black)
        textView.delegate = self
        textView.linkTextAttributes = [
          .foregroundColor: themeService.attrs.tundoraTextColor
        ]
        textView.attributedText = attributedDescription
        return textView
    }

    fileprivate func makeDeleteButton() -> Button {
        let submitButton = SubmitButton(title: R.string.phrase.accountDeleteAccountAction())
        submitButton.applyTheme(colorTheme: .mercury)
        return submitButton
    }

    fileprivate func makeDeleteAccountConfirmationAlert() -> UIAlertController {
        let alertController = UIAlertController(
            title: R.string.phrase.deleteAccountConfirmationTitle(),
            message: R.string.phrase.deleteAccountConfirmationDescription(),
            preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: R.string.localizable.cancel(), style: .cancel, handler: nil)
        let confirmAction = UIAlertAction(title: R.string.localizable.confirm(), style: .destructive) { [weak self] (_) in
            guard let self = self else { return }
            BiometricAuth.authorizeAccess()
                .subscribe(onCompleted: { [weak self] in
                    loadingState.onNext(.loading)
                    self?.thisViewModel.deleteAccount()
                })
                .disposed(by: self.disposeBag)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(confirmAction)
        alertController.preferredAction = cancelAction
        return alertController
    }
}
