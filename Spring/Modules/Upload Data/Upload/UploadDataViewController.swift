//
//  UploadDataViewController.swift
//  Spring
//
//  Created by Thuyen Truong on 2/26/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout
import RxSwift
import RxCocoa
import MobileCoreServices

class UploadDataViewController: ViewController, BackNavigator {

    // MARK: - Properties
    fileprivate lazy var scroll = UIScrollView()
    fileprivate lazy var scrollContentView = UIView()
    fileprivate lazy var screenTitle = makeScreenTitle()
    fileprivate lazy var instructionView = makeInstructionView()
    fileprivate lazy var uploadFileButton = makeUploadFileButton()
    fileprivate lazy var uploadDataView = makeUploadDataView()
    fileprivate lazy var provideURLTextField = makeProvideURLTextField()
    fileprivate lazy var uploadProgressView = makeUploadProgressView()

    fileprivate var lockTextViewClick: Bool = false
    let dyiFacebookPath = "https://m.facebook.com/dyi"

    lazy var thisViewModel = { viewModel as! UploadDataViewModel }()
    weak var documentPickerDelegate: DocumentPickerDelegate?
    let lock = NSLock()

    // MARK: - Binds Model
    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? UploadDataViewModel else { return }

        uploadFileButton.rx.tap.bind { [weak self] in
            guard let self = self else { return }
            self.browseFile(fileTypes: [kUTTypeZipArchive as String])
        }.disposed(by: disposeBag)

        viewModel.submitArchiveDataResultSubject
            .subscribe(onNext: { [weak self] (event) in
                guard let self = self else { return }
                switch event {
                case .error(let error):
                    loadingState.onNext(.hide)
                    self.errorWhenSubmitArchiveData(error: error)
                case .completed:
                    Global.pollingSyncAppArchiveStatus()
                    Global.log.info("[done] submitArchiveDataResult")
                default:
                    break
                }
            }).disposed(by: disposeBag)
    }

    fileprivate func errorWhenSubmitArchiveData(error: Error) {
        guard !AppError.errorByNetworkConnection(error),
            !handleErrorIfAsAFError(error),
            !showIfRequireUpdateVersion(with: error) else {
                return
        }

        Global.log.error(error)
        showErrorAlertWithSupport(message: R.string.error.system())
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scroll.contentSize = scrollContentView.frame.size
    }

    // MARK: - setup Views
    override func setupViews() {
        super.setupViews()

        let backItem = makeBlackBackItem()

        scrollContentView.flex.define { (flex) in
            flex.addItem(screenTitle).margin(OurTheme.titlePaddingInset)
            flex.addItem(instructionView)
            flex.addItem(uploadDataView).marginTop(12)
        }
        scroll.addSubview(scrollContentView)

        contentView.flex
            .padding(OurTheme.paddingInset)
            .define { (flex) in
                flex.addItem(backItem)
                flex.addItem(scroll).height(100%)

                flex.addItem(uploadProgressView)
                    .height(130)
                    .position(.absolute)
                    .bottom(0).left(0).right(0)
            }

        BackgroundTaskManager.shared
            .uploadProgressRelay
            .map { $0[SessionIdentifier.upload.rawValue] }
            .filterNil()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self, weak uploadProgressView] (event) in
                guard let self = self, let uploadProgressView = uploadProgressView else { return }
                switch event {
                case .next(let progressInfo):
                    uploadProgressView.progressInfo = progressInfo
                    self.setEnableOptionButton(isEnabled: false)

                case .error:
                    uploadProgressView.isHidden = true
                    self.setEnableOptionButton(isEnabled: true)

                default:
                    self.setEnableOptionButton(isEnabled: false)
                }
            })
            .disposed(by: disposeBag)

        AppArchiveStatus.currentState
            .subscribe(onNext: { [weak self, weak uploadProgressView] in
                uploadProgressView?.appArchiveStatusCurrentState = $0
                self?.setEnableOptionButton(isEnabled: $0 == AppArchiveStatus.none)
            })
            .disposed(by: disposeBag)
    }

    fileprivate func setEnableOptionButton(isEnabled: Bool) {
        uploadFileButton.isEnabled = isEnabled
        provideURLTextField.isEnabled = isEnabled
    }
}

extension UploadDataViewController: DocumentPickerDelegate, UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        documentPickerDelegate?.didPickDocument(controller, didPickDocumentAt: url)
    }

    func handle(selectedFileURL: URL) {
        thisViewModel.archiveZipURLRelay.accept(selectedFileURL)
        thisViewModel.submitArchiveData()
    }
}

