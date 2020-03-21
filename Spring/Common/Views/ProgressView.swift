//
//  ProgressView.swift
//  Spring
//
//  Created by Thuyen Truong on 3/2/20.
//  Copyright © 2020 Bitmark Inc. All rights reserved.
//

import UIKit
import RxSwift
import FlexLayout
import MaterialProgressBar

class ProgressView: UIView {

    // MARK: - Properties
    fileprivate lazy var boxView = makeBoxView()
    lazy var titleLabel = makeTitleLabel()
    lazy var fileLabel = makeFileLabel()
    fileprivate lazy var progressBar = makeProgressBar()
    lazy var indeterminateProgressBar = makeIndeterminateProgressBar()
    fileprivate lazy var valueLabel = makeValueLabel()
    let disposeBag = DisposeBag()

    var progressInfo: ProgressInfo? {
        didSet {
            guard let progressInfo = progressInfo else { return }
            fileLabel.setText(BackgroundTaskManager.shared.uploadInfoRelay.value[SessionIdentifier.upload.rawValue])

            progressBar.setProgress(progressInfo.fractionCompleted, animated: true)
            valueLabel.setText(R.string.localizable.sizeProgress(
                format(progressInfo.totalBytesSent),
                format(progressInfo.totalBytesExpectedToSend)))
        }
    }

    var hasBorder: Bool = false {
        didSet {
            boxView.isHidden = !hasBorder
        }
    }

    // MARK: - Bind Info
    fileprivate func bindInfo() {
        BackgroundTaskManager.shared
            .uploadProgressRelay
            .map { $0[SessionIdentifier.upload.rawValue] }
            .filterNil()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (event) in
                guard let self = self else { return }
                switch event {
                case .next(let progressInfo):
                    self.progressInfo = progressInfo

                default:
                    break
                }
            })
            .disposed(by: disposeBag)
    }

    func bindInfoInDashboard() {
        AppArchiveStatus.currentState
            .mapLowestStatus()
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                switch $0 {
                case .processing:
                    self.fileLabel.setText(nil)
                    self.valueLabel.setText(nil)
                    self.showIndeterminateProgressBar = true

                case .uploading:
                    self.showIndeterminateProgressBar = false

                default:
                    break
                }
            })
            .disposed(by: disposeBag)
    }

    func bindInfoInUpload() {
        AppArchiveStatus.currentState
            .mapLowestStatus()
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                switch $0 {
                case .processing:
                    self.titleLabel.setText(R.string.localizable.processing().localizedUppercase)
                    self.fileLabel.setText(nil)
                    self.valueLabel.setText(nil)
                    self.showIndeterminateProgressBar = true

                case .uploading:
                    self.titleLabel.setText(R.string.localizable.uploading().localizedUppercase)
                    self.showIndeterminateProgressBar = false

                case .requesting:
                    self.titleLabel.setText(R.string.localizable.facebookRequested().localizedUppercase)
                    self.showIndeterminateProgressBar = true

                default:
                    break
                }
            })
            .disposed(by: disposeBag)
    }

    var showIndeterminateProgressBar: Bool =  true {
        didSet {
            if showIndeterminateProgressBar {
                indeterminateProgressBar.isHidden = false
                progressBar.isHidden = true
                restartIndeterminateProgressBar()
            } else {
                indeterminateProgressBar.isHidden = true
                progressBar.isHidden = false
                indeterminateProgressBar.stopAnimating()
            }
        }
    }

    func restartIndeterminateProgressBar() {
        indeterminateProgressBar.stopAnimating()
        indeterminateProgressBar.startAnimating()
    }

    // MARK: - Properties
    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .white

        flex.define { (flex) in
            flex.addItem(boxView).grow(1).width(100%).height(100%)
                .position(.absolute)
                .top(0)

            flex.addItem()
                .padding(UIEdgeInsets(top: 22, left: 18, bottom: 22, right: 18))
                .define { (flex) in
                    flex.addItem(titleLabel)
                    flex.addItem(fileLabel).marginTop(19).height(20)
                    flex.addItem().marginTop(4).define { (flex) in
                        flex.addItem(progressBar)
                        flex.addItem(indeterminateProgressBar)
                    }
                    flex.addItem(valueLabel).alignSelf(.end)
                        .height(16).width(100%)
                        .marginBottom(8).marginTop(5)
            }
        }
        bindInfo()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProgressView {
    fileprivate func makeBoxView() -> ImageView {
        let boxImage = ImageView(image: R.image.progressBox())
        boxImage.contentMode = .scaleToFill
        boxImage.isHidden = true
        return boxImage
    }

    fileprivate func makeTitleLabel() -> Label {
        let label = Label()
        label.adjustsFontSizeToFitWidth = true
        label.apply(
            text: R.string.localizable.processing().localizedUppercase,
            font: R.font.domaineSansTextLight(size: 22), colorTheme: .black)
        return label
    }

    fileprivate func makeFileLabel() -> Label {
        let label = Label()
        label.lineBreakMode = .byTruncatingMiddle
        label.apply(font: R.font.atlasGroteskLight(size: 18), colorTheme: .tundora)
        return label
    }

    fileprivate func makeProgressBar() -> UIProgressView {
        let progressBar = UIProgressView()
        progressBar.isHidden = true
        progressBar.height = 4.0
        progressBar.progressTintColor = UIColor(hexString: "#932C19")!
        progressBar.backgroundColor = UIColor(red: 147/255, green: 44/255, blue: 24/255, alpha: 0.5)
        return progressBar
    }

    fileprivate func makeIndeterminateProgressBar() -> LinearProgressBar {
        let progressBar = LinearProgressBar()
        progressBar.progressBarColor = UIColor(hexString: "#0011AF")!
        progressBar.backgroundColor = UIColor(red: 0, green: 17/255, blue: 175/255, alpha: 0.5)
        progressBar.startAnimating()
        return progressBar
    }

    fileprivate func makeValueLabel() -> Label {
        let label = Label()
        label.textAlignment = .right
        label.apply(font: R.font.atlasGroteskLight(size: 12), colorTheme: .tundora)
        return label
    }

    fileprivate func format(_ byteCount: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowsNonnumericFormatting = false
        return formatter.string(fromByteCount: Int64(byteCount))
    }
}

struct ProgressInfo {
    let fractionCompleted: Float
    let totalBytesSent: Int64
    let totalBytesExpectedToSend: Int64
}
