//
//  UsageViewController.swift
//  Spring
//
//  Created by Anh Nguyen on 11/25/19.
//  Copyright © 2019 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import FlexLayout
import Intercom

class AccountViewController: ViewController, BackNavigator {

    // MARK: - Properties
    lazy var scroll = UIScrollView()
    lazy var settingsView = UIView()

    lazy var screenTitle = makeScreenTitle()

    // *** Section - Account
    lazy var updateFacebookArchiveButton = makeOptionButton(title: R.string.phrase.accountSettingsAccountUpdateFacebookArchive())
    lazy var deleteAccountButton = makeOptionButton(title: R.string.phrase.accountSettingsAccountDeleteAccount())
    lazy var signOutOptionButton = makeOptionButton(title: R.string.phrase.accountSettingsAccountSignOut())
    lazy var recoveryKeyOptionButton = makeOptionButton(title: R.string.phrase.accountSettingsAccountRecoveryKey())

    // *** Section - Security
    lazy var biometricAuthOptionButton = makeBiometricAuthOptionButton()
    lazy var increasePrivacyButton = makeOptionButton(title: R.string.phrase.accountSettingsSecurityIncreasePrivacy())

    // *** Section - Development
    lazy var personalAPIOptionButton = makeOptionButton(title: R.string.phrase.accountSettingsDevelopmentPersonalAPI())
    lazy var sourceCodeOptionButton = makeOptionButton(title: R.string.phrase.accountSettingsDevelopmentSourceCode())

    // *** Section - Support
    lazy var faqOptionButton = makeOptionButton(title: R.string.phrase.accountSettingsSupportFaq())
    lazy var whatsNewButton = makeOptionButton(title: R.string.phrase.accountSettingsSupportWhatsNew())
    lazy var contactOptionButton = makeOptionButton(title: R.string.phrase.accountSettingsSupportContact())

    lazy var versionLabel = makeVersionLabel()
    lazy var bitmarkCertView = makeBitmarkCertView()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        } else {
            return .default
        }
    }

    override func bindViewModel() {
        super.bindViewModel()

        AppArchiveStatus.currentState
            .mapHighestStatus()
            .map { (appArchiveStatus) -> Bool in
                return appArchiveStatus == .processed // only enable when at least one archive is proccessed
            }
            .bind(to: updateFacebookArchiveButton.rx.isEnabled)
            .disposed(by: disposeBag)

        updateFacebookArchiveButton.rx.tap.bind { [weak self] in
            self?.gotoUpdateYourDataScreen()
        }.disposed(by: disposeBag)

        signOutOptionButton.rx.tap.bind { [weak self] in
            self?.gotoSignOutFlow()
        }.disposed(by: disposeBag)

        biometricAuthOptionButton?.rx.tap.bind { [weak self] in
            self?.gotoBiometricAuthFlow()
        }.disposed(by: disposeBag)

        recoveryKeyOptionButton.rx.tap.bind { [weak self] in
            self?.gotoViewRecoveryKeyFlow()
        }.disposed(by: disposeBag)

        deleteAccountButton.rx.tap.bind { [weak self] in
            self?.gotoDeleteAccountScreen()
        }.disposed(by: disposeBag)

        increasePrivacyButton.rx.tap.bind { [weak self] in
            self?.gotoIncreasePrivacyListScreen()
        }.disposed(by: disposeBag)

        personalAPIOptionButton.rx.tap.bind { [weak self] in
            self?.gotoPersonalAPIScreen()
        }.disposed(by: disposeBag)

        sourceCodeOptionButton.rx.tap.bind { [weak self] in
            self?.gotoSourceCodeScreen()
        }.disposed(by: disposeBag)

        faqOptionButton.rx.tap.bind { [weak self] in
            self?.gotoFAQScreen()
        }.disposed(by: disposeBag)

        whatsNewButton.rx.tap.bind { [weak self] in
            self?.gotoReleaseNoteScreen()
        }.disposed(by: disposeBag)

        contactOptionButton.rx.tap.bind { [weak self] in
            self?.showIntercomContact()
        }.disposed(by: disposeBag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scroll.contentSize = settingsView.frame.size
    }

    override func setupViews() {
        super.setupViews()
        let securityButtonGroup: [Button]!

        if let biometricAuthOptionButton = biometricAuthOptionButton {
            securityButtonGroup = [biometricAuthOptionButton, increasePrivacyButton]
        } else {
            securityButtonGroup = [increasePrivacyButton]
        }

        settingsView.flex.define { (flex) in
            flex.addItem(screenTitle)
                .marginLeft(18)
                .margin(30, 18, 0, 18)

            flex.addItem(
                makeOptionsSection(
                    name: R.string.phrase.accountSettingsAccount(),
                    options: [updateFacebookArchiveButton, signOutOptionButton, recoveryKeyOptionButton]))
                .marginTop(12)

            flex.addItem(
                makeOptionsSection(
                    name: R.string.phrase.accountSettingsSecurity(),
                    options: securityButtonGroup))
                .marginTop(12)

            flex.addItem(
                makeOptionsSection(
                    name: R.string.phrase.accountSettingsDevelopment(),
                    options: [personalAPIOptionButton, sourceCodeOptionButton]))
                .marginTop(12)

            flex.addItem(
                makeOptionsSection(
                    name: R.string.phrase.accountSettingsSupport(),
                    options: [whatsNewButton, faqOptionButton, contactOptionButton]))
                .marginTop(12)

            flex.addItem(bitmarkCertView)
                .paddingBottom(22).paddingTop(22)
        }

        scroll.addSubview(settingsView)
        contentView.flex
            .direction(.column).define { (flex) in
                flex.addItem(scroll).height(0).grow(1)
            }
    }
}

