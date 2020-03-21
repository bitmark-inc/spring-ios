//
//  UpdateYourDataViewController.swift
//  Spring
//
//  Created by Thuyen Truong on 3/20/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import FlexLayout
import RxSwift
import RxCocoa
import MobileCoreServices

class UpdateYourDataViewController: ViewController, BackNavigator {

    // MARK: - Properties
    fileprivate lazy var scroll = UIScrollView()
    fileprivate lazy var scrollContentView = UIView()
    fileprivate lazy var screenTitle = makeScreenTitle()
    fileprivate lazy var updatedDataInfo = makeUpdatedDataInfoLabel()
    fileprivate lazy var automateButton = makeAutomateButton()
    fileprivate lazy var uploadFileButton = makeUploadFileButton()
    fileprivate lazy var uploadDataView = makeUploadDataView()
    fileprivate lazy var provideURLTextField = makeProvideURLTextField()
    fileprivate lazy var coverLayerView = CoverLayerView()
    fileprivate lazy var uploadProgressView = makeUploadProgressView()

    fileprivate var lockTextViewClick: Bool = false
    let dyiFacebookPath = "https://m.facebook.com/dyi"

    lazy var thisViewModel = { viewModel as! UpdateYourDataViewModel }()
    weak var documentPickerDelegate: DocumentPickerDelegate?
    let lock = NSLock()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        uploadProgressView.restartIndeterminateProgressBar()
    }

    // MARK: - Binds Model
    override func bindViewModel() {
        super.bindViewModel()

        UIApplication.shared.rx.didOpenApp
            .subscribe(onNext: { [weak uploadProgressView] (_) in
                uploadProgressView?.restartIndeterminateProgressBar()
            })
            .disposed(by: disposeBag)

        guard let viewModel = viewModel as? UpdateYourDataViewModel else { return }

        viewModel.realmFbmAccountResultsRelay
            .filterNil()
            .observeObject().filterNil()
            .map({ (fbmAccount) -> String? in
                guard let metadataInfo = fbmAccount.metadataInfo,
                    let startDate = metadataInfo.firstActivityDate,
                    let endDate = metadataInfo.lastActivityDate else {
                        return nil
                }

                let datePeriod = DatePeriod(startDate: startDate, endDate: endDate)
                return datePeriod.makeTimelinePeriodText(in: .week)
            })
            .subscribe(onNext: { [weak self] (lastUpdated) in
                guard let self = self else { return }
                guard let lastUpdated = lastUpdated else {
                    self.updatedDataInfo.setText(nil)
                    return
                }

                self.updatedDataInfo.setText(R.string.phrase.updateYourDataDataInfo(lastUpdated))
            })
            .disposed(by: disposeBag)

        automateButton.rx.tap.bind { [weak self] in
            self?.updateAndSetupAutomate()
        }.disposed(by: disposeBag)

        uploadFileButton.rx.tap.bind { [weak self] in
            guard let self = self else { return }
            self.view.endEditing(true)
            self.browseFile(fileTypes: [kUTTypeZipArchive as String])
        }.disposed(by: disposeBag)

        viewModel.submitArchiveDataResultSubject
            .subscribe(onNext: { [weak self] (event) in
                loadingState.onNext(.hide)

                guard let self = self else { return }
                switch event {
                case .error(let error):
                    self.errorWhenSubmitArchiveData(error: error)
                case .completed:
                    Global.log.info("[done] submitArchiveDataResult")
                    Global.pollingSyncAppArchiveStatus()

                default:
                    break
                }
            }).disposed(by: disposeBag)

        AppArchiveStatus.currentState.mapLowestStatus().distinctUntilChanged()
            .skipUntil(AppArchiveStatus.currentState.mapLowestStatus().filter { $0 == .processing })
            .filter { $0 == .processed }.take(1)
            .subscribe(onCompleted: { [weak self] in
                loadingState.onNext(.success)
                self?.navigationController?.popViewController()
            })
            .disposed(by: disposeBag)

        BehaviorRelay.combineLatest(GetYourData.standard.runningState, AppArchiveStatus.currentState.mapLowestStatus().distinctUntilChanged())
            .subscribe(onNext: { [weak self] (loadState, latestAppArchiveStatus) in
                guard let self = self else { return }
                var showProgress: Bool = false

                if loadState == .loading {
                    showProgress = true
                } else {
                    showProgress = [AppArchiveStatus.uploading, AppArchiveStatus.processing, AppArchiveStatus.requesting].contains(latestAppArchiveStatus)
                }

                self.uploadProgressView.isHidden = !showProgress
                self.uploadProgressView.restartIndeterminateProgressBar()
                self.coverLayerView.isHidden = !showProgress
                self.updatedDataInfo.isHidden = showProgress
            })
            .disposed(by: disposeBag)

        uploadProgressView.bindInfoInUpload()
    }

    // MARK: - Handlers
    // - updateAndSetupAutomate
    // - signUpAndSubmitArchive
    fileprivate func updateAndSetupAutomate() {
        loadingState.onNext(.loading)

        thisViewModel.update(isAutomate: true)
            .subscribe(onCompleted: { [weak self] in
                guard let self = self else { return }
                loadingState.onNext(.hide)

                guard let hometabVC = self.navigationController?.parent as? HomeTabbarController else { return }
                hometabVC.missions = [.requestData]

            }, onError: { [weak self] (error) in
                loadingState.onNext(.hide)
                self?.errorWhenUpdate(error: error)
            })
            .disposed(by: disposeBag)
    }

    // MARK: - signUpAndSubmitArchive
    fileprivate func signUpAndSubmitArchive() {
        thisViewModel.submitArchiveData()
    }

    // MARK: - Error Handlers
    fileprivate func errorWhenUpdate(error: Error) {
        guard !AppError.errorByNetworkConnection(error),
            !handleErrorIfAsAFError(error),
            !showIfRequireUpdateVersion(with: error) else {
                return
        }

        Global.log.error(error)
        showErrorAlertWithSupport(message: R.string.error.system())
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
            flex.addItem(screenTitle).margin(UIEdgeInsets(top: 21, left: 0, bottom: 0, right: 0))

            flex.addItem().grow(1).define { (flex) in
                flex.addItem(updatedDataInfo).height(50)
                flex.addItem(makeOptionTitleLabel(R.string.phrase.getYourDataOption1())).marginTop(25)
                flex.addItem(automateButton).height(40).marginTop(20)
                flex.addItem(makeOptionTitleLabel(R.string.phrase.getYourDataOption2())).marginTop(60)
                flex.addItem(makeInstructionTextView()).marginTop(20)
                flex.addItem(uploadDataView).marginTop(25)

                flex.addItem(coverLayerView)
                    .position(.absolute).top(0)
                    .width(100%).height(100%)
            }
        }
        scroll.addSubview(scrollContentView)
        scroll.showsVerticalScrollIndicator = false

        contentView.flex
            .padding(OurTheme.paddingInset)
            .define { (flex) in
                flex.addItem(backItem)
                flex.addItem(scroll).grow(1).height(1)

                flex.addItem(uploadProgressView)
                    .height(135)
                    .position(.absolute)
                    .bottom(0).left(0).right(0)
            }

        coverLayerView.isHidden = true
    }
}

