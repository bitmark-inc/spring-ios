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
    fileprivate lazy var titleLabel = makeTitleLabel()
    fileprivate lazy var fileLabel = makeFileLabel()
    fileprivate lazy var progressBar = makeProgressBar()
    lazy var indeterminateProgressBar = makeIndeterminateProgressBar()
    fileprivate lazy var valueLabel = makeValueLabel()

    let disposeBag = DisposeBag()

    var progressInfo: ProgressInfo? {
        didSet {
            guard let progressInfo = progressInfo else { return }

            isHidden = false
            titleLabel.setText(R.string.localizable.uploading().localizedUppercase)
            fileLabel.setText(BackgroundTaskManager.shared.uploadInfoRelay.value[SessionIdentifier.upload.rawValue])

            progressBar.setProgress(progressInfo.fractionCompleted, animated: true)
            valueLabel.setText(R.string.localizable.sizeProgress(
                format(progressInfo.totalBytesSent),
                format(progressInfo.totalBytesExpectedToSend)))

            flex.markDirty()
            flex.layout()
        }
    }

    var appArchiveStatusCurrentState: AppArchiveStatus? {
        didSet {
            switch appArchiveStatusCurrentState {
            case .processing:
                self.isHidden = false
                self.titleLabel.setText(R.string.localizable.processing().localizedUppercase)
                self.fileLabel.setText(nil)
                self.fileLabel.flex.height(18)
                self.valueLabel.setText(nil)

            case .invalid:
                self.isHidden = true

            case .processed:
                self.removeFromSuperview()

            default:
                break
            }

            if let appArchiveStatusCurrentState = appArchiveStatusCurrentState {
                toggleProgressBar(isProgressing:
                    appArchiveStatusCurrentState == .processing)
            }

            flex.markDirty()
            flex.layout()
        }
    }

    fileprivate func toggleProgressBar(isProgressing: Bool) {
        if isProgressing {
            indeterminateProgressBar.isHidden = false
            progressBar.isHidden = true
            indeterminateProgressBar.startAnimating()
        } else {
            indeterminateProgressBar.isHidden = true
            progressBar.isHidden = false
            indeterminateProgressBar.stopAnimating()
        }
    }

    // MARK: - Properties
    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = .white

        flex.define { (flex) in
            let boxImage = ImageView(image: R.image.progressBox())
            boxImage.contentMode = .scaleToFill
            flex.addItem(boxImage).grow(1).width(100%).height(100%)
                .position(.absolute)
                .top(0)

            flex.addItem()
                .padding(UIEdgeInsets(top: 22, left: 18, bottom: 21, right: 18))
                .define { (flex) in
                    flex.addItem(titleLabel)
                    flex.addItem(fileLabel).marginTop(8)
                    flex.addItem().marginTop(6).define { (flex) in
                        flex.addItem(progressBar)
                        flex.addItem(indeterminateProgressBar)
                    }
                    flex.addItem(valueLabel).marginTop(6).alignSelf(.end)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ProgressView {
    fileprivate func makeTitleLabel() -> Label {
        let label = Label()
        label.apply(font: R.font.domaineSansTextLight(size: 22), colorTheme: .black)
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
        progressBar.height = 4.0
        progressBar.progressTintColor = UIColor(hexString: "#932C19")!
        progressBar.backgroundColor = UIColor(red: 147/255, green: 44/255, blue: 24/255, alpha: 0.5)
        return progressBar
    }

    fileprivate func makeIndeterminateProgressBar() -> LinearProgressBar {
        let progressBar = LinearProgressBar()
        progressBar.progressBarColor = UIColor(hexString: "#0011AF")!
        progressBar.isHidden = true
        progressBar.backgroundColor = UIColor(red: 0, green: 17/255, blue: 175/255, alpha: 0.5)
        progressBar.startAnimating()
        return progressBar
    }

    fileprivate func makeValueLabel() -> Label {
        let label = Label()
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