// MARK: - Navigator
extension AccountViewController {
    fileprivate func gotoUpdateYourDataScreen() {
        let viewModel = UpdateYourDataViewModel()
        navigator.show(segue: .updateYourData(viewModel: viewModel), sender: self)
    }

    fileprivate func gotoSignOutFlow() {
        navigator.show(segue: .signOutWarning, sender: self)
    }

    fileprivate func gotoBiometricAuthFlow() {
        navigator.show(segue: .biometricAuth, sender: self)
    }

    fileprivate func gotoViewRecoveryKeyFlow() {
        navigator.show(segue: .viewRecoveryKeyWarning, sender: self)
    }

    fileprivate func gotoDeleteAccountScreen() {
        let viewModel = DeleteAccountViewModel()
        navigator.show(segue: .deleteAccount(viewModel: viewModel), sender: self)
    }

    fileprivate func gotoIncreasePrivacyListScreen() {
        navigator.show(segue: .increasePrivacyList, sender: self)
    }

    fileprivate func gotoFAQScreen() {
        guard let url = AppLink.faq.websiteURL else { return }
        navigator.show(segue: .safariController(url), sender: self, transition: .alert)
    }

    fileprivate func gotoReleaseNoteScreen() {
        navigator.show(segue: .releaseNote(buttonItemType: .back), sender: self)
    }

    fileprivate func showIntercomContact() {
        Intercom.presentMessenger()
    }

    fileprivate func gotoPersonalAPIScreen() {
        guard let url = AppLink.personalAPI.websiteURL else { return }
        navigator.show(segue: .safariController(url), sender: self, transition: .alert)
    }

    fileprivate func gotoSourceCodeScreen() {
        guard let url = AppLink.sourceCode.websiteURL else { return }
        navigator.show(segue: .safariController(url), sender: self, transition: .alert)
    }
 }

// MARK: UITextViewDelegate
extension AccountViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard URL.scheme != nil, let host = URL.host else {
            return false
        }

        guard let appLink = AppLink(rawValue: host),
            let appLinkURL = appLink.websiteURL
        else {
            return true
        }

        navigator.show(segue: .safariController(appLinkURL), sender: self, transition: .alert)
        return true
    }
}

extension AccountViewController {
    fileprivate func makeScreenTitle() -> Label {
        let label = Label()
        label.apply(
            text: R.string.phrase.accountSettingsTitle().localizedUppercase,
            font: R.font.domaineSansTextLight(size: 36),
            colorTheme: .yukonGold)
        return label
    }

    fileprivate func makeOptionsSection(name: String, options: [Button]) -> UIView {
        let nameSectionLabel = Label()
        nameSectionLabel.apply(
            text: name.localizedUppercase,
            font: R.font.atlasGroteskLight(size: 24),
            colorTheme: .black)

        let sectionView = UIView()
        themeService.rx
            .bind({ $0.sectionBackgroundColor }, to: sectionView.rx.backgroundColor)
            .disposed(by: disposeBag)

        sectionView.flex
            .padding(UIEdgeInsets(top: 18, left: OurTheme.paddingInset.left, bottom: 18, right: OurTheme.paddingInset.right))
            .direction(.column).define { (flex) in
                flex.addItem(nameSectionLabel).marginBottom(5)
                options.forEach { flex.addItem($0).marginTop(15) }
            }

        return sectionView
    }

    fileprivate func makeOptionButton(title: String) -> Button {
        let button = Button()
        button.apply(
            title: title,
            font: R.font.atlasGroteskThin(size: 18),
            colorTheme: .black)
        button.contentHorizontalAlignment = .leading
        button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 0, bottom: 2, right: 0)
        return button
    }

    fileprivate func makeBiometricAuthOptionButton() -> Button? {
        let currentDeviceEvaluatePolicyType = BiometricAuth.currentDeviceEvaluatePolicyType()

        guard currentDeviceEvaluatePolicyType != .none else { return nil }
        let title = R.string.phrase.accountSettingsSecurityBiometricAuth(currentDeviceEvaluatePolicyType.text)
        return makeOptionButton(title: title)
    }

    fileprivate func makeBitmarkCertView() -> UIView {
        let view = UIView()
        view.flex.alignItems(.center)
            .define { (flex) in
                flex.addItem(versionLabel)
                flex.addItem(makeEulaAndPolicyTextView()).marginTop(7)
                flex.addItem(ImageView(image: R.image.securedByBitmark())).marginTop(9)
            }
        return view
    }

    fileprivate func makeVersionLabel() -> Label {
        let label = Label()
        label.apply(
            text: R.string.phrase.releaseNoteAppVersion(UserDefaults.standard.appVersion ?? "--"),
            font: R.font.atlasGroteskLight(size: 14), colorTheme: .black)
        return label
    }

    fileprivate func makeEulaAndPolicyTextView() -> UITextView {
        let textView = ReadingTextView()
        textView.apply(colorTheme: .black)
        textView.isScrollEnabled = false
        textView.delegate = self
        textView.linkTextAttributes = [
          .foregroundColor: themeService.attrs.blackTextColor
        ]

        textView.attributedText = LinkAttributedString.make(
            string: R.string.phrase.termsAndPolicyPhrase(
                AppLink.eula.generalText,
                AppLink.privacyOfPolicy.generalText),
            attributes: [
                .font: R.font.atlasGroteskLight(size: 12)!,
                .foregroundColor: themeService.attrs.blackTextColor
            ], links: [
                (text: AppLink.eula.generalText, url: AppLink.eula.path),
                (text: AppLink.privacyOfPolicy.generalText, url: AppLink.privacyOfPolicy.path)
            ], linkAttributes: [
                .font: R.font.atlasGroteskLightItalic(size: 12)!,
                .underlineColor: themeService.attrs.blackTextColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ])

        return textView
    }
}