extension UpdateYourDataViewController: DocumentPickerDelegate, UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        documentPickerDelegate?.didPickDocument(controller, didPickDocumentAt: url)
    }

    func handle(selectedFileURL: URL) {
        do {
            guard let fileSize = try FileManager.default.attributesOfItem(atPath: selectedFileURL.path)[.size] as? Int64 else {
                return
            }

            if fileSizeIfValid(fileSize) {
                thisViewModel.archiveZipRelay.accept((url: selectedFileURL, size: fileSize))
                signUpAndSubmitArchive()

            } else {
                showErrorAlert(title: R.string.error.excessFileSizeTitle(),
                               message: R.string.error.excessFileSizeMessage())
            }
        } catch {
            Global.log.error(error)
        }
    }
}

// MARK: UITextViewDelegate, UITextFieldDelegate
extension UpdateYourDataViewController: UITextViewDelegate, UITextFieldDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        guard !lockTextViewClick else { return false }
        lockTextViewClick = true

        if URL.absoluteString == dyiFacebookPath {
            moveToDYIFacebookPage()
        }

        lockTextViewClick = false
        return false
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let urlPath = textField.text, urlPath.isNotEmpty else {
            textField.endEditing(true)
            return true
        }

        guard let url = URL(string: urlPath), UIApplication.shared.canOpenURL(url) else {
            let alertController = ErrorAlert.invalidArchiveFileAlert(
                title: R.string.error.invalidArchiveURLTitle(),
                message: R.string.error.invalidArchiveURLMessage(),
                action: {})
            alertController.show()
            return true
        }

        textField.endEditing(true)
        thisViewModel.downloadableURLRelay.accept(url)
        signUpAndSubmitArchive()

        return true
    }
}

extension UpdateYourDataViewController {
    fileprivate func moveToDYIFacebookPage() {
        guard let dyiFacebookURL = URL(string: dyiFacebookPath) else { return }
        navigator.show(segue: .safariController(dyiFacebookURL), sender: self, transition: .alert)
    }
}

extension UpdateYourDataViewController {
    fileprivate func makeScreenTitle() -> Label {
        let label = Label()
        label.numberOfLines = 0
        label.apply(
            text: R.string.phrase.updateYourDataTitle().localizedUppercase,
            font: R.font.domaineSansTextLight(size: 36),
            colorTheme: .black, lineHeight: 1.06)
        label.numberOfLines = 0
        return label
    }

    fileprivate func makeUpdatedDataInfoLabel() -> Label {
        let label = Label()
        label.numberOfLines = 0
        label.apply(font: R.font.atlasGroteskThinItalic(size: 18), colorTheme: .black, lineHeight: 1.27)
        return label
    }

    fileprivate func makeOptionTitleLabel(_ text: String) -> Label {
        let label = Label()
        label.apply(text: text, font: R.font.atlasGroteskMedium(size: 16), colorTheme: .black, lineHeight: 1.25)
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
            string: R.string.phrase.updateYourDataOption2Instruction(dyiFacebookPath),
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

    fileprivate func makeAutomateButton() -> Button {
        let button = Button()
        button.applyBackground(title: R.string.localizable.automate_now(),
                               font: R.font.atlasGroteskLight(size: 18), colorTheme: .cognac)
        return button
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
        textField.clearButtonMode = .whileEditing
        return textField
    }

    fileprivate func makeUploadProgressView() -> ProgressView {
        let progressView = ProgressView()
        progressView.isHidden = true
        progressView.hasBorder = true
        return progressView
    }
}