// MARK: UITextViewDelegate, UITextFieldDelegate
extension UploadDataViewController: UITextViewDelegate, UITextFieldDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard !lockTextViewClick else { return false }
        lockTextViewClick = true

        if URL.path == dyiFacebookPath {
            moveToDYIFacebookPage()
        }

        lockTextViewClick = false
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let urlPath = textField.text, let url = URL(string: urlPath) else {
            return false
        }

        guard UIApplication.shared.canOpenURL(url) else {
            showErrorAlert(message: R.string.error.invalidArchiveFile())
            return false
        }

        thisViewModel.downloadableURLRelay.accept(url)
        thisViewModel.submitArchiveData()

        return true
    }

}

extension UploadDataViewController {
    fileprivate func moveToDYIFacebookPage() {
        guard let dyiFacebookURL = URL(string: dyiFacebookPath) else { return }
        navigator.show(segue: .safariController(dyiFacebookURL), sender: self, transition: .alert)
    }
}

extension UploadDataViewController {
    fileprivate func makeScreenTitle() -> Label {
        let label = Label()
        label.apply(
            text: R.string.phrase.uploadDataTitle().localizedUppercase,
            font: R.font.domaineSansTextLight(size: 36),
            colorTheme: OurTheme.usageColorTheme, lineHeight: 1.06)
        label.numberOfLines = 0
        return label
    }

    fileprivate func makeInstructionView() -> UIView {
        func makeTitleLabel(_ text: String) -> Label {
            let label = Label()
            label.apply(text: text, font: R.font.atlasGroteskMedium(size: 16), colorTheme: .black, lineHeight: 1.25)
            label.numberOfLines = 0
            return label
        }

        func makeDescLabel(_ text: String) -> Label {
            let label = Label()
            label.apply(text: text, font: R.font.atlasGroteskLight(size: 16), colorTheme: .black, lineHeight: 1.25)
            label.numberOfLines = 0
            return label
        }

        let paragraphDistance: CGFloat = 18

        let view = UIView()
        view.flex.define { (flex) in
            flex.addItem(makeTitleLabel(R.string.phrase.uploadDataInstructionStep1Title()))
            flex.addItem(makeInstructionTextView()).marginTop(paragraphDistance)
            flex.addItem(makeDescLabel(R.string.phrase.uploadDataInstructionStep1Desc2())).marginTop(paragraphDistance)

            flex.addItem(makeTitleLabel(R.string.phrase.uploadDataInstructionStep2Title())).marginTop(38)
            flex.addItem(makeDescLabel(R.string.phrase.uploadDataInstructionStep2Desc1())).marginTop(paragraphDistance)
            flex.addItem(makeDescLabel(R.string.phrase.uploadDataInstructionStep2Desc2())).marginTop(paragraphDistance)
            flex.addItem(makeDescLabel(R.string.localizable.to_continue())).marginTop(paragraphDistance)
        }
        return view
    }

    fileprivate func makeInstructionTextView() -> UITextView {
        let textView = ReadingTextView()
        textView.apply(colorTheme: .black)
        textView.isScrollEnabled = false
        textView.delegate = self
        textView.linkTextAttributes = [
          .foregroundColor: themeService.attrs.blackTextColor
        ]

        textView.attributedText = LinkAttributedString.make(
            string: R.string.phrase.uploadDataInstructionStep1Desc1(dyiFacebookPath),
            lineHeight: 1.25,
            attributes: [
                .font: R.font.atlasGroteskLight(size: 16)!,
                .foregroundColor: themeService.attrs.blackTextColor
            ], links: [
                (text: dyiFacebookPath, url: dyiFacebookPath)
            ], linkAttributes: [
                .font: R.font.atlasGroteskLight(size: 16)!,
                .underlineColor: themeService.attrs.blackTextColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ])

        return textView
    }

    fileprivate func makeUploadDataView() -> UIView {
        let orLabel = Label()
        orLabel.apply(
            text: R.string.localizable.or(),
            font: R.font.atlasGroteskLight(size: 16),
            colorTheme: .black)

        let view = UIView()
        view.flex.define { (flex) in
            flex.addItem(uploadFileButton).height(40)
            flex.addItem(orLabel).marginTop(6).alignSelf(.center)
            flex.addItem(provideURLTextField).height(40).marginTop(6)
            flex.addItem().height(20)
        }

        return view
    }

    fileprivate func makeUploadFileButton() -> Button {
        let button = Button()
        button.applyBackground(
            title: R.string.phrase.uploadDataBrowserFile(),
            font: R.font.atlasGroteskLight(size: 18),
            colorTheme: .mercury)
        documentPickerDelegate = self
        return button
    }

    fileprivate func makeProvideURLTextField() -> UITextField {
        let textField = TextField()
        textField.apply(
            placeholder: R.string.phrase.uploadDataProvideURL(),
            font: R.font.atlasGroteskLight(size: 18),
            colorTheme: .black)
        textField.borderColor = ColorTheme.mercury.color
        textField.borderWidth = 2
        textField.textAlignment = .center
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        textField.delegate = self
        return textField
    }

    fileprivate func makeUploadProgressView() -> ProgressView {
        let progressView = ProgressView()
        progressView.isHidden = true
        return progressView
    }
}
