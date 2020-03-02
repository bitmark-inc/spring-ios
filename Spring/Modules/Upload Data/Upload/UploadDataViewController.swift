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
    fileprivate lazy var screenTitle = makeScreenTitle()
    fileprivate lazy var submitButton = makeSubmitButton()
    fileprivate lazy var instructionTextView = makeInstructionTextView()
    fileprivate lazy var uploadFileButton = makeUploadFileButton()
    fileprivate lazy var provideURLTextField = makeProvideURLTextField()
    fileprivate var lockTextViewClick: Bool = false

    lazy var thisViewModel = { viewModel as! UploadDataViewModel }()
    weak var documentPickerDelegate: DocumentPickerDelegate?
    let lock = NSLock()

    // MARK: - Binds Model
    override func bindViewModel() {
        super.bindViewModel()

        guard let viewModel = viewModel as? UploadDataViewModel else { return }

        viewModel.submitEnabledDriver
            .drive(submitButton.rx.isEnabled)
            .disposed(by: disposeBag)

        viewModel.archiveZipURLRelay
            .map { $0?.lastPathComponent }
            .bind(to: uploadFileButton.rx.text)
            .disposed(by: disposeBag)

        uploadFileButton.selectionButton.rx.tap.bind { [weak self] in
            guard let self = self else { return }
            self.browseFile(fileTypes: [kUTTypeZipArchive as String])
        }.disposed(by: disposeBag)

        uploadFileButton.deleteButton.rx.tap.bind {
           viewModel.archiveZipURLRelay.accept(nil)
       }.disposed(by: disposeBag)

        provideURLTextField.rx.text
            .map { URL(string: $0) }
            .map { (url) -> URL? in
                guard let url = url else { return nil }
                return UIApplication.shared.canOpenURL(url) ? url : nil
            }
            .subscribe(onNext: {
                viewModel.downloadableURLRelay.accept($0)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - setup Views
    override func setupViews() {
        super.setupViews()

        let backItem = makeBlackBackItem()

        contentView.flex
            .padding(OurTheme.paddingInset)
            .direction(.column).define { (flex) in
                flex.addItem(backItem)
                flex.addItem(screenTitle).margin(OurTheme.titlePaddingInset)
                flex.addItem(instructionTextView).top(43)

                flex.addItem(makeOptionsView())
                    .width(100%)
                    .position(.absolute)
                    .top(50%).left(OurTheme.paddingInset.left)

                flex.addItem(submitButton)
                    .width(100%)
                    .position(.absolute)
                    .left(OurTheme.paddingInset.left)
                    .bottom(OurTheme.paddingBottom)
            }
    }
}

extension UploadDataViewController: DocumentPickerDelegate, UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        documentPickerDelegate?.didPickDocument(controller, didPickDocumentAt: url)
    }

    func handle(selectedFileURL: URL) {
        thisViewModel.archiveZipURLRelay.accept(selectedFileURL)
    }
}

// MARK: UITextViewDelegate
extension UploadDataViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard !lockTextViewClick else { return false }
        lockTextViewClick = true

        guard URL.scheme != nil, let host = URL.host else {
            lockTextViewClick = false
            return false
        }

        lockTextViewClick = false
        switch host {
        case AppLink.getFBDataInstruction.rawValue:
            gotoInstructionScreen()
        default:
            return false
        }
        return true
    }
}

extension UploadDataViewController {
    fileprivate func gotoInstructionScreen() {
        navigator.show(segue: .getYourDataInstruction, sender: self)
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

    fileprivate func makeInstructionTextView() -> UITextView {
        let textView = ReadingTextView()
        textView.apply(colorTheme: .black)
        textView.isScrollEnabled = false
        textView.delegate = self
        textView.linkTextAttributes = [
          .foregroundColor: themeService.attrs.blackTextColor
        ]

        textView.attributedText = LinkAttributedString.make(
            string: R.string.phrase.uploadDataDescription(AppLink.getFBDataInstruction.generalText),
            lineHeight: 1.25,
            attributes: [
                .font: R.font.atlasGroteskLight(size: 16)!,
                .foregroundColor: themeService.attrs.blackTextColor
            ], links: [
                (text: AppLink.getFBDataInstruction.generalText, url: AppLink.getFBDataInstruction.path)
            ], linkAttributes: [
                .font: R.font.atlasGroteskLightItalic(size: 16)!,
                .underlineColor: themeService.attrs.blackTextColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ])

        return textView
    }

    fileprivate func makeOptionsView() -> UIView {
        let orLabel = Label()
        orLabel.apply(
            text: R.string.localizable.or().localizedUppercase,
            font: R.font.atlasGroteskLight(size: 18),
            colorTheme: .black)

        let view = UIView()
        view.flex.define { (flex) in
            flex.addItem(uploadFileButton).height(50)
            flex.addItem(orLabel).marginTop(20).alignSelf(.center)
            flex.addItem(provideURLTextField).height(50).marginTop(20)
        }

        return view
    }

    fileprivate func makeUploadFileButton() -> SelectionWithDelete {
        let button = SelectionWithDelete()
        button.placeholder = R.string.phrase.uploadDataBrowserFile()
        button.apply(font: R.font.atlasGroteskLight(size: 18), colorTheme: .cognac)
        documentPickerDelegate = self
        return button
    }

    fileprivate func makeSubmitButton() -> SubmitButton {
        let submitButton = SubmitButton(title: R.string.localizable.submitArrow())
        submitButton.applyTheme(colorTheme: .cognac)
        return submitButton
    }

    fileprivate func makeProvideURLTextField() -> UITextField {
        let textField = TextField()
        textField.apply(
            placeholder: R.string.phrase.uploadDataProvideURL(),
            font: R.font.atlasGroteskLight(size: 18),
            colorTheme: .black)
        textField.borderColor = ColorTheme.cognac.color
        textField.borderWidth = 1
        textField.textAlignment = .center
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }
}
